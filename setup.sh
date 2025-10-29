#!/bin/bash

echo "Setup GIG Scraping..."

# Permissions
chmod 755 -R backend/ frontend/ scraping/ database/
chmod +x setup.sh

# Dossiers
mkdir -p logs/nginx frontend/var backend/staticfiles backend/media
chmod -R 777 logs/ frontend/var/ 2>/dev/null || true

# Docker
docker compose down
docker compose build
docker compose up -d

# Attendre DB
echo "Attente de la base de donnees..."
sleep 20

# Migrations
docker compose exec -T backend python manage.py migrate --noinput || true

# Seeds
docker compose exec -T db mysql -uroot -p${DB_ROOT_PASSWORD:-root_password_secure_123} ${DB_NAME:-gig_benchmark} < database/seeds/01_sports.sql 2>/dev/null || true
docker compose exec -T db mysql -uroot -p${DB_ROOT_PASSWORD:-root_password_secure_123} ${DB_NAME:-gig_benchmark} < database/seeds/04_bookmakers.sql 2>/dev/null || true

# Symfony
docker compose exec php chmod -R 777 var/ 2>/dev/null || true
docker compose restart php nginx

echo ""
echo "Termine!"
echo "Frontend: http://localhost:10014"
echo "API:      http://localhost:8000"