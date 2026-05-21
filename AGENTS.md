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
- Every push to `master` auto-creates a prerelease on GitHub with the APK attached.
- Pushing a tag `v*` creates a full (non-prerelease) Release.
- Release signing uses GitHub Secrets: `ANDROID_KEYSTORE_BASE64` (base64-encoded .jks), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. If absent, debug signing is used.

## Architecture

```
lib/
  main.dart                           — entry point
  app.dart                            — MaterialApp
  screens/
    browser_screen.dart               — InAppWebView + composes all services
    account_sheet.dart                — bottom sheet for account switching UI
  services/
    account_manager.dart              — Account CRUD + persistence (pure data)
    cookie_session_manager.dart       — Cookie session switch/capture/detect
    cookie_store.dart                 — CookieStore interface + adapters
    username_resolver.dart            — UsernameResolver: DOM + API strategies
  adblock/
    adblock_engine.dart               — Facade composing downloader→parser→matcher
    rule_set.dart                     — RuleSet value type (block/exception domain+path sets)
    url_matcher.dart                  — O(1) URL matching against RuleSet
    filter_list_parser.dart           — Filter text → RuleSet (pure function)
    filter_list_downloader.dart       — HTTP download + disk cache
  models/
    reddit_account.dart               — account data model with JSON serialization
```

## Deepened modules (refactored)

- **Adblock Pipeline** — `FilterListDownloader` + `FilterListParser` + `UrlMatcher` split from monolithic `AdblockEngine`. Each is independently testable. `UrlMatcher` accepts synthetic `RuleSet` directly (no HTTP/file I/O needed in tests).
- **Cookie Session Manager** — `CookieSessionManager` with `CookieStore` seam (abstracts `CookieManager.instance()`). `AccountManager` is now pure CRUD/persistence with no WebView dependency. Switching sessions: find account → `CookieSessionManager.switchToSession()` → `AccountManager.markActive()`.
- **Username Resolution** — `DomUsernameResolver` (JS eval) + `ApiUsernameResolver` (HTTP) + `CompositeUsernameResolver` (fallback chain) extracted from `BrowserScreen._handleLoginSuccess`.

## Key constraints

- `shouldInterceptRequest` fires for sub-resources (images, scripts, XHR). Main frame requests pass through — adblock only blocks sub-requests. Uses `isForMainFrame != true` guard.
- Filter lists are downloaded at startup from easylist.to + GitHub (uAssets). Stored in app documents dir under `webbit/filters/`. Download failures are silently ignored (cached version used if available).
- Cosmetic CSS is injected on each page load via `injectCSSCode()` to hide Reddit first-party promoted content.

## Features

- **Account switching** — multiple Reddit accounts stored as cookie profiles. Tap the profile button (bottom-right) to add or switch accounts. Login flow detected via `reddit_session` cookie in `onLoadStop`. Cookies serialized to `accounts.json` in app docs dir.

## Future work (not yet implemented)

- Embedded media previews for unsupported sites
- Caching layer for responsiveness
- Settings screen (filter list selection, user agent config)

## Android build note

Release builds require a signing config. The `build.gradle.kts` reads `ANDROID_KEYSTORE_PATH`/`ANDROID_KEYSTORE_PASSWORD`/`ANDROID_KEY_ALIAS`/`ANDROID_KEY_PASSWORD` env vars. If unset, debug signing is used (fine for testing).
