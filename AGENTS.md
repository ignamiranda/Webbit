# Webbit — AGENTS.md

Android APK wrapping Reddit mobile site with uBlock Origin filter-list ad blocking.

## Tech stack

- **Language**: Kotlin 2.1, **Build**: Gradle 8.11 + AGP 8.7 (Kotlin DSL, version catalog)
- **minSdk** 26 / **targetSdk** 35 / **compileSdk** 35
- **Single-Activity** (`MainActivity`) + fullscreen `WebView`

## Architecture

```
app/src/main/java/com/webbit/app/
├── adblock/
│   ├── FilterRule.kt          # Data model + uBlock filter list parser
│   ├── AdBlockerEngine.kt     # Domain-indexed block/exception engine
│   └── FilterListManager.kt   # Downloads & caches 4 uBlock lists via OkHttp
├── webview/
│   └── WebbitWebViewClient.kt # Intercepts requests, checks AdBlockerEngine
├── WebbitApp.kt               # Application class, schedules WorkManager updates
├── FilterUpdateWorker.kt      # Daily background filter list refresh
└── MainActivity.kt            # WebView host, loads filters on start
```

## Ad blocking — how it works

- `AdBlockerEngine` indexes rules by domain. On each request, it checks all subdomain candidates → path regex → resource type → exception rules.
- `WebbitWebViewClient.shouldInterceptRequest` returns an empty response for blocked URLs. Main document requests are never blocked.
- Filter lists are downloaded from `uBlockOrigin/uAssets` on first launch, cached in `context.cacheDir/filter_lists/`, and refreshed daily via `WorkManager`.
- Current sources: `filters.txt`, `privacy.txt`, `quick-fixes.txt`, `unbreak.txt`.

## Build commands

```bash
./gradlew assembleDebug          # Build debug APK
./gradlew assembleRelease        # Build release APK (minified w/ ProGuard)
```

APK output: `app/build/outputs/apk/debug/app-debug.apk`

## Notes

- No Gradle wrapper jar committed. Run `gradle wrapper` or open in Android Studio to generate it.
- Requires JDK 17+ and `ANDROID_HOME` pointing to an Android SDK with platforms 35.
- User agent strips `; wv)` to avoid WebView detection — reddit serves mobile site.
- Filter rules without a `||domain` prefix (bare path patterns) are treated as generic rules and checked against every request domain.
- Third-party and `domain=` filter options are parsed but **currently ignored** during matching.
- `proguard-rules.pro` keeps WebViewClient, OkHttp, and Coroutines entry points.
