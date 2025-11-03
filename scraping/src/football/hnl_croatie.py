# scraping/src/football/hnl_croatie.py

from ._scraper_utils import scrape_league


def scrape_hnl_croatie():
    """Scrape 1.HNL Croatie"""
    return scrape_league(
        league_name="1.HNL",
        league_url="https://www.coteur.com/cotes/foot/croatie/1-hnl",
        display_name="1.HNL (Croatie)"
    )
