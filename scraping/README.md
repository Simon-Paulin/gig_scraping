# Multi-Sport Scraping System

A scalable web scraping system for sports betting odds from [coteur.com](https://www.coteur.com), supporting **197 competitions** across 4 sports.

## Coverage

- **Football**: 105 competitions (Champions League, Ligue 1, Premier League, La Liga, etc.)
- **Tennis**: 89 tournaments (ATP, WTA - Roland Garros, Wimbledon, US Open, etc.)
- **Basketball**: 15 leagues (NBA, Euroleague, Betclic Elite, etc.)
- **Rugby**: 3 competitions (Top 14, Pro D2, Test-Match)

**Total: 197 automated scrapers**

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         AUTOMATED SCHEDULING                              │
│  ┌────────────────┐         ┌─────────────────┐                         │
│  │ Celery Beat    │────────▶│ Celery Worker   │                         │
│  │ (Every 6h)     │         │ (tasks.py)      │                         │
│  └────────────────┘         └────────┬────────┘                         │
│                                       │                                   │
└───────────────────────────────────────┼───────────────────────────────────┘
                                        │
                                        ▼
                              ┌─────────────────┐
                              │  Django API     │
                              │ (trigger scraping)│
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │   RabbitMQ      │
                              │ scraping_tasks  │◀──── Manual trigger
                              │     Queue       │      (Django command)
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ Scraping Worker │
                              │   (worker.py)   │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │   205 Scrapers  │
                              │  (sport/*.py)   │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ Selenium Grid   │
                              │(Remote WebDriver)│
                              └────────┬────────┘
                                       │
                                       ▼ Scrapes coteur.com
                              ┌─────────────────┐
                              │   RabbitMQ      │
                              │   odds Queue    │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ Consumer Odds   │
                              │(consumer_odds.py)│
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  MySQL Database │
                              │  (Odds stored)  │
                              └─────────────────┘
```

### Key Components:

1. **Celery Beat**: Scheduler that triggers `auto_scrape_all_leagues()` task every 6 hours
2. **Celery Worker**: Executes scheduled tasks, calls Django API to trigger scraping
3. **Django API** (`/api/scraping/trigger`): Receives scraping requests and publishes to RabbitMQ
4. **RabbitMQ** (2 queues):
   - `scraping_tasks`: Contains scraping jobs to execute
   - `odds`: Contains scraped odds data to store
5. **Scraping Worker** (`worker.py`): Consumes `scraping_tasks`, dispatches to appropriate scrapers
6. **Scrapers** (197 files): Execute web scraping via Selenium, publish results to `odds` queue
7. **Consumer Odds** (`consumer_odds.py`): Consumes `odds` queue and stores data in MySQL database
8. **Selenium Grid**: Remote WebDriver for headless Chrome browser automation

### Two Scraping Modes:

#### Automated Scraping (Production Mode)

**Trigger**: Celery Beat (every 6 hours)
**Flow**: Celery Beat → Celery Worker → tasks.py → Django API → RabbitMQ → Scraping Worker
**Scrapers**: Only 7 main leagues (configured in tasks.py)
**Use Case**: Regular automatic updates for main competitions

#### Manual Scraping (On-Demand Mode)

**Trigger**: User command or API call
**Flow**: Django Command/API → RabbitMQ → Scraping Worker
**Scrapers**: Any of the 197 available scrapers
**Use Case**: On-demand scraping for specific competitions or testing

## Project Structure

```
scraping/
├── src/
│   ├── football/
│   │   ├── _scraper_utils.py      # Shared scraping logic (3 odds: 1, N, 2)
│   │   ├── ligue_1.py             # Ligue 1 scraper
│   │   ├── champions_league.py    # Champions League scraper
│   │   └── ... (91 total)
│   │
│   ├── tennis/
│   │   ├── _scraper_utils.py      # Shared scraping logic (2 odds: 1, 2)
│   │   ├── atp_miami.py           # ATP Miami scraper
│   │   ├── wta_roland_garros.py   # Roland Garros scraper
│   │   └── ... (89 total)
│   │
│   ├── basketball/
│   │   ├── _scraper_utils.py      # Shared scraping logic (2 odds: 1, 2)
│   │   ├── nba.py                 # NBA scraper
│   │   └── ... (14 total)
│   │
│   └── rugby/
│       ├── _scraper_utils.py      # Shared scraping logic (3 odds: 1, N, 2)
│       ├── top_14.py              # Top 14 scraper
│       └── ... (3 total)
│
├── worker.py                       # RabbitMQ consumer/dispatcher
├── generate_scrapers.py            # Script to generate all scrapers
└── README.md                       # This file
```

## Design Pattern: DRY (Don't Repeat Yourself)

Instead of duplicating 200 lines of scraping logic across 197 files, we use a **centralized utility approach**:

### Traditional Approach (Bad)

```python
# bundesliga.py - 200 lines
def scrape_bundesliga():
    driver = webdriver.Remote(...)
    driver.get("https://...")
    # ... 195 more lines ...
```

**Result**: 200 lines × 197 files = **39,400 lines of duplicated code**

### Our Approach (Good)

```python
# _scraper_utils.py - 200 lines (shared)
def scrape_league(league_name, league_url, display_name):
    driver = webdriver.Remote(...)
    driver.get(league_url)
    # ... all scraping logic ...

# bundesliga.py - 13 lines
def scrape_bundesliga():
    return scrape_league(
        league_name="Bundesliga",
        league_url="https://www.coteur.com/cotes/foot/allemagne/bundesliga",
        display_name="Bundesliga"
    )
```

**Result**: 4 utils (800 lines) + 197 configs (2,561 lines) = **3,361 lines total**
**Code reduction: 91%**

## How `_scraper_utils.py` Works

Each sport has its own `_scraper_utils.py` because of **different odds structures**:

### Football & Rugby (3 odds)

```python
# Match can end in: Win, Draw, Loss
cote_dict = {
    "cote_1": 2.10,  # Team 1 wins
    "cote_N": 3.20,  # Draw
    "cote_2": 3.50   # Team 2 wins
}
# TRJ = 1 / (1/cote_1 + 1/cote_N + 1/cote_2) * 100
```

### Tennis & Basketball (2 odds)

```python
# Match has only 2 outcomes (no draw possible)
cote_dict = {
    "cote_1": 1.85,  # Player/Team 1 wins
    "cote_2": 1.95   # Player/Team 2 wins
}
# TRJ = 1 / (1/cote_1 + 1/cote_2) * 100
```

### Core Functionality

Each `scrape_league()` function:

1. Initializes Selenium WebDriver (remote)
2. Navigates to competition URL
3. Waits for dynamic content (AJAX)
4. Extracts matches via XPath selectors
5. Parses odds (2 or 3 depending on sport)
6. Calculates **TRJ** (Return To Player percentage)
7. Publishes results to RabbitMQ
8. Handles errors gracefully

## Usage

### 1. Generate All Scrapers

```bash
cd /home/simn-popo/gig_scraping/scraping
python3 generate_scrapers.py
```

This will:

- Create all 197 scraper files in their respective directories
- Generate `/tmp/all_scrapers_info.txt` with import statements for `worker.py` and `tasks.py`

### 2. Start the Worker

```bash
docker-compose up scraping-worker
```

The worker will:

- Connect to RabbitMQ
- Load all 197 scrapers
- Listen for scraping tasks
- Dispatch tasks to appropriate scrapers

### 3. Trigger Scraping

#### A. Automatic Scraping (Production - Every 6 hours)

Celery Beat automatically triggers scraping every 6 hours via the `auto_scrape_all_leagues()` task in [backend/core/tasks.py](../backend/core/tasks.py).

**Automated leagues (7 total)**:

- `football.ligue_1`
- `football.premier_league`
- `football.la_liga`
- `football.serie_a`
- `football.bundesliga`
- `football.champions_league`
- `football.europa_league`

**Flow**: Celery Beat → Celery Worker executes task → Task calls Django API for each league → RabbitMQ → Scraping Worker → Selenium

This runs automatically without any manual intervention. Check Celery Beat logs to see execution:

```bash
docker-compose logs -f celery_beat
```

#### B. Manual Scraping (On-Demand - Any of 197 scrapers)

##### Via Django Management Command:

```bash
docker-compose exec backend python manage.py scrape football.ligue_1
```

##### Via Django API:

```bash
# Single scraper
curl -X POST http://localhost:8000/api/scraping/trigger \
  -H "Content-Type: application/json" \
  -d '{"scraper": "football.ligue_1"}'

# All football scrapers
curl -X POST http://localhost:8000/api/scraping/all/football

# All tennis scrapers
curl -X POST http://localhost:8000/api/scraping/all/tennis
```

##### Via Python (Direct RabbitMQ):

```python
import pika
import json

credentials = pika.PlainCredentials('gig_user', 'gig_password')
connection = pika.BlockingConnection(
    pika.ConnectionParameters('rabbitmq', credentials=credentials)
)
channel = connection.channel()

channel.basic_publish(
    exchange='',
    routing_key='scraping_tasks',
    body=json.dumps({'scraper': 'football.ligue_1', 'params': {}})
)
```

## Scraper Naming Convention

Scraper keys follow the pattern: `{sport}.{competition_slug}`

Examples:

- `football.ligue_1`
- `football.champions_league`
- `tennis.atp_miami`
- `tennis.wta_roland_garros`
- `basketball.nba`
- `rugby.top_14`

## Adding a New Competition

### Option 1: Manual (Quick)

1. Create the scraper file:

```python
# src/football/new_competition.py
from ._scraper_utils import scrape_league

def scrape_new_competition():
    """Scrape New Competition"""
    return scrape_league(
        league_name="New Competition",
        league_url="https://www.coteur.com/cotes/...",
        display_name="New Competition"
    )
```

2. Add import to `worker.py`:

```python
from src.football.new_competition import scrape_new_competition
SCRAPERS_REGISTRY['football.new_competition'] = scrape_new_competition
```

3. Add to `tasks.py`:

```python
leagues = [
    # ...
    'football.new_competition',
]
```

### Option 2: Automated (Recommended)

1. Add competition to `generate_scrapers.py`:

```python
football_competitions = [
    # ...
    {"name": "New Competition", "url": "https://www.coteur.com/cotes/..."},
]
```

2. Re-run the generator:

```bash
python3 generate_scrapers.py
```

3. Update `worker.py` and `tasks.py` with content from `/tmp/all_scrapers_info.txt`

## Modifying Scraping Logic

### If coteur.com changes HTML structure:

**Before this architecture**: Edit 205 files
**With this architecture**: Edit 1 file (`_scraper_utils.py`)

Example:

```python
# src/football/_scraper_utils.py

# Old XPath
matches = driver.find_elements(By.XPATH, '//div[@class="match"]')

# New XPath (after site update)
matches = driver.find_elements(By.XPATH, '//div[@class="match-item"]')
```

All 197 scrapers automatically use the new selector!

## Testing

### Test a single scraper:

```python
from src.football.ligue_1 import scrape_ligue_1

result = scrape_ligue_1()
print(result)
```

### Test the utils directly:

```python
from src.football._scraper_utils import scrape_league

result = scrape_league(
    league_name="Test League",
    league_url="https://www.coteur.com/cotes/...",
    display_name="Test League"
)
```

## Monitoring

The worker provides detailed logging:

```
============================================================
WORKER DE SCRAPING MULTI-SPORTS - GIG BENCHMARK
============================================================
RabbitMQ Host: rabbitmq
RabbitMQ User: gig_user
Queue: scraping_tasks
============================================================

SCRAPERS CHARGÉS (197):

Football (91):
   ✓ football.ligue_1
   ✓ football.champions_league
   ...

Tennis (89):
   ✓ tennis.atp_miami
   ✓ tennis.wta_roland_garros
   ...

Basketball (14):
   ✓ basketball.nba
   ...

Rugby (3):
   ✓ rugby.top_14
   ...
============================================================
```

## Error Handling

The system includes robust error handling:

1. **Import Errors**: Failed scrapers are logged but don't crash the worker
2. **Scraping Errors**: Captured with full stack trace, message rejected (no requeue)
3. **Connection Errors**: Automatic retry with exponential backoff
4. **Selenium Timeouts**: Graceful cleanup and error reporting

## Technical Concepts Demonstrated

- **Template Method Pattern**: Shared algorithm with variable parameters
- **DRY Principle**: Single source of truth for scraping logic
- **Message Queue Architecture**: Decoupled producer/consumer with RabbitMQ
- **Task Scheduling**: Celery Beat for periodic task execution
- **Microservices Architecture**: Separate containers for each concern (backend, scraping, consumer, scheduler)
- **Event-Driven Architecture**: Publish/subscribe pattern with 2 queues (`scraping_tasks` → `odds`)
- **Polymorphism via Configuration**: Same function, 197 use cases
- **Meta-Programming**: Code generation via scripting
- **Graceful Degradation**: Optional imports with fallbacks

## Complete Data Flow Examples

### Automatic Scraping Flow (Every 6 hours)

1. **Celery Beat** (timer): Triggers `auto_scrape_all_leagues()` every 6 hours
2. **Celery Worker**: Executes the task
3. **Task (tasks.py)**: Loops through 7 main leagues, calls Django API for each:
   ```python
   requests.post('http://backend:8000/api/scraping/trigger',
                 json={'scraper': 'football.ligue_1'})
   ```
4. **Django API** (`/api/scraping/trigger`): Publishes to RabbitMQ `scraping_tasks`:
   ```json
   { "scraper": "football.ligue_1", "params": {} }
   ```
5. **Scraping Worker** (`worker.py`): Consumes message, dispatches to `scrape_ligue_1()`
6. **Scraper** (`ligue_1.py`): Calls `scrape_league()` from `_scraper_utils.py`
7. **\_scraper_utils.py**:
   - Launches Selenium WebDriver
   - Scrapes coteur.com
   - Publishes results to RabbitMQ `odds` queue:
   ```json
   {
     "match": "PSG - Marseille",
     "bookmaker": "Betclic",
     "cotes": { "cote_1": 2.1, "cote_N": 3.2, "cote_2": 3.5 },
     "trj": 94.5,
     "league": "Ligue 1",
     "sport": "football"
   }
   ```
8. **Consumer Odds** (`consumer_odds.py`): Consumes `odds` queue, stores in MySQL
9. **MySQL Database**: Data persisted and available via Django API for frontend

### Manual Scraping Flow (On-Demand)

1. **User**: Runs `python manage.py scrape football.ligue_1` OR calls API
2. **Django Command/API**: Directly publishes to RabbitMQ `scraping_tasks`:
   ```json
   { "scraper": "football.ligue_1", "params": {} }
   ```
3. **Scraping Worker** (`worker.py`): Consumes message, dispatches to scraper
4. _(Same as steps 6-9 above)_

**Key Difference**: Manual mode bypasses Celery Beat and Celery Worker, directly publishing to RabbitMQ.

## Performance Metrics

- **Code Reduction**: 91% (39,400 → 3,361 lines)
- **Development Time**: ~2 hours (vs ~2-3 weeks manual)
- **Maintainability**: Single point of modification
- **Scalability**: Add competition in 2 minutes

## Contributing

When adding new sports or modifying scraping logic:

1. Ensure `_scraper_utils.py` handles the sport's odds structure correctly
2. Use the generator script for bulk additions
3. Test with a single competition before mass deployment
4. Update this README if adding new sports
