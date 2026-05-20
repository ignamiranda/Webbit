# Webbit

Android WebView wrapper for reddit.com with built-in adblock using uBlock Origin filter lists.

## Stack

- **Flutter 3.38** (Dart 3.10) targeting **Android** + **Windows**
- `flutter_inappwebview: ^6.1` for WebView with network request interception (`shouldInterceptRequest`)
- Adblock via downloaded EasyList + uBlock Origin filter lists, parsed in `lib/adblock/`

## Key constraints

- `shouldInterceptRequest` fires for sub-resources (images, scripts, XHR). Main frame requests pass through — adblock only blocks sub-requests. Uses `isForMainFrame != true` guard.
- Filter lists are downloaded at startup from easylist.to + GitHub (uAssets). Stored in app documents dir under `webbit/filters/`. Download failures are silently ignored (cached version used if available).
- Cosmetic CSS is injected on each page load via `injectCSSCode()` to hide Reddit first-party promoted content.

## Commands

| Action | Command |
|--------|---------|
| Run on Windows (testing) | `flutter run -d windows` |
| Build APK (debug) | `flutter build apk --debug` |
| Build APK (release) | `flutter build apk --release` |
| Analyze | `flutter analyze` |
| Tests | `flutter test` |

## CI / Release

- `.github/workflows/build-apk.yml` — runs `flutter analyze` + `flutter test`, then builds and uploads release APK as artifact.
- Pushing a tag `v*` triggers a GitHub Release with the APK attached.
- Release signing uses GitHub Secrets: `ANDROID_KEYSTORE_BASE64` (base64-encoded .jks), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. If absent, debug signing is used.

## Architecture

```
lib/
  main.dart              — entry point
  app.dart               — MaterialApp
  screens/browser_screen.dart — InAppWebView + adblock wiring, loads www.reddit.com
  adblock/adblock_engine.dart  — filter download, parse, URL matching
```

## Future work (not yet implemented)

- Account switching (cookie/profile management)
- Embedded media previews for unsupported sites
- Caching layer for responsiveness
- Settings screen (filter list selection, user agent config)

## Android build note

Release builds require a signing config. The `build.gradle.kts` reads `ANDROID_KEYSTORE_PATH`/`ANDROID_KEYSTORE_PASSWORD`/`ANDROID_KEY_ALIAS`/`ANDROID_KEY_PASSWORD` env vars. If unset, debug signing is used (fine for testing).
