# scraping/src/football/ucl_femmes.py

from ._scraper_utils import scrape_league


def scrape_ucl_femmes():
    """Scrape Ligue des Champions Femmes"""
    return scrape_league(
        league_name="Ligue des Champions F",
        league_url="https://www.coteur.com/cotes/foot/europe/ligue-des-champions-f",
        display_name="Ligue des Champions F (Europe)"
    )
