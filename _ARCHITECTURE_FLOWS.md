# GIG Scraping - Architecture & Data Flows

## Two Scraping Modes

### Automatic Mode (Production)

- **Trigger**: Celery Beat (every 6 hours)
- **Competitions**: 7 main leagues only
- **Purpose**: Regular updates for major competitions

### Manual Mode (On-demand)

- **Trigger**: User command or API call
- **Competitions**: Any scraper among 197 available
- **Purpose**: Tests, specific requests, additional competitions

---

## Flow 1: Automatic Scraping (Every 6 hours)

```
┌──────────────────────────────────────────────────────────────────────┐
│                     AUTOMATIC TRIGGER                                 │
└──────────────────────────────────────────────────────────────────────┘

    [TIMER] Celery Beat (6h timer)
        │
        │ trigger task
        ▼
    [WORKER] Celery Worker
        │
        │ execute
        ▼
    [TASK] tasks.py: auto_scrape_all_leagues()
        │
        │ Loop over 7 leagues:
        │  - football.ligue_1
        │  - football.premier_league
        │  - football.la_liga
        │  - football.serie_a
        │  - football.bundesliga
        │  - football.champions_league
        │  - football.europa_league
        │
        │ For each league:
        │ requests.post('http://backend:8000/api/scraping/trigger',
        │               json={'scraper': 'football.ligue_1'})
        ▼
    [API] Django API: /api/scraping/trigger
        │
        │ receive request
        ▼
    [PUBLISH] Publish to RabbitMQ
        │
        │ queue: "scraping_tasks"
        │ message: {"scraper": "football.ligue_1", "params": {}}
        ▼
    ┌─────────────────┐
    │   RabbitMQ      │
    │ scraping_tasks  │
    └────────┬────────┘
             │
             │ consume message
             ▼
    [WORKER] Scraping Worker (worker.py)
        │
        │ dispatch to scraper
        ▼
    [SCRAPER] scrape_ligue_1() in ligue_1.py
        │
        │ call utility function
        ▼
    [UTILS] _scraper_utils.py: scrape_league()
        │
        │ 1. Launch Selenium WebDriver
        │ 2. Navigate to coteur.com
        │ 3. Extract matches & odds
        │ 4. Calculate TRJ
        │
        │ For each match + bookmaker:
        ▼
    [PUBLISH] Publish to RabbitMQ
        │
        │ queue: "odds"
        │ message: {
        │   "match": "PSG - Marseille",
        │   "bookmaker": "Betclic",
        │   "cotes": {"cote_1": 2.10, "cote_N": 3.20, "cote_2": 3.50},
        │   "trj": 94.5,
        │   "league": "Ligue 1",
        │   "sport": "football"
        │ }
        ▼
    ┌─────────────────┐
    │   RabbitMQ      │
    │   odds Queue    │
    └────────┬────────┘
             │
             │ consume message
             ▼
    [CONSUMER] Consumer Odds (consumer_odds.py)
        │
        │ 1. Get/Create Sport
        │ 2. Get/Create League
        │ 3. Get/Create Teams
        │ 4. Get/Create Match
        │ 5. Get MarketName (1X2)
        │ 6. Get Bookmaker
        │ 7. Create Odd records
        ▼
    [DATABASE] MySQL Database
        │
        │ Data stored:
        │  - Sport, League, Team, Match
        │  - Odd (with TRJ)
        │  - Timestamp: scraped_at
        ▼
    [API] Django API
        │
        │ Expose data via REST endpoints
        ▼
    [FRONTEND] Frontend (PHP/Symfony)
        │
        │ Display odds to users
        ▼
    [USER] End User

┌──────────────────────────────────────────────────────────────────────┐
│  RESULT: 7 leagues scraped automatically every 6 hours              │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Flow 2: Manual Scraping (On-demand)

```
┌──────────────────────────────────────────────────────────────────────┐
│                     MANUAL TRIGGER                                    │
└──────────────────────────────────────────────────────────────────────┘

    [USER] User
        │
        │ Option A: Django Command
        │   docker-compose exec backend python manage.py scrape football.ligue_1
        │
        │ Option B: API Call
        │   curl -X POST http://localhost:8000/api/scraping/trigger \
        │        -d '{"scraper": "football.ligue_1"}'
        │
        │ Option C: Direct RabbitMQ
        │   (Publish directly to "scraping_tasks" queue)
        ▼
    [API] Django Command / API Endpoint
        │
        │ /api/scraping/trigger
        │ or management command
        ▼
    [PUBLISH] Publish to RabbitMQ
        │
        │ queue: "scraping_tasks"
        │ message: {"scraper": "football.ligue_1", "params": {}}
        ▼
    ┌─────────────────┐
    │   RabbitMQ      │
    │ scraping_tasks  │
    └────────┬────────┘
             │
             │ consume message
             ▼
    [WORKER] Scraping Worker (worker.py)
        │
        │ dispatch to scraper
        ▼
    [SCRAPER] scrape_ligue_1() in ligue_1.py
        │
        │ call utility function
        ▼
    [UTILS] _scraper_utils.py: scrape_league()
        │
        │ ... (same as automated flow)
        ▼
    [CONSUMER] Consumer Odds
        ▼
    [DATABASE] MySQL Database
        ▼
    [API] Django API
        ▼
    [FRONTEND] Frontend
        ▼
    [USER] End User

┌──────────────────────────────────────────────────────────────────────┐
│  RESULT: Any scraper (among 205) can be triggered instantly,        │
│          without waiting for the 6-hour timer                        │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Key Differences

| Aspect                  | Automatic Mode                     | Manual Mode                  |
| ----------------------- | ---------------------------------- | ---------------------------- |
| **Trigger**             | Celery Beat (timer)                | User command/API             |
| **Goes through Celery** | Yes (Beat + Worker)                | No (direct to RabbitMQ)      |
| **Number of scrapers**  | 7 leagues (configured in tasks.py) | 205 scrapers available       |
| **Frequency**           | Every 6 hours                      | On-demand                    |
| **Use case**            | Production - regular updates       | Dev/Test - specific scraping |
| **Configuration**       | `backend/core/tasks.py`            | None (all available)         |

---

## System Components

### 1. Celery Beat (Scheduler)

**Role**: Timer that triggers periodic tasks
**Configuration**: Django Celery Beat (database-backed)
**Task**: `auto_scrape_all_leagues` every 6 hours
**Container**: `celery_beat`

### 2. Celery Worker (Task Executor)

**Role**: Executes tasks triggered by Celery Beat
**Configuration**: 4 concurrent workers
**Location**: `backend/core/tasks.py`
**Container**: `celery_worker`

### 3. Django API (Orchestrator)

**Role**: Entry point to trigger scraping
**Endpoints**:

- `POST /api/scraping/trigger` - Triggers a scraper
- `POST /api/scraping/all/football` - All football scrapers
  **Container**: `backend`

### 4. RabbitMQ (Message Broker)

**Role**: Message queue (producer/consumer pattern)
**Queues**:

- `scraping_tasks` - Scraping jobs to execute
- `odds` - Odds data to store
  **Container**: `rabbitmq`

### 5. Scraping Worker (Dispatcher)

**Role**: Consumes `scraping_tasks`, dispatches to scrapers
**Location**: `scraping/worker.py`
**Registry**: 197 available scrapers
**Container**: `scraping`

### 6. Scrapers (197 files)

**Role**: Execute web scraping via Selenium
**Structure**:

- `src/football/` (105 scrapers)
- `src/tennis/` (89 scrapers)
- `src/basketball/` (15 scrapers)
- `src/rugby/` (3 scrapers)
  **Shared logic**: `_scraper_utils.py` per sport

### 7. Selenium Grid (Browser Automation)

**Role**: Remote WebDriver for headless Chrome
**Configuration**: 2GB RAM, 1 max session
**Ports**: 4444 (WebDriver), 7900 (VNC debug)
**Container**: `selenium`

### 8. Consumer Odds (Data Persister)

**Role**: Consumes `odds` queue, stores in database
**Location**: `backend/consumers/consumer_odds.py`
**Operations**: Create/Update Leagues, Teams, Matches, Odds
**Container**: `consumer_odds`

### 9. MySQL (Database)

**Role**: Persistent data storage
**Models**: Sport, League, Team, Match, MarketName, Odd, Bookmaker
**Container**: `db`

### 10. Frontend (User Interface)

**Role**: Display odds to users
**Tech**: PHP/Symfony + Nginx
**Containers**: `php` + `nginx`

---

## RabbitMQ Queues

### Queue: `scraping_tasks`

**Producers**:

- Celery Worker (automatic mode)
- Django API (manual mode)
- Django Management Command (manual mode)

**Consumer**:

- Scraping Worker

**Message format**:

```json
{
  "scraper": "football.ligue_1",
  "params": {}
}
```

**Properties**:

- Durable: Yes (survives RabbitMQ restart)
- Auto-delete: No
- Acknowledgment: Manual

---

### Queue: `odds`

**Producer**:

- Scrapers (via `_scraper_utils.py`)

**Consumer**:

- Consumer Odds

**Message format**:

```json
{
  "match": "PSG - Marseille",
  "bookmaker": "Betclic",
  "cotes": {
    "cote_1": 2.1,
    "cote_N": 3.2,
    "cote_2": 3.5
  },
  "trj": 94.5,
  "league": "Ligue 1",
  "sport": "football",
  "match_date": "2025-11-15 20:00:00"
}
```

**Properties**:

- Durable: Yes
- Auto-delete: No
- Acknowledgment: Manual

---

## Monitoring & Logs

### Check automatic scraping

```bash
# Scheduler logs
docker-compose logs -f celery_beat

# Celery tasks logs
docker-compose logs -f celery_worker

# Scraping logs
docker-compose logs -f scraping

# Consumer logs
docker-compose logs -f consumer_odds
```

### Check RabbitMQ queues

- UI: http://localhost:15672
- User: `gig_user`
- Password: `gig_password_2025`

### Manual testing

```bash
# Trigger a scraper
docker-compose exec backend python manage.py scrape football.ligue_1

# Check logs
docker-compose logs -f scraping
```

---

## Key Points for Presentation

1. **2 operating modes** distinct but sharing the same infrastructure (Scraping Worker, Selenium, Consumer)

2. **Automatic mode** = Production

   - Celery Beat timer
   - Only 7 major leagues
   - No human intervention

3. **Manual mode** = Development/Testing

   - On-demand
   - 197 available scrapers
   - Flexible and responsive

4. **Decoupled architecture**:

   - Changes in Celery Beat don't affect manual scraping
   - Adding a scraper makes it immediately available in manual mode
   - Modify tasks.py to add it to automatic mode

5. **Dual mode advantage**:
   - Production: Automation without intervention
   - Dev: Testing and ad-hoc scraping without waiting 6h
   - Flexibility: Choose what to scrape and when
