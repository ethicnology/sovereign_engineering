#!/usr/bin/env sh

# abort on errors
set -e

# build
flutter build web --release --base-href '/sovereign_engineering/'

# navigate into the build output directory
cd build/web

git init
git add -A
git commit -m 'deploy'

# if you are deploying to https://<USERNAME>.github.io/<REPO>
git push -f git@github.com:ethicnology/sovereign_engineering.git main:gh-pages #main or master

cd -