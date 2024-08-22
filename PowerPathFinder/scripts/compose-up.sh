# Get the first argument into a variable
ARG1="$1"

# If a service is not present, clone it
repos=("ppf-route-api" "ppf-user-api" "ppf-admin-page" "ppf-payments-api" "ppf-chat-engine")

reload=false
for repo in "${repos[@]}"; do
    if [ ! -d "$repo" ]; then
        reload=true
        echo "Cloning $repo"
        git clone https://github.com/pes2324q2-gei-upc/$repo.git &
    fi
done

if [ $reload = true ]; then
    wait
    echo "-----------------------------------------------------"
    echo "| repos have been cloned! reload your vscode window |"
    echo "-----------------------------------------------------"
    exit 1
fi

echo "Creating database files"
mkdir -p ./db
mkdir -p ./db/chatengine

touch ./db/db.sqlite3
touch ./db/chatengine/chat.db

echo "Installing requirements"
.venv/bin/pip install -r ppf-route-api/requirements.txt &
.venv/bin/pip install -r ppf-user-api/requirements.txt &
.venv/bin/pip install -r ppf-payments-api/requirements.txt &
echo "Installing editable ppf package"
.venv/bin/pip install -e ppf &
wait

echo "Creating migrations and loading sample data"
.venv/bin/python ppf-route-api/manage.py makemigrations
.venv/bin/python ppf-route-api/manage.py migrate
.venv/bin/python ppf-route-api/manage.py loaddata load_chargerTypes.json service_profiles.json load_achievements.json
.venv/bin/python ppf-route-api/manage.py loaddata sample_users.json sample_routes.json
echo "Spinning up development environment"

echo "Spinning up development environment"
if [ "$1" = "macos" ]; then
    docker compose -f 'docker-compose.development.yml' -f 'docker-compose.macos.yml' up -d
    exit 0
fi

docker compose -f 'docker-compose.development.yml' up -d