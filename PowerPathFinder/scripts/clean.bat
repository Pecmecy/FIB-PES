@echo off
echo Starting project cleanup
echo Composing down containers, this might take a while
docker compose -f docker-compose.development.yml down > NUL 2>&1

if "%1"=="ultra" (
    echo Prunning all docker system, this may take a while
    docker system prune -af
)

echo Removing all python cache files, migrations, database, build files
for /R %%G in (__pycache__) do (
    rmdir /s /q "%%G"
)

for /R %%G in (ppf\common\migrations\*.py) do (
    if not "%%~nxG"=="__init__.py" (
        del "%%G"
    )
)

echo Removing all python installation files and database
del /f /q db\db.sqlite3
rmdir /s /q ppf\build ppf\ppf.egg-info

echo Removing installed editable python packages
.venv\Scripts\pip uninstall -y ppf

echo 🧼 Clean complete 🧼
echo.