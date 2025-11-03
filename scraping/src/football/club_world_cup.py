# scraping/src/football/club_world_cup.py

from ._scraper_utils import scrape_league


def scrape_club_world_cup():
    """Scrape Coupe du monde des Clubs"""
    return scrape_league(
        league_name="Coupe du monde des Clubs",
        league_url="https://www.coteur.com/cotes/foot/monde/coupe-du-monde-des-clubs",
        display_name="Coupe du monde des Clubs (Monde)"
    )
