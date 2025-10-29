from django.urls import path
from .views import data_views, scraping_views

urlpatterns = [
    path('scraping/health', scraping_views.health_check, name='scraping-health'),
    path('scraping/trigger', scraping_views.trigger_scraping, name='trigger-scraping'),
    path('scraping/football/all', scraping_views.scrape_all_football, name='scrape-football'),
    path('scraping/basketball/all', scraping_views.scrape_all_basketball, name='scrape-basketball'),
    path('scraping/rugby/all', scraping_views.scrape_all_rugby, name='scrape-rugby'),
    path('scraping/tennis/all', scraping_views.scrape_all_tennis, name='scrape-tennis'),
    path('sports', data_views.get_distinct_sports),
    path('bookmakers', data_views.get_distinct_bookmakers),
    path('leagues', data_views.get_distinct_leagues),
    path('matches', data_views.get_distinct_matches),
    path('odds', data_views.get_odds_with_filters),
    path('avg-trj', data_views.get_avg_trj),
    path('odds-with-evolution', data_views.get_odds_with_evolution, name='odds_with_evolution'),
    path('avg-trj-with-evolution', data_views.get_avg_trj_with_evolution, name='avg_trj_with_evolution'),
]
