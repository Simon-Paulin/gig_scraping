include .env
export

.PHONY: help build up down restart logs clean

# ============================================
# HELP
# ============================================
help:
	@echo "Commandes disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================
# DOCKER
# ============================================
build: ## Construit les images
	docker compose build

build-scrap: ## Construit image du scraping
	docker compose build scraping

up: ## Demarre tous les services
	docker compose up -d

down: ## Arrete tous les services
	docker compose down

restart: down up ## Redémarre tous les services

ps: ## Liste les services
	docker compose ps

clean: ## Nettoie volumes et containers
	docker compose down -v
	docker system prune -f

cache: ## Vide cache symfony
	docker compose exec php php bin/console cache:clear

# ============================================
# MIGRATIONS
# ============================================
makemigrations: ## Cree les migrations Django
	docker compose exec backend python manage.py makemigrations

migrate: ## Applique les migrations
	docker compose exec backend python manage.py migrate

migrate-fake: ## Marque les migrations comme appliquees
	docker compose exec backend python manage.py migrate --fake

showmigrations: ## Affiche les migrations
	docker compose exec backend python manage.py showmigrations

# ============================================
# SEEDS
# ============================================
seed-all: ## Insere toutes les donnees de reference
	@echo "Insertion des seeds..."
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/01_sports.sql
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/02_markets.sql
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/03_leagues.sql
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/04_bookmakers.sql
	@echo "Seeds inseres avec succes"

seed-sports: ## Insere les sports
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/01_sports.sql

seed-markets: ## Insere les marches
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/02_markets.sql

seed-leagues: ## Insere les ligues
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/03_leagues.sql

seed-bookmakers: ## Insere les bookmakers
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME) < database/seeds/04_bookmakers.sql

# ============================================
# SEEDS MANAGEMENT
# ============================================
seed-status: ## Affiche le statut des seeds
	@echo "Statut des seeds dans la base de donnees:"
	@echo "----------------------------------------"
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT \
	    'Sports' as Seed, \
	    COUNT(*) as Count, \
	    CASE WHEN COUNT(*) > 0 THEN 'APPLIED' ELSE 'PENDING' END as Status \
	FROM Sports \
	UNION ALL \
	SELECT \
	    'Markets', \
	    COUNT(*), \
	    CASE WHEN COUNT(*) > 0 THEN 'APPLIED' ELSE 'PENDING' END \
	FROM MarketNames \
	UNION ALL \
	SELECT \
	    'Leagues', \
	    COUNT(*), \
	    CASE WHEN COUNT(*) > 0 THEN 'APPLIED' ELSE 'PENDING' END \
	FROM Leagues \
	UNION ALL \
	SELECT \
	    'Bookmakers', \
	    COUNT(*), \
	    CASE WHEN COUNT(*) > 0 THEN 'APPLIED' ELSE 'PENDING' END \
	FROM Bookmakers;" 2>/dev/null || echo "Erreur: Base de donnees non accessible"

seed-check: ## Verifie si les seeds sont necessaires
	@echo "Verification des seeds..."
	@SPORTS=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM Sports" 2>/dev/null); \
	MARKETS=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM MarketNames" 2>/dev/null); \
	LEAGUES=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM Leagues" 2>/dev/null); \
	BOOKMAKERS=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM Bookmakers" 2>/dev/null); \
	if [ "$$SPORTS" = "0" ] || [ "$$MARKETS" = "0" ] || [ "$$LEAGUES" = "0" ] || [ "$$BOOKMAKERS" = "0" ]; then \
		echo "Seeds manquants detectes. Executez 'make seed-apply'"; \
		exit 1; \
	else \
		echo "Tous les seeds sont appliques"; \
	fi

seed-apply: ## Applique tous les seeds manquants
	@echo "Application des seeds..."
	@SPORTS=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM Sports" 2>/dev/null); \
	if [ "$$SPORTS" = "0" ]; then \
		echo "Application: 01_sports.sql"; \
		docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/01_sports.sql; \
	else \
		echo "Skip: 01_sports.sql (deja applique)"; \
	fi
	@MARKETS=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM MarketNames" 2>/dev/null); \
	if [ "$$MARKETS" = "0" ]; then \
		echo "Application: 02_markets.sql"; \
		docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/02_markets.sql; \
	else \
		echo "Skip: 02_markets.sql (deja applique)"; \
	fi
	@LEAGUES=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM Leagues" 2>/dev/null); \
	if [ "$$LEAGUES" = "0" ]; then \
		echo "Application: 03_leagues.sql"; \
		docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/03_leagues.sql; \
	else \
		echo "Skip: 03_leagues.sql (deja applique)"; \
	fi
	@BOOKMAKERS=$$(docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -sN -e "SELECT COUNT(*) FROM Bookmakers" 2>/dev/null); \
	if [ "$$BOOKMAKERS" = "0" ]; then \
		echo "Application: 04_bookmakers.sql"; \
		docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/04_bookmakers.sql; \
	else \
		echo "Skip: 04_bookmakers.sql (deja applique)"; \
	fi
	@echo "Seeds appliques avec succes"

seed-force: ## Force la reapplication de tous les seeds
	@echo "ATTENTION: Cette operation va SUPPRIMER toutes les donnees de reference"
	@echo "Les cotes existantes seront conservees"
	@read -p "Continuer ? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "Suppression des donnees de reference..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SET FOREIGN_KEY_CHECKS=0; \
	TRUNCATE TABLE Bookmakers; \
	TRUNCATE TABLE Leagues; \
	TRUNCATE TABLE MarketNames; \
	TRUNCATE TABLE Sports; \
	SET FOREIGN_KEY_CHECKS=1;"
	@echo "Reapplication des seeds..."
	$(MAKE) seed-all

seed-refresh: ## Met a jour les seeds sans supprimer
	@echo "Mise a jour des seeds..."
	@echo "Sports..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/01_sports.sql
	@echo "Markets..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/02_markets.sql
	@echo "Leagues..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/03_leagues.sql
	@echo "Bookmakers..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < database/seeds/04_bookmakers.sql
	@echo "Seeds mis a jour avec succes"

seed-validate: ## Valide l'integrite des seeds
	@echo "Validation de l'integrite des seeds..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT 'Verification des Sports' as Test; \
	SELECT CASE WHEN COUNT(*) >= 4 THEN 'PASS' ELSE 'FAIL' END as Status, \
	       COUNT(*) as Expected_Min_4 \
	FROM Sports; \
	SELECT 'Verification des Markets' as Test; \
	SELECT CASE WHEN COUNT(*) >= 20 THEN 'PASS' ELSE 'FAIL' END as Status, \
	       COUNT(*) as Expected_Min_20 \
	FROM MarketNames; \
	SELECT 'Verification des Leagues' as Test; \
	SELECT CASE WHEN COUNT(*) >= 20 THEN 'PASS' ELSE 'FAIL' END as Status, \
	       COUNT(*) as Expected_Min_20 \
	FROM Leagues; \
	SELECT 'Verification des Bookmakers' as Test; \
	SELECT CASE WHEN COUNT(*) >= 15 THEN 'PASS' ELSE 'FAIL' END as Status, \
	       COUNT(*) as Expected_Min_15 \
	FROM Bookmakers;"
	
# ============================================
# LOGS
# ============================================
logs: ## Logs de tous les services
	docker compose logs -f

logs-backend: ## Logs backend
	docker compose logs backend -f

logs-scraping: ## Logs scraping
	docker compose logs scraping -f

logs-consumer: ## Logs consumer
	docker compose logs consumer_odds -f

logs-celery-worker: ## Logs celery worker
	docker compose logs celery_worker --tail=50 -f

logs-celery-beat: ## Logs celery beat
	docker compose logs celery_beat --tail=50 -f

logs-celery: ## Logs celery worker et beat
	docker compose logs celery_worker celery_beat -f

logs-rabbitmq: ## Logs RabbitMQ
	docker compose logs rabbitmq -f

logs-all: ## Logs de tous les services
	docker compose logs -f --tail=50

logs-front-symfony:
	sudo docker compose exec php tail -50 /var/www/html/var/log/dev.log

logs-front-php:
	sudo docker compose logs php --tail=30
# ============================================
# SHELLS
# ============================================
shell-backend: ## Shell backend
	docker compose exec backend /bin/bash

shell-scraping: ## Shell scraping
	docker compose exec scraping /bin/bash

shell-db: ## Shell MySQL
	docker compose exec db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME)

shell-db-root: ## Shell MySQL root
	docker compose exec db mysql -uroot -p$(DB_ROOT_PASSWORD) $(DB_NAME)

shell-python: ## Shell Python Django
	docker compose exec backend python manage.py shell

# ============================================
# DATABASE - SETUP
# ============================================
install-db: ## Installe la BDD complete
	@echo "Installation de la base de donnees..."
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) -e "CREATE DATABASE IF NOT EXISTS $(DB_NAME);"
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) -e "GRANT ALL PRIVILEGES ON $(DB_NAME).* TO '$(DB_USER)'@'%';"
	docker compose exec -T db mysql -uroot -p$(DB_ROOT_PASSWORD) -e "FLUSH PRIVILEGES;"
	$(MAKE) migrate
	$(MAKE) seed-all
	@echo "Base de donnees installee avec succes"

reset-db: ## Reinitialise la BDD
	@echo "ATTENTION: Suppression de toutes les donnees!"
	@read -p "Continuer ? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose down
	docker volume rm gig-benchmark_db_data || true
	docker compose up -d db
	@echo "Attente de la base de donnees..."
	@sleep 20
	docker compose up -d
	@sleep 10
	$(MAKE) install-db

check-db: ## Verifie la BDD
	docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT 'Sports' as Table_Name, COUNT(*) as Count FROM Sports \
	UNION ALL SELECT 'Bookmakers', COUNT(*) FROM Bookmakers \
	UNION ALL SELECT 'Matches', COUNT(*) FROM Matches \
	UNION ALL SELECT 'Odds', COUNT(*) FROM Odds;"

# ============================================
# DATABASE - STATS
# ============================================
db-stats: ## Statistiques generales
	@echo "Statistiques de la base de donnees"
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT 'Sports' as Table_Name, COUNT(*) as Count FROM Sports \
	UNION ALL SELECT 'Ligues', COUNT(*) FROM Leagues \
	UNION ALL SELECT 'Equipes', COUNT(*) FROM Teams \
	UNION ALL SELECT 'Matchs', COUNT(*) FROM Matches \
	UNION ALL SELECT 'Bookmakers', COUNT(*) FROM Bookmakers \
	UNION ALL SELECT 'Cotes', COUNT(*) FROM Odds;"

db-matches: ## Liste tous les matchs
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT m.id, l.name as Ligue, CONCAT(ht.name, ' - ', at.name) as Rencontre, \
	DATE_FORMAT(m.match_date, '%Y-%m-%d %H:%i') as Date, m.status as Statut, \
	COUNT(DISTINCT o.bookmaker_id) as Nb_Bookmakers \
	FROM Matches m \
	JOIN Leagues l ON m.league_id = l.id \
	JOIN Teams ht ON m.home_team_id = ht.id \
	JOIN Teams at ON m.away_team_id = at.id \
	LEFT JOIN Odds o ON m.id = o.match_id \
	GROUP BY m.id ORDER BY m.match_date;"

db-bookmakers: ## Liste les bookmakers avec stats
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT b.name as Bookmaker, COUNT(DISTINCT o.match_id) as Nb_Matchs, \
	COUNT(o.id) as Nb_Cotes, ROUND(AVG(o.trj), 2) as TRJ_Moyen, \
	ROUND(MAX(o.trj), 2) as Meilleur_TRJ \
	FROM Bookmakers b LEFT JOIN Odds o ON b.id = o.bookmaker_id \
	GROUP BY b.id ORDER BY TRJ_Moyen DESC;"

db-odds: ## Dernieres cotes
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT CONCAT(ht.name, ' - ', at.name) as Rencontre, b.name as Bookmaker, \
	o.outcome as Issue, o.odd_value as Cote, o.trj as TRJ, \
	DATE_FORMAT(o.scraped_at, '%d/%m %H:%i') as Date \
	FROM Odds o \
	JOIN Matches m ON o.match_id = m.id \
	JOIN Teams ht ON m.home_team_id = ht.id \
	JOIN Teams at ON m.away_team_id = at.id \
	JOIN Bookmakers b ON o.bookmaker_id = b.id \
	ORDER BY o.scraped_at DESC LIMIT 20;"

db-best-trj: ## Meilleurs TRJ par match
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "\
	SELECT CONCAT(ht.name, ' - ', at.name) as Rencontre, b.name as Bookmaker, \
	ROUND(AVG(o.trj), 2) as TRJ_Moyen, \
	GROUP_CONCAT(CONCAT(o.outcome, ':', o.odd_value) ORDER BY o.outcome SEPARATOR ' | ') as Cotes \
	FROM Odds o \
	JOIN Matches m ON o.match_id = m.id \
	JOIN Teams ht ON m.home_team_id = ht.id \
	JOIN Teams at ON m.away_team_id = at.id \
	JOIN Bookmakers b ON o.bookmaker_id = b.id \
	GROUP BY m.id, b.id \
	HAVING COUNT(o.id) = 3 \
	ORDER BY TRJ_Moyen DESC LIMIT 10;"

db-clean-odds: ## Supprime toutes les cotes
	@echo "Suppression de toutes les cotes..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "TRUNCATE TABLE Odds;"
	@echo "Cotes supprimees"

db-query: ## Execute une requete SQL (usage: make db-query SQL="SELECT * FROM Sports")
	@if [ -z "$(SQL)" ]; then echo "Usage: make db-query SQL=\"SELECT * FROM Sports\""; exit 1; fi
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) -e "$(SQL)"

# ============================================
# SCRAPING
# ============================================
scrape-ligue1: ## Lance scraping Ligue 1
	docker compose exec scraping python send_task.py football.ligue_1

scrape-serie_a: ## Lance scraping Serie A
	docker compose exec scraping python send_task.py football.serie_a

scrape-premier_league: ## Lance scraping Premier League
	docker compose exec scraping python send_task.py football.premier_league

scrape-liga: ## Lance scraping La Liga
	docker compose exec scraping python send_task.py football.la_liga

scrape-bundesliga: ## Lance scraping Bundesliga
	docker compose exec scraping python send_task.py football.bundesliga

scrape-all: ## Lance scraping toutes les ligues
	$(MAKE) scrape-ligue1
	$(MAKE) scrape-premier_league
	$(MAKE) scrape-liga
	$(MAKE) scrape-serie_a
	$(MAKE) scrape-bundesliga

# ============================================
# RABBITMQ
# ============================================
check-rabbitmq: ## Verifie RabbitMQ
	@echo "RabbitMQ Management: http://localhost:15672"
	@echo "User: $(RABBITMQ_USER) | Pass: $(RABBITMQ_PASSWORD)"
	@docker compose exec rabbitmq rabbitmqctl list_queues

rabbitmq-purge: ## Vide les queues
	docker compose exec rabbitmq rabbitmqctl purge_queue odds
	docker compose exec rabbitmq rabbitmqctl purge_queue scraping_tasks

# ============================================
# HEALTH CHECK
# ============================================
health: ## Health check complet
	@echo "Health Check..."
	@docker compose exec -T db mysql -u$(DB_USER) -p$(DB_PASSWORD) -e "SELECT 'MySQL OK';" 2>/dev/null && echo "MySQL: OK" || echo "MySQL: ERROR"
	@docker compose exec rabbitmq rabbitmqctl status > /dev/null 2>&1 && echo "RabbitMQ: OK" || echo "RabbitMQ: ERROR"
	@curl -s http://localhost:$(BACKEND_PORT)/api/scraping/health > /dev/null && echo "Backend: OK" || echo "Backend: ERROR"

# ============================================
# WORKFLOW COMPLET
# ============================================
init: ## Initialisation complete du projet
	$(MAKE) build
	$(MAKE) up
	@sleep 20
	$(MAKE) install-db
	@echo "Projet initialise avec succes"

demo: ## Demo complete
	@echo "Demo complete"
	@echo "1. Lancement du scraping..."
	$(MAKE) scrape-ligue1
	@sleep 30
	@echo "2. Statistiques:"
	$(MAKE) db-stats
	@echo "3. Meilleurs TRJ:"
	$(MAKE) db-best-trj

status: ## Affiche le statut complet
	@echo "Statut des services:"
	$(MAKE) ps
	@echo ""
	@echo "Statistiques de la base:"
	$(MAKE) db-stats
	@echo ""
	@echo "Health check:"
	$(MAKE) health
# ============================================
# AUTO SCRAPING
# ============================================
auto-scrape-status: ## Statut du scraping automatique
	@echo "Taches periodiques actives:"
	@docker compose exec backend python manage.py shell -c "from django_celery_beat.models import PeriodicTask; [print(f'{t.name}: enabled={t.enabled}') for t in PeriodicTask.objects.all()]"

auto-scrape-enable: ## Active le scraping automatique
	@echo "Activation du scraping automatique..."
	@docker compose exec backend python manage.py shell -c "from django_celery_beat.models import PeriodicTask; t=PeriodicTask.objects.get(name='Scraping automatique toutes les 6h'); t.enabled=True; t.save(); print('ACTIVE')"
	@docker compose restart celery_beat > /dev/null 2>&1

auto-scrape-disable: ## Desactive le scraping automatique
	@echo "Desactivation du scraping automatique..."
	@docker compose exec backend python manage.py shell -c "from django_celery_beat.models import PeriodicTask; t=PeriodicTask.objects.get(name='Scraping automatique toutes les 6h'); t.enabled=False; t.save(); print('DESACTIVE')"
	@docker compose restart celery_beat > /dev/null 2>&1

auto-scrape-test: ## Lance un scraping automatique immediatement
	@echo "Lancement du scraping..."
	@docker compose exec backend python manage.py shell -c "from core.tasks import auto_scrape_all_leagues; r=auto_scrape_all_leagues.delay(); print(f'Task ID: {r.id}')"
	@echo "Suivre: sudo make logs-celery-worker"

auto-scrape-logs: ## Logs du scraping automatique
	@docker compose logs celery_worker celery_beat --tail=50 -f