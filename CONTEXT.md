# Webbit Domain Model

## Domain

- **Reddit Account** — a Reddit user profile with associated cookies that authenticate sessions. Stored in `accounts.json` with display name, optional username, and cookie list.
- **Cookie Session** — the set of HTTP cookies that authenticate a Reddit session (`reddit_session` cookie is the key). Cookies are stored per account and swapped when switching accounts.
- **Filter List** — a downloadable adblock rule list in EasyList/uBlock Origin format. Sources: EasyList, EasyPrivacy, uAssets filters, uAssets unbreak.
- **URL Matching** — the algorithm that decides whether to block a sub-resource request. Uses domain suffix matching and path-prefix matching against a `RuleSet`, with exception rules overriding block rules.
- **Username Resolution** — extracting a Reddit username from a login session. Two strategies: DOM scraping via JS evaluation in the WebView, and HTTP API fallback to `api/me.json`.
- **Adblock Pipeline** — the chain: `FilterListDownloader` → `FilterListParser` → `UrlMatcher`. Each module has a single seam and is independently testable.

## Module Map

```
lib/
  adblock/
    rule_set.dart              — RuleSet value type (domain sets + path maps)
    url_matcher.dart           — UrlMatcher: shouldBlock(url) against a RuleSet
    filter_list_parser.dart    — FilterListParser: filter text → RuleSet
    filter_list_downloader.dart — FilterListDownloader: HTTP download + disk cache
    adblock_engine.dart        — Facade composing downloader → parser → matcher
  services/
    account_manager.dart       — Account CRUD + persistence (pure data, no cookie ops)
    cookie_store.dart          — CookieStore interface + WebViewCookieStore + FakeCookieStore
    cookie_session_manager.dart — CookieSessionManager: switch, capture, detect sessions
    username_resolver.dart     — UsernameResolver interface + Dom/Api/Composite resolvers
  screens/
    browser_screen.dart        — Composes adblock + account mgmt + session mgmt + username resolve
    account_sheet.dart         — Pure UI bottom sheet for account switching
  models/
    reddit_account.dart        — RedditAccount data class with JSON serialization
```

## Key interfaces at seams

| Interface | Adapters | Tests |
|-----------|----------|-------|
| `CookieStore` | `WebViewCookieStore` (prod), `FakeCookieStore` (test) | `cookie_session_manager_test.dart` |
| `UsernameResolver` | `DomUsernameResolver` (prod), `ApiUsernameResolver` (prod), `FakeUsernameResolver` (test) | `username_resolver_test.dart` |
| `UrlMatcher` | instantiated with `RuleSet` (no adapter needed) | `url_matcher_test.dart` |
| `FilterListParser` | pure function (no adapter needed) | `filter_list_parser_test.dart` |
