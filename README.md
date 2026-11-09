# Converge

Converge is a two-player word game. Each round, both players enter a word, and
they win when they enter the same word in the same round.

This repository holds all parts of Converge:

- `app/` is the Flutter app for Android, iOS, and the web.
- `server/` is the Go game server. It runs at https://converge-server.onrender.com.
- `web/` is the Astro website. It runs at https://converge-dg4.pages.dev and
  serves the Flutter web app at `/app/`.

## Deploying

### Server

Render deploys the server automatically when a push to `main` changes files in
`server/`. Pushes that only change other folders do not start a server deploy.

To start a deploy by hand, use the Render dashboard or run:

```sh
render deploys create srv-csjrtbbtq21c73dgh0bg --confirm
```

The server accepts browser connections only from the website's address. If the
website moves to a new address, update the allowed origin in `server/src/main.go`.

### Website and web app

Cloudflare Pages deploys the website automatically when a push to `main` changes
files in `web/`. It runs `npm run build` in `web/` and publishes `web/dist`.

Cloudflare does not build the Flutter app. The website serves a copy of the web
build that is committed in `web/public/app`. To update the web version of the
app:

1. Run `scripts/build-web-app.sh`. It builds the Flutter web app and copies it
   into `web/public/app`.
2. Commit the changes and push to `main`.

### Android app

1. Increase `version` in `app/pubspec.yaml`. The number after the `+` must go
   up with each release.
2. In `app/`, run `flutter build appbundle --release`. The signing key settings
   come from `app/android/key.properties`, which is not committed.
3. In Play Console, open **Test and release → Production**, create a new
   release, and upload `app/build/app/outputs/bundle/release/app-release.aab`.

If the build ends with "failed to strip debug symbols", install the Android SDK
Command-line Tools from the Android Studio SDK Manager. The bundle is still
safe to upload.

The app connects to the server address in `app/lib/views/game_view.dart`. If the
server moves, change it there and release new versions of the web and Android
apps.
