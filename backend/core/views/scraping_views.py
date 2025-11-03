# backend/core/views/scraping_views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
import pika
import json
import os

RABBITMQ_HOST = os.environ.get('RABBITMQ_HOST', 'rabbitmq')
RABBITMQ_PORT = int(os.environ.get('RABBITMQ_PORT', '5672'))
RABBITMQ_USER = os.environ.get('RABBITMQ_USER', 'gig_user')
RABBITMQ_PASSWORD = os.environ.get('RABBITMQ_PASSWORD', 'gig_password_2025')


def send_scraping_task(scraper_name):
    """
    Send scraping task to RabbitMQ queue
    """
    try:
        print(f"Connecting to RabbitMQ: {RABBITMQ_HOST}:{RABBITMQ_PORT}")

        credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASSWORD)
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host=RABBITMQ_HOST,
                port=RABBITMQ_PORT,
                credentials=credentials,
                connection_attempts=3,
                retry_delay=2
            )
        )

        print("Connected to RabbitMQ")

        channel = connection.channel()
        channel.queue_declare(queue='scraping_tasks', durable=True)

        print(f"Queue 'scraping_tasks' declared")

        message = json.dumps({'scraper': scraper_name, 'params': {}})
        channel.basic_publish(
            exchange='',
            routing_key='scraping_tasks',
            body=message,
            properties=pika.BasicProperties(delivery_mode=2)
        )

        print(f"Task sent: {scraper_name}")
        connection.close()
        return True
        
    except Exception as e:
        print(f" Erreur envoi task: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    return Response({'status': 'healthy', 'service': 'scraping-api'})


@api_view(['POST'])
@permission_classes([AllowAny])
def trigger_scraping(request):
    """
    Déclenche un scraping
    Body: {"scraper": "football.ligue_1"}
    """
    scraper = request.data.get('scraper')
    
    if not scraper:
        return Response(
            {'success': False, 'error': 'scraper field required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Send task to RabbitMQ
    success = send_scraping_task(scraper)

    if success:
        return Response({
            'success': True,
            'message': f'Scraping {scraper} launched successfully'
        })
    else:
        return Response(
            {'success': False, 'error': 'Error sending task'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def scrape_all_football(request):
    """Lance tous les scrapers de football"""
    scrapers = [
        'football.ligue_1',
        'football.premier_league',
        'football.la_liga',
        'football.serie_a',
        'football.bundesliga'
    ]
    
    tasks_sent = []
    errors = []
    
    for scraper in scrapers:
        if send_scraping_task(scraper):
            tasks_sent.append(scraper)
        else:
            errors.append(scraper)
    
    return Response({
        'success': len(errors) == 0,
        'message': f'{len(tasks_sent)} scrapers lancés',
        'tasks_sent': tasks_sent,
        'errors': errors
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def scrape_all_basketball(request):
    scrapers = ['basketball.nba', 'basketball.euroleague']
    tasks_sent = []
    for scraper in scrapers:
        if send_scraping_task(scraper):
            tasks_sent.append(scraper)
    
    return Response({
        'success': True,
        'message': f'{len(tasks_sent)} scrapers basketball lancés',
        'tasks_sent': tasks_sent
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def scrape_all_rugby(request):
    scrapers = ['rugby.top_14']
    tasks_sent = []
    for scraper in scrapers:
        if send_scraping_task(scraper):
            tasks_sent.append(scraper)
    
    return Response({
        'success': True,
        'message': f'{len(tasks_sent)} scrapers rugby lancés',
        'tasks_sent': tasks_sent
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def scrape_all_tennis(request):
    scrapers = ['tennis.atp']
    tasks_sent = []
    for scraper in scrapers:
        if send_scraping_task(scraper):
            tasks_sent.append(scraper)
    
    return Response({
        'success': True,
        'message': f'{len(tasks_sent)} scrapers tennis lancés',
        'tasks_sent': tasks_sent
    })
