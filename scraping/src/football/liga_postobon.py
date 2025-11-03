# scraping/src/football/liga_postobon.py

from ._scraper_utils import scrape_league


def scrape_liga_postobon():
    """Scrape Liga Postobon I"""
    return scrape_league(
        league_name="Liga Postobon I",
        league_url="https://www.coteur.com/cotes/foot/colombie/liga-postobon-i",
        display_name="Liga Postobon I (Colombie)"
    )
