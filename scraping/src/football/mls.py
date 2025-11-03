# scraping/src/football/mls.py

from ._scraper_utils import scrape_league


def scrape_mls():
    """Scrape Major League Soccer"""
    return scrape_league(
        league_name="Major League Soccer",
        league_url="https://www.coteur.com/cotes/foot/etats-unis/major-league-soccer",
        display_name="Major League Soccer (Etats-Unis)"
    )
