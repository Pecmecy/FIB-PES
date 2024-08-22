# Get the first argument into a variable
ARG1="$1"

cd $(dirname "$0")/..

echo this will remove the following folders:
echo ppf-route-api
echo ppf-user-api
echo ppf-admin-page
echo ppf-payments-api
echo ppf-chat-engine
echo ppf_mobile_client
echo db
echo .gitmodules

read -p "Are you sure you want to continue? (y/n): " answer

if [ "$answer" = "y" ]; then
    echo Removing all cloned repositories
    rm -rf ppf-route-api &
    rm -rf ppf-user-api &
    rm -rf ppf-admin-page &
    rm -rf ppf-payments-api &
    rm -rf ppf-chat-engine &
    rm -rf ppf_mobile_client &
    wait
    echo Removing database
    rm -rf db
    echo Removing .gitmodules
    rm -f .gitmodules # Remove .gitmodules file
    echo ""
    echo "Removal completed"
else
    exit 1
fi

# If a service is not present, clone it
repos=("ppf-route-api" "ppf-user-api" "ppf-admin-page" "ppf-payments-api" "ppf-chat-engine" "ppf_mobile_client")

reload=false
echo Recreating .gitmodules file
# Add submodule paths to .gitmodules
for repo in "${repos[@]}"; do
    echo "[submodule \"$repo\"]" >>.gitmodules
    echo "    path = $repo" >>.gitmodules
    echo "    url = https://github.com/pes2324q2-gei-upc/$repo.git" >>.gitmodules

    if [ ! -d "$repo" ]; then
        reload=true
        echo "Cloning $repo"
        git submodule add -f https://github.com/pes2324q2-gei-upc/$repo.git &
    fi
    wait
done

if [ $reload = true ]; then
    wait
    echo Initializing and updating submodules...
    if git submodule init && git submodule update && git submodule update --remote; then
        echo "Submodules initialized and updated successfully."
    else
        echo "Failed to initialize or update submodules. Please check the logs for more details."
        exit 1
    fi

    wait

    echo "-----------------------------------------------------"
    echo "| repos have been cloned! reload your vscode window |"
    echo "-----------------------------------------------------"

    echo creating database file...

    mkdir -p db
    rm -f db/db.sqlite3
    touch db/db.sqlite3
    touch db/chatengine/chat.db

    echo Set-up complete
fi
