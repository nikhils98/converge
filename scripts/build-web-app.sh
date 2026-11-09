#!/bin/sh
# Build the Flutter web app and copy it into the website, which serves it at /app/.
# Commit the result: Cloudflare Pages builds only the website and does not have Flutter.
set -e
cd "$(dirname "$0")/.."
(cd app && flutter build web --release --base-href /app/)
rm -rf website/public/app
cp -r app/build/web website/public/app
echo "Copied the web build to website/public/app."
