@echo off
echo Creating database file
type nul > db\db.sqlite3

echo Installing requirements
.venv\Scripts\pip install -r ppf-route-api\requirements.txt
.venv\Scripts\pip install -r ppf-user-api\requirements.txt
.venv\Scripts\pip install -r ppf-payments-api\requirements.txt

echo Installing editable ppf package
.venv\Scripts\pip install -e ppf

echo Creating migrations and loading sample data
.venv\Scripts\python ppf-route-api\manage.py makemigrations
.venv\Scripts\python ppf-route-api\manage.py migrate
.venv\Scripts\python ppf-route-api\manage.py loaddata sample_users.json sample_routes.json load_chargerTypes.json load_achievements.json service_profiles.json

echo Spinning up development environment
docker compose -f docker-compose.development.yml up -d