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

  String get cosmeticFiltersCSS => '''
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
  ''';
}

class _PathFilter {
  final String domain;
  final String pathPrefix;
  _PathFilter(this.domain, this.pathPrefix);
}
