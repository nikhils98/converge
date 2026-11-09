# Converge

This repository holds all parts of Converge:

- `app/` is the Flutter app for Android, iOS, and the web.
- `server/` is the Go game server. Render deploys it from this folder when a
  push to `main` changes files in it. It runs at https://converge-server.onrender.com.
- `web/` is the Astro website. Cloudflare Pages deploys it from this folder
  when a push to `main` changes files in it. It runs at https://converge-dg4.pages.dev.

The website serves the Flutter web app at `/app/` from a copy that is committed
in `web/public/app`. After you change the app, run
`scripts/build-web-app.sh` and commit the result to update the web version.
