#!/bin/bash
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

read -p "Are you sure you want to continue? (y/n): " answer

if [ "$answer" = "y" ]; then
    echo Removing all cloned repositories
    rm -rf ppf-route-api
    rm -rf ppf-user-api
    rm -rf ppf-admin-page
    rm -rf ppf-payments-api
    rm -rf ppf-chat-engine
    rm -rf ppf_mobile_client
    echo Removing database
    rm -rf db

    echo ""
    echo "Removal completed"
else
    exit 1
fi
