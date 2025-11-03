# Scraping Commands

## Manuel Scraping (205 scrapers avalable)

### Main Commands

```bash
# List of all avalable scrapers
make scrape-list

# target a championship
make scrape LEAGUE=football.ligue_1

# Manual
make help
```

---

## Football (105 championships)

### Top 5 EU Leagues

```bash
make scrape-ligue1           # Ligue 1
make scrape-premier-league   # Premier League
make scrape-la-liga          # La Liga
make scrape-serie-a          # Serie A
make scrape-bundesliga       # Bundesliga
```

### EU CUP

```bash
make scrape-champions-league    # Champions League
make scrape-europa-league       # Europa League
make scrape-conference-league   # Conference League
```

### Coupes Nationales

```bash
make scrape-coupe-france    # Coupe de France
make scrape-ligue2          # Ligue 2
```

### Scraper all football

```bash
make scrape-all-football    # 91 championships
```

---

## Tennis (89 tournements)

### Grand Chelem

```bash
make scrape-roland-garros   # Roland Garros (H+F)
make scrape-wimbledon       # Wimbledon (H+F)
make scrape-us-open         # US Open (H+F)
```

### Masters 1000

```bash
make scrape-atp-miami       # ATP Miami
make scrape-wta-miami       # WTA Miami
```

### Scraper all tennis

```bash
make scrape-all-tennis      # 89 tournois
```

---

## Basketball (15 leagues)

```bash
make scrape-nba              # NBA
make scrape-euroleague       # Euroleague
make scrape-betclic-elite    # Betclic Elite (France)
```

### Scraper all basketball

```bash
make scrape-all-basketball   # 14 ligues
```

---

## Rugby (3 compétitions)

```bash
make scrape-top14     # Top 14
make scrape-pro-d2    # Pro D2
```

### Scraper all rugby

```bash
make scrape-all-rugby    # 3 compétitions
```

---

## Automatic Scraping (Celery Beat)

### Automatic scraping management

```bash
# Check statuts
make auto-scrape-status

# Activate automatic scraping (6h)
make auto-scrape-enable

# Disable
make auto-scrape-disable

# Tests
make auto-scrape-test

# Check logs
make auto-scrape-logs
```

---

## Monitoring & Logs

### Logs in real time

```bash
# Worker scraping logs
make logs-scraping

# Consumer logs (stock DB)
make logs-consumer

# Celery logs (automatic)
make logs-celery

# Alllogs
make logs-all
```

### Vérifier RabbitMQ

```bash
# Queue informations
make check-rabbitmq

# Empty the queues
make rabbitmq-purge

# Interface web: http://localhost:15672
# User: gig_user / Pass: gig_password_2025
```

---

## Statistics and Data base

### View Data

```bash
# Global stats
make db-stats

# Check matchs
make db-matches

# Check bookmakers
make db-bookmakers

# Lastes Odds
make db-odds

# Best TRJ
make db-best-trj
```

### Cleaner

```bash
# Delete all the Odds (keep matchs)
make db-clean-odds

# Reset the database
make reset-db
```

---

## Workflow

### Manually scrape a competition

```bash
# 1. Start scraping
make scrape-ligue1

# 2. logs
make logs-scraping

# 3. Check Data
make db-stats
make db-odds
```

### Scraper all sports

```bash
# 212 scrapers
make scrape-all
```

---

## Practical Examples

### Top 5 Football Leagues

```bash
make scrape-ligue1
make scrape-premier-league
make scrape-la-liga
make scrape-serie-a
make scrape-bundesliga
```

### Grand Chelem

```bash
make scrape-roland-garros
make scrape-wimbledon
make scrape-us-open
```

### Scrape a specific, unlisted competition

```bash
# Syntaxe: make scrape LEAGUE=<sport>.<competition>
make scrape LEAGUE=football.copa_libertadores
make scrape LEAGUE=tennis.atp_paris
make scrape LEAGUE=basketball.eurocup
make scrape LEAGUE=rugby.test_match
```

---

## Debugging

### Scraping does not start

```bash
# Check that all services are UP
make ps

# Check worker
make logs-scraping

# Check RabbitMQ
make check-rabbitmq

# Health check
make health
```

### No data in the database

```bash
# Check consumer
make logs-consumer

# Check DB
make db-stats

# Check seeds
make seed-status
```

### Reset

```bash
# 1. Stop all Services
make down

# 2. Clean
make clean

# 3. Reset
make init
```

---

## Checklist de Démarrage

1. Docker services running

   ```bash
   make up
   make ps
   ```

2. Set DB

   ```bash
   make install-db
   make seed-status
   ```

3. Scraping testing

   ```bash
   make scrape-ligue1
   make logs-scraping
   ```

4. Check Data

   ```bash
   make db-stats
   make db-odds
   ```

5. Check the automatic worker
   ```bash
   make auto-scrape-enable
   make auto-scrape-status
   ```

---

## Summary of Capabilities

- **212 avalable scrapers**

  - 105 football competitions
  - 89 tennis tournements
  - 15 basketball leagues
  - 3 rugby competitions

- **2 scraping mode**

  - Manuel: On demand via Makefile
  - Automatic: Every 6h via Celery Beat

- **Distributed Architecture**
  - Scraping Worker: Executors
  - Consumer Odds: Stocke in DB
  - Celery Beat: Automatisation
  - RabbitMQ: Tasks queue

---

## To go further

View full documentation:

- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - Project overview
- [ARCHITECTURE_FLOWS.md](ARCHITECTURE_FLOWS.md) - Detailed diagrams
- [scraping/README.md](scraping/README.md) - Documentation technique scraping
