import 'filter_list_downloader.dart';
import 'filter_list_parser.dart';
import 'rule_set.dart';
import 'url_matcher.dart';

class AdblockEngine {
  UrlMatcher _urlMatcher = UrlMatcher(const RuleSet());
  final FilterListDownloader _downloader = FilterListDownloader();
  final FilterListParser _parser = FilterListParser();
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> initializeFromCache() async {
    final cached = await _downloader.loadFromCache();
    _applyFilterTexts(cached);
    if (!_loaded) {
      _loaded = _urlMatcher.rules.domainFilters.isNotEmpty;
    }
  }

  Future<void> updateFilterLists() async {
    final downloaded = await _downloader.download();
    _applyFilterTexts(downloaded);
    _loaded = true;
  }

  Future<void> initialize() async {
    await initializeFromCache();
    await updateFilterLists();
  }

  void _applyFilterTexts(Map<String, String> texts) {
    var combined = const RuleSet();
    for (final entry in texts.entries) {
      final parsed = _parser.parse(entry.value, sourceUrl: entry.key);
      combined = combined.merge(parsed);
    }
    _urlMatcher = UrlMatcher(combined);
  }

  bool shouldBlock(String url) => _urlMatcher.shouldBlock(url);

  static const _cosmeticCSS = '''
    [data-ad-slot] { display: none !important; }
    .promotedlink { display: none !important; }
    [data-testid*="promoted"] { display: none !important; }
    [class*="promoted"] { display: none !important; }
    [id*="promoted"] { display: none !important; }
    [class*="ad-"] { display: none !important; }
    [id*="ad-"] { display: none !important; }
    shreddit-ad-post { display: none !important; }
    shreddit-comments-page-ad { display: none !important; }
    [data-faceplate-tracking-context*="promoted"] { display: none !important; }
    div[data-before-content="advertisement"] { display: none !important; }
    .native-ad-container { display: none !important; }
    shreddit-open-app-button { display: none !important; }
    a[href="/app"] { display: none !important; }
  ''';

  String get cosmeticFiltersCSS => _cosmeticCSS;

  String get initialCSSInjectionJS {
    final css = _cssEscape(_cosmeticCSS);
    return '''
(function() {
  var css = "$css";
  function injectCSS() {
    try {
      var sheet = new CSSStyleSheet();
      sheet.replaceSync(css);
      document.adoptedStyleSheets = [sheet];
      return true;
    } catch(e) {
      try {
        var head = document.head || document.querySelector("head");
        if (head) {
          var s = document.createElement("style");
          s.textContent = css;
          head.appendChild(s);
          return true;
        }
      } catch(e2) {}
    }
    return false;
  }
  if (!injectCSS()) {
    var obs = new MutationObserver(function() {
      if (injectCSS()) obs.disconnect();
    });
    obs.observe(document, { childList: true, subtree: true });
  }
  try { Object.defineProperty(navigator, 'maxTouchPoints', { get: function() { return 5; } }); } catch(e) {}
  try { Object.defineProperty(navigator, 'platform', { get: function() { return 'Android'; } }); } catch(e) {}
  try { Object.defineProperty(navigator, 'vendor', { get: function() { return 'Google Inc.'; } }); } catch(e) {}
})();
''';
  }

  String get cosmeticFiltersJS {
    final css = _cssEscape(_cosmeticCSS);
    return '''
(function() {
  var css = "$css";
  function injectCSS() {
    try {
      var sheet = new CSSStyleSheet();
      sheet.replaceSync(css);
      document.adoptedStyleSheets = [sheet];
      return true;
    } catch(e) {
      try {
        var head = document.head || document.querySelector("head");
        if (head) {
          var s = document.createElement("style");
          s.textContent = css;
          head.appendChild(s);
          return true;
        }
      } catch(e2) {}
    }
    return false;
  }
  injectCSS();
  function hideOpenApp() {
    try {
      ["shreddit-open-app-button", "a[href='/app']", "a[href*='reddit.com/app']"].forEach(function(sel) {
        document.querySelectorAll(sel).forEach(function(el) {
          el.style.setProperty("display", "none", "important");
        });
      });
      document.querySelectorAll("a, button, span").forEach(function(el) {
        if (el.textContent.trim() === "Open App") {
          el.style.setProperty("display", "none", "important");
        }
      });
    } catch(e) {}
  }
  hideOpenApp();
  try { new MutationObserver(hideOpenApp).observe(document.body, { childList: true, subtree: true }); } catch(e) {}
  (function loop() { hideOpenApp(); requestAnimationFrame(loop); })();
})();
''';
  }

  static String _cssEscape(String css) {
    return css
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
  }
}
