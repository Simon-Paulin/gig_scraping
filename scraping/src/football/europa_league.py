# scraping/src/football/europa_league.py

from ._scraper_utils import scrape_league


def scrape_europa_league():
    """Scrape TOUS les matchs de Europa League"""
    return scrape_league(
        league_name="Europa League",
        league_url="https://www.coteur.com/cotes/foot/europe/ligue-europa-1",
        display_name="Ligue Europa (Europe)"
    )
