from celery import shared_task
import requests
import logging

logger = logging.getLogger(__name__)

@shared_task(name='auto_scrape_all_leagues')
def auto_scrape_all_leagues():
    """Scraping automatique de toutes les ligues principales"""
    logger.info("=== DEBUT SCRAPING AUTOMATIQUE ===")
    
    leagues = [
        'football.ligue_1',
        'football.premier_league',
        'football.la_liga',
        'football.serie_a',
        'football.bundesliga'
    ]
    
    results = []
    for league in leagues:
        try:
            logger.info(f"Scraping: {league}")
            
            # Appel à l'API de scraping Django
            response = requests.post(
                'http://backend:8000/api/scraping/trigger',
                json={'scraper': league},
                timeout=600
            )
            
            success = response.status_code == 200
            results.append({
                'league': league,
                'success': success,
                'status_code': response.status_code
            })
            
            logger.info(f"{league}: {'OK' if success else 'ERREUR'} (status={response.status_code})")
            
        except requests.exceptions.Timeout:
            logger.error(f"{league}: TIMEOUT")
            results.append({'league': league, 'success': False, 'error': 'timeout'})
        except Exception as e:
            logger.error(f"{league}: {str(e)}")
            results.append({'league': league, 'success': False, 'error': str(e)})
    
    success_count = sum(1 for r in results if r.get('success'))
    logger.info(f"=== FIN: {success_count}/{len(results)} succes ===")
    
    return results
