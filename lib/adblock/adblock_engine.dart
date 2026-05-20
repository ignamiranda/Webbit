import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AdblockEngine {
  static const _filterListUrls = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
    'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt',
    'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt',
  ];

  final Set<String> _domainFilters = {};
  final Set<String> _exceptionDomains = {};
  final List<_PathFilter> _pathFilters = [];
  final List<_PathFilter> _exceptionPaths = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/webbit/filters');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    await _loadFromCache(cacheDir);
    _updateFilterLists(cacheDir);
  }

  Future<void> _loadFromCache(Directory dir) async {
    for (final url in _filterListUrls) {
      final file = File('${dir.path}/${_listName(url)}.txt');
      if (await file.exists()) {
        _parseFilters(await file.readAsString(), url);
      }
    }
    _loaded = _domainFilters.isNotEmpty;
  }

  Future<void> _updateFilterLists(Directory dir) async {
    for (final url in _filterListUrls) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode == 200) {
          final file = File('${dir.path}/${_listName(url)}.txt');
          await file.writeAsString(response.body);
          _parseFilters(response.body, url);
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  void _parseFilters(String content, String sourceUrl) {
    final lines = const LineSplitter().convert(content);
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('!') || t.startsWith('[')) continue;

      if (t.startsWith('@@')) {
        var rule = t.substring(2).trim();
        if (rule.startsWith('||') && rule.endsWith('^')) {
          _exceptionDomains.add(rule.substring(2, rule.length - 1));
        } else if (rule.startsWith('||')) {
          final parts = rule.substring(2).split('^');
          if (parts.isNotEmpty && parts[0].contains('/')) {
            final si = parts[0].indexOf('/');
            _exceptionPaths.add(_PathFilter(
              parts[0].substring(0, si),
              parts[0].substring(si),
            ));
          }
        }
        continue;
      }

      if (t.contains('##') || t.contains('#')) continue;

      if (t.startsWith('||') && t.endsWith('^')) {
        _domainFilters.add(t.substring(2, t.length - 1));
        continue;
      }

      if (t.startsWith('||')) {
        final parts = t.substring(2).split('^');
        if (parts.isNotEmpty) {
          final first = parts[0];
          final si = first.indexOf('/');
          if (si > 0) {
            _pathFilters.add(_PathFilter(first.substring(0, si), first.substring(si)));
          } else {
            _domainFilters.add(first);
          }
        }
      }
    }
  }

  bool shouldBlock(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final path = uri.path;

      for (final ex in _exceptionDomains) {
        if (host == ex || host.endsWith('.$ex')) {
          return false;
        }
      }
      for (final ex in _exceptionPaths) {
        if ((host == ex.domain || host.endsWith('.${ex.domain}')) &&
            path.startsWith(ex.pathPrefix)) {
          return false;
        }
      }

      for (final domain in _domainFilters) {
        if (host == domain || host.endsWith('.$domain')) {
          return true;
        }
      }
      for (final f in _pathFilters) {
        if ((host == f.domain || host.endsWith('.${f.domain}')) &&
            path.startsWith(f.pathPrefix)) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static String _listName(String url) {
    final parts = url.split('/');
    final last = parts.last;
    return last.endsWith('.txt') ? last.substring(0, last.length - 4) : last;
  }

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

class _PathFilter {
  final String domain;
  final String pathPrefix;
  _PathFilter(this.domain, this.pathPrefix);
}
