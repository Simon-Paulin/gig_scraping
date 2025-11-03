# scraping/src/football/qualif_world_cup_south_america.py

from ._scraper_utils import scrape_league


def scrape_qualif_world_cup_south_america():
    """Scrape Qualifications Coupe du Monde Amérique du Sud"""
    return scrape_league(
        league_name="Qualif WC Amérique du Sud",
        league_url="https://www.coteur.com/cotes/foot/amerique-du-sud/qualification-coupe-du-monde-zone-amsud",
        display_name="Coupe du monde - qualifications (Amérique du Sud)"
    )
