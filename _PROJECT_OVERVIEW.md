# GIG Scraping - Project Overview

## Project Summary

**GIG Scraping** is a distributed web scraping system designed to collect sports betting odds from [coteur.com](https://www.coteur.com) for **205 competitions** across 4 sports (Football, Tennis, Basketball, Rugby). The system features automated scheduling, real-time data processing, and a scalable microservices architecture.

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          FRONTEND (PHP/Symfony)                         │
│                     User Interface for Odds Display                     │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ HTTP/API
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      BACKEND (Django REST API)                          │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐                 │
│  │    Models    │   │     API      │   │  Management  │                 │
│  │   (ORM)      │   │   Endpoints  │   │   Commands   │                 │
│  └──────────────┘   └──────────────┘   └──────────────┘                 │
└─────────────┬───────────────────┬───────────────────────────────────────┘
              │                   │
              ▼                   ▼
┌─────────────────────┐  ┌─────────────────────┐
│   MySQL Database    │  │   RabbitMQ Broker   │
│   (Persistent Data) │  │  (Message Queues)   │
└─────────────────────┘  └──────────┬──────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  Celery Beat     │   │ Scraping Worker  │   │ Consumer Odds    │
│  (Scheduler)     │   │   (worker.py)    │   │(consumer_odds.py)│
│  Every 6 hours   │   │ 205 Scrapers     │   │ Stores in DB     │
└──────────────────┘   └────────┬─────────┘   └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ Selenium Grid    │
                       │       (Headless) │
                       └────────┬─────────┘
                                │
                                ▼
                         Scrapes exemple.com
```

---

## Technology Stack

### Backend

- **Django 4.x**: REST API framework
- **Django REST Framework**: API endpoints
- **Celery**: Distributed task queue
- **Celery Beat**: Periodic task scheduler
- **MySQL 8.0**: Primary database
- **RabbitMQ 3.12**: Message broker

### Scraping

- **Python 3.11**: Core language
- **Selenium WebDriver**: Browser automation
- **Standalone Chrome**: Headless browser
- **Pika**: RabbitMQ client library

### Frontend

- **PHP 8.x**: Server-side rendering
- **Symfony 6**: PHP framework
- **Nginx**: Reverse proxy & web server

### Infrastructure

- **Docker Compose**: Container orchestration
- **Gunicorn**: WSGI server for Django
- **PHP-FPM**: FastCGI Process Manager

---

## Project Structure

```
gig_scraping/
├── backend/                      # Django REST API
│   ├── config/                   # Django settings & Celery config
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   └── production.py
│   │   ├── celery.py            # Celery app configuration
│   │   └── urls.py
│   ├── core/                     # Main Django app
│   │   ├── models.py            # Database models (Sport, League, Match, Odd)
│   │   ├── serializers.py       # API serializers
│   │   ├── tasks.py             # Celery tasks (auto_scrape_all_leagues)
│   │   ├── views/
│   │   │   ├── scraping_views.py  # API endpoints for scraping
│   │   │   └── data_views.py      # API endpoints for data
│   │   └── urls.py
│   ├── consumers/
│   │   └── consumer_odds.py     # RabbitMQ consumer for odds storage
│   └── services/
│       └── management/
│           └── commands/
│               └── scrape.py    # Django management command
│
├── scraping/                     # Scraping microservice
│   ├── src/
│   │   ├── football/
│   │   │   ├── _scraper_utils.py   # Shared logic (3 odds: 1, N, 2)
│   │   │   ├── ligue_1.py          # Ligue 1 scraper
│   │   │   ├── champions_league.py # Champions League scraper
│   │   │   └── ... (105 total)
│   │   ├── tennis/
│   │   │   ├── _scraper_utils.py   # Shared logic (2 odds: 1, 2)
│   │   │   ├── atp_miami.py
│   │   │   └── ... (89 total)
│   │   ├── basketball/
│   │   │   ├── _scraper_utils.py   # Shared logic (2 odds: 1, 2)
│   │   │   ├── nba.py
│   │   │   └── ... (15 total)
│   │   └── rugby/
│   │       ├── _scraper_utils.py   # Shared logic (3 odds: 1, N, 2)
│   │       ├── top_14.py
│   │       └── ... (3 total)
│   ├── worker.py                # RabbitMQ consumer & scraper dispatcher
│   ├── generate_scrapers.py     # Script to generate all scrapers
│   └── README.md                # Scraping system documentation
│
├── frontend/                     # PHP/Symfony frontend
│   ├── public/
│   ├── src/
│   ├── templates/
│   └── composer.json
│
├── database/
│   └── schema.sql               # MySQL database schema
│
├── docker-compose.yml           # Main orchestration file
├── nginx.conf                   # Nginx configuration
└── .env                         # Environment variables
```

---

## Docker Services (docker-compose.yml)

### 1. **db** - MySQL 8.0

- Database for storing all application data
- Models: Sport, League, Team, Match, MarketName, Odd, Bookmaker
- Port: 3307 (host) → 3306 (container)

### 2. **rabbitmq** - RabbitMQ 3.12

- Message broker with management UI
- Queues: `scraping_tasks`, `odds`
- Ports: 5672 (AMQP), 15672 (Management UI)

### 3. **backend** - Django + Gunicorn

- REST API for data access and scraping triggers
- Port: 8000
- Endpoints:
  - `POST /api/scraping/trigger` - Trigger single scraper
  - `POST /api/scraping/all/football` - Trigger all football scrapers
  - `GET /api/matches` - Get matches data
  - `GET /api/odds` - Get odds data

### 4. **celery_worker** - Celery Worker

- Executes asynchronous tasks
- Task: `auto_scrape_all_leagues()` - Triggers scraping for main leagues
- Concurrency: 4 workers

### 5. **celery_beat** - Celery Beat Scheduler

- Triggers `auto_scrape_all_leagues()` every 6 hours
- Uses Django Celery Beat (database-backed scheduler)

### 6. **consumer_odds** - Odds Consumer

- Consumes `odds` queue from RabbitMQ
- Stores scraped odds data in MySQL database
- Creates/updates: Leagues, Teams, Matches, Odds

### 7. **selenium** - Selenium Standalone Chrome

- Remote WebDriver for browser automation
- Headless Chrome
- Port: 4444 (WebDriver), 7900 (VNC for debugging)
- Memory: 2GB limit

### 8. **scraping** - Scraping Worker

- Consumes `scraping_tasks` queue
- Dispatches to 205 individual scrapers
- Publishes results to `odds` queue

### 9. **php** - PHP-FPM

- Symfony application server
- Handles frontend logic

### 10. **nginx** - Nginx Reverse Proxy

- Routes requests to PHP or Django backend
- Serves static files
- Port: 10014 (HTTP)

---

## Data Flow

### Two Scraping Modes

#### Automated Scraping (Production - Every 6 hours)

- **Trigger**: Celery Beat
- **Competitions**: all scrapers files
- **Purpose**: Regular updates for primary competitions

#### Manual Scraping (On-Demand)

- **Trigger**: User command or API call
- **Competitions**: Any of the 205 available scrapers
- **Purpose**: Testing, specific requests, or additional competitions

---

### Automated Scraping Flow (Every 6 hours)

```
1. Celery Beat (timer) triggers auto_scrape_all_leagues()
                ↓
2. Celery Worker executes task (backend/core/tasks.py)
                ↓
3. Task loops through 7 leagues, calls Django API for each:
   requests.post('http://backend:8000/api/scraping/trigger',
                 json={'scraper': 'football.ligue_1'})
                ↓
4. Django API publishes to RabbitMQ "scraping_tasks" queue
                ↓
5. Scraping Worker (worker.py) consumes message
                ↓
6. Worker dispatches to appropriate scraper (e.g., scrape_ligue_1)
                ↓
7. Scraper calls scrape_league() from _scraper_utils.py
                ↓
8. _scraper_utils.py:
   - Launches Selenium WebDriver
   - Navigates to coteur.com
   - Extracts matches and odds
   - Publishes to RabbitMQ "odds" queue
                ↓
9. Consumer Odds consumes "odds" queue
                ↓
10. Consumer stores data in MySQL:
    - Creates/updates Leagues
    - Creates/updates Teams
    - Creates/updates Matches
    - Creates Odds records
                ↓
11. Data available via Django API
                ↓
12. Frontend displays data to users
```

---

### Manual Scraping Flow (On-Demand)

```
User triggers via:
  - Django command: python manage.py scrape football.ligue_1
  - API call: POST /api/scraping/trigger
  - Direct RabbitMQ publish
                ↓
Django Command/API directly publishes to RabbitMQ "scraping_tasks"
                ↓
        (Same flow from step 5 above)
```

**Key Difference**: Manual mode bypasses Celery Beat and Celery Worker, allowing any of the 205 scrapers to be triggered on-demand.

---

## Database Models

### Core Models

**Sport**

- `code`: FOOT, BASK, TENN, RUGB
- `name`: Display name

**League**

- `sport`: FK to Sport
- `code`: Unique identifier (e.g., LIGUE_1)
- `name`: Display name
- `country`: Country

**Team**

- `league`: FK to League
- `name`: Team name

**Match**

- `league`: FK to League
- `home_team`: FK to Team
- `away_team`: FK to Team
- `match_date`: Scheduled date/time
- `status`: scheduled, live, finished

**MarketName**

- `sport`: FK to Sport
- `code`: Market type (e.g., 1X2)
- `name`: Display name

**Bookmaker**

- `code`: Bookmaker code (e.g., BETCLIC)
- `name`: Display name
- `url`: Website URL

**Odd**

- `match`: FK to Match
- `market`: FK to MarketName
- `bookmaker`: FK to Bookmaker
- `outcome`: '1', 'X', or '2'
- `odd_value`: Decimal odd value
- `trj`: Return To Player percentage
- `scraped_at`: Timestamp

---

## Key Features

### 1. Modular Scraping Architecture

- **DRY Principle**: Single `_scraper_utils.py` per sport
- **Code Reduction**: 91% less code (39,400 → 3,361 lines)
- **Sport-Specific Logic**:
  - Football/Rugby: 3 odds (1, N, 2)
  - Tennis/Basketball: 2 odds (1, 2)

### 2. Automated Scheduling

- Celery Beat triggers scraping every 6 hours
- Configurable via Django admin (django-celery-beat)
- No manual intervention required

### 3. Scalable Message Queue

- RabbitMQ for asynchronous task processing
- 2 queues: `scraping_tasks`, `odds`
- Durable queues (survive broker restart)
- Manual acknowledgment (at-least-once delivery)

### 4. Real-Time Data Processing

- Consumer Odds processes data as it arrives
- Immediate database updates
- No batch processing delays

### 5. Error Handling & Monitoring

- Try-except blocks at every level
- Failed scrapers logged but don't crash worker
- Detailed logging for debugging
- Health checks on all containers

### 6. Docker Orchestration

- 10 services in docker-compose
- Service dependencies managed
- Health checks ensure proper startup order
- Volume persistence for data

---

## Environment Variables

Key variables in `.env`:

```bash
# Database
DB_NAME=gig_benchmark
DB_USER=gig_user
DB_PASSWORD=gig_password_2025
DB_ROOT_PASSWORD=root_password_2025

# RabbitMQ
RABBITMQ_DEFAULT_USER=gig_user
RABBITMQ_DEFAULT_PASS=gig_password_2025

# Django
DJANGO_SECRET_KEY=django-secret-key
DJANGO_SETTINGS_MODULE=config.settings.production
DEBUG=False

# Celery
CELERY_BROKER_URL=amqp://gig_user:gig_password_2025@rabbitmq:5672//

# Ports
NGINX_PORT=10014
BACKEND_PORT=8000
MYSQL_PORT=3307
```

---

## Usage Commands

### Start the entire stack

```bash
docker-compose up -d
```

### View logs

```bash
docker-compose logs -f celery_beat      # Scheduler logs
docker-compose logs -f scraping         # Scraping worker logs
docker-compose logs -f consumer_odds    # Consumer logs
docker-compose logs -f backend          # Django logs
```

### Trigger manual scraping

```bash
# Via Django command
docker-compose exec backend python manage.py scrape football.ligue_1

# Via API
curl -X POST http://localhost:8000/api/scraping/trigger \
  -H "Content-Type: application/json" \
  -d '{"scraper": "football.ligue_1"}'
```

### Access services

- **Frontend**: http://localhost:10014
- **Django API**: http://localhost:8000/api
- **RabbitMQ Management**: http://localhost:15672 (gig_user / gig_password_2025)
- **Selenium VNC**: http://localhost:7900 (for debugging)

### Generate all scrapers

```bash
cd scraping
python3 generate_scrapers.py
```

### Database migrations

```bash
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py makemigrations
```

---

## Performance & Scalability

### Current Metrics

- **197 competitions** scraped automatically
- **Scraping frequency**: Every 6 hours
- **Average scraping time**: ~2-5 minutes per competition
- **Database records**: ~10,000+ odds per scraping cycle

### Scalability Options

1. **Horizontal scaling**: Run multiple scraping worker containers
2. **Queue partitioning**: Separate queues per sport
3. **Database sharding**: Partition by sport or date
4. **Caching**: Redis for frequently accessed data
5. **CDN**: Static assets and API responses

---

## Security Considerations

1. **Environment Variables**: Sensitive data in `.env` (not committed)
2. **Database Credentials**: Unique passwords per environment
3. **RabbitMQ Authentication**: Credentials required for all connections
4. **Django Secret Key**: Unique per deployment
5. **API Permissions**: AllowAny for demo, implement authentication for production
6. **Network Isolation**: Docker internal network for service communication

---

## Future Enhancements

1. **Authentication & Authorization**: JWT/OAuth2 for API access
2. **Rate Limiting**: Prevent abuse of scraping triggers
3. **WebSocket Support**: Real-time odds updates to frontend
4. **Advanced Analytics**: TRJ trends, arbitrage opportunities
5. **Notification System**: Alerts for significant odds changes
6. **Multi-Site Scraping**: Add more betting sites beyond coteur.com
7. **Machine Learning**: Predict odds movements
8. **Mobile App**: Native iOS/Android apps

---

## Maintenance

### Regular Tasks

- Monitor RabbitMQ queue sizes
- Check Celery Beat scheduler status
- Review error logs for failed scrapers
- Database backup and cleanup (old odds data)
- Update Selenium Chrome version
- Renew SSL certificates (if using HTTPS)

### Troubleshooting

- **Scrapers not running**: Check Celery Beat logs
- **No odds in database**: Check Consumer Odds logs
- **Selenium errors**: Check Selenium container logs, increase memory
- **Database connection errors**: Check MySQL healthcheck status
- **RabbitMQ queue buildup**: Scale up consumers

---

## Development Guidelines

### Adding a New Competition

1. Add to `football_competitions` list in `generate_scrapers.py`
2. Run `python3 generate_scrapers.py`
3. Update `worker.py` with import statement
4. Update `tasks.py` with scraper key
5. Test manually: `docker-compose exec backend python manage.py scrape football.new_competition`

### Modifying Scraping Logic

1. Edit `_scraper_utils.py` for the relevant sport
2. Test with a single competition
3. Deploy changes (all competitions use the same logic)

### Database Schema Changes

1. Modify models in `backend/core/models.py`
2. Generate migrations: `python manage.py makemigrations`
3. Apply migrations: `python manage.py migrate`
4. Update serializers and API endpoints as needed

---

## Contributors

This project demonstrates best practices in:

- Distributed systems architecture
- Web scraping at scale
- Task scheduling and automation
- Message queue patterns
- Docker container orchestration
- RESTful API design
