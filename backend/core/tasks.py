from celery import shared_task
import subprocess
import logging

logger = logging.getLogger(__name__)

@shared_task(name='auto_scrape_all_leagues')
def auto_scrape_all_leagues():
    """Automate Scraping"""
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
            
            
            result = subprocess.run(
                ['python', '/app/send_task.py', league],
                cwd='/app',
                capture_output=True,
                text=True,
                timeout=600
            )
            
            success = result.returncode == 0
            results.append({
                'league': league,
                'success': success,
                'stdout': result.stdout[:200] if success else None,
                'stderr': result.stderr[:200] if not success else None
            })
            
            status = 'OK' if success else 'ERREUR'
            logger.info(f"{league}: {status}")
            
        except subprocess.TimeoutExpired:
            logger.error(f"{league}: TIMEOUT (600s)")
            results.append({'league': league, 'success': False, 'error': 'timeout'})
        except Exception as e:
            logger.error(f"{league}: EXCEPTION - {str(e)}")
            results.append({'league': league, 'success': False, 'error': str(e)})
    
    success_count = sum(1 for r in results if r.get('success'))
    logger.info(f"=== FIN SCRAPING AUTOMATIQUE: {success_count}/{len(results)} succes ===")
    
    return {
        'total': len(results),
        'success': success_count,
        'failed': len(results) - success_count,
        'details': results
    }
