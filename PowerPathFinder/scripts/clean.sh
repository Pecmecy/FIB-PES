sudo "Started project cleanup"
echo "Composing down containers, this might take a while"
docker compose -f 'docker-compose.development.yml' down > /dev/null 2>&1

if [ "$1" = "ultra" ]; then
    echo "This is an ultra clean, YOU WILL LOSE ALL UN-PUSHED CHANGES!!!"
    read -p "Are you sure you want to continue? (y/n): " answer

    if [ "$answer" = "y" ]; then
        read -p "Is everything really pushed? (y/n): " answer2

        if [ "$answer2" = "y" ]; then
            echo "Prunning all docker system, this may take a while"
            sudo docker system prune -af > /dev/null 2>&1 &

            echo "Removing all cloned repositories"
            repos=("ppf-route-api" "ppf-user-api" "ppf-admin-page" "ppf-payments-api" "ppf-chat-engine")
            reload=false
            for repo in "${repos[@]}"; do
                rm -rf $repo
            done
        else
            echo "Skipping"
            break
        fi
    else
        echo "Skipping"
        break
    fi
fi


echo "Removing all python cache files, migrations, database, build files"
sudo find . -type d -name '__pycache__' -exec rm -fr {} + > /dev/null 2>&1 &
sudo find . -path 'ppf/common/migrations/*.py' -not -name '__init__.py' -delete > /dev/null 2>&1 &

echo "Removing all python installation files and database"
sudo rm -f db/db.sqlite3 > /dev/null 2>&1 &
sudo rm -rf db/chatengine > /dev/null 2>&1 &
sudo rm -rf ppf/build/ ppf/ppf.egg-info/ > /dev/null 2>&1 &

echo "Removing installed editable python packages"
sudo .venv/bin/pip uninstall -y ppf > /dev/null 2>&1 &

wait
if [ "$1" = "ultra" ]; then
    echo "🔥 ULTRA CLEAN COMPLETE 🔥"
else
    echo "🧼 Clean complete 🧼"
fi
echo ""