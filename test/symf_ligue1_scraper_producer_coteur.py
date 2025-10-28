import time
import json
import pika
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# --- RabbitMQ ---
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()
channel.queue_declare(queue="cotes")


def perform_scrapping():
    # --- Selenium ---
    options = webdriver.ChromeOptions()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)

    # --- URL Ligue 1 ---
    url = "https://www.coteur.com/cotes/foot/france/ligue-1"
    driver.get(url)
    try:
        # wait charging page
        WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, ".d-flex[data-name]"))
        )
        print("✅ Page chargée, les éléments de matchs sont présents.")
    except:
        print("⚠️ Impossible de charger les éléments de la page :", url)


    # had match links
    link_elements = driver.find_elements(By.CSS_SELECTOR, "a.text-decoration-none")
    match_links = []
    for elem in link_elements:
        href = elem.get_attribute("href")
        if href:
            if href.startswith("/"):
                href = "https://www.coteur.com" + href
            match_links.append(href)

    print(f"📌 Nombre de matchs trouvés : {len(match_links)}")


    # browse matches
    for match_url in match_links:
        try:
            driver.get(match_url)
            time.sleep(3)

            # name match
            match_elem = driver.find_element(By.CSS_SELECTOR, ".page-title")
            match_name = match_elem.text.strip()

            # name bookmakers
            rows = driver.find_elements(By.CSS_SELECTOR, ".d-flex[data-name]")
            for row in rows:
                bookmaker = row.get_attribute("data-name")
                odds = row.find_elements(By.CSS_SELECTOR, ".border.odds-col")

                cote_dict = {}
                if len(odds) >= 3:
                    cote_dict["cote_1"] = odds[0].text.strip()
                    cote_dict["cote_N"] = odds[1].text.strip()
                    cote_dict["cote_2"] = odds[2].text.strip()

                # publish in Rabbit
                message = {"match": match_name, "bookmaker": bookmaker, "cotes": cote_dict}
                channel.basic_publish(exchange="", routing_key="cotes", body=json.dumps(message))
                print(f"📤 Envoyé : {message}")

        except Exception as e:
            print("⚠️ Erreur scraping :", e)

    driver.quit()
    connection.close()