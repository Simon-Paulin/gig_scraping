# scraping/src/football/ligue_nations_f.py

from ._scraper_utils import scrape_league


def scrape_ligue_nations_f():
    """Scrape Ligue des Nations Femmes"""
    return scrape_league(
        league_name="Ligue des Nations F",
        league_url="https://www.coteur.com/cotes/foot/europe/europe-ligue-des-nations-f",
        display_name="Ligue des Nations F (Europe)"
    )
