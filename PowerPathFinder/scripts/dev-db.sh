#!/bin/bash

cd $(dirname "$0")/..

mkdir -p db
rm -f db/db.sqlite3
touch db/db.sqlite3