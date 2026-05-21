import 'rule_set.dart';

class UrlMatcher {
  const UrlMatcher(this.rules);
  final RuleSet rules;

  bool shouldBlock(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final path = uri.path;

      if (_matchesException(host, path)) return false;
      if (_matchesAnyDomain(host, rules.hardBlockedDomains)) return true;
      if (_isFontUrl(path)) return true;
      if (_matchesAnyDomain(host, rules.domainFilters)) return true;
      if (_matchesAnyPath(host, path, rules.blockedPaths)) return true;
    } catch (_) {}
    return false;
  }

  bool _matchesException(String host, String path) {
    if (_matchesAnyDomain(host, rules.exceptionDomains)) return true;
    if (_matchesAnyPath(host, path, rules.exceptionPaths)) return true;
    return false;
  }

  bool _matchesAnyDomain(String host, Set<String> domains) {
    if (domains.contains(host)) return true;
    var dotIndex = host.indexOf('.');
    while (dotIndex > 0 && dotIndex < host.length - 1) {
      if (domains.contains(host.substring(dotIndex + 1))) return true;
      dotIndex = host.indexOf('.', dotIndex + 1);
    }
    return false;
  }

  bool _matchesAnyPath(
      String host, String path, Map<String, Set<String>> pathMap) {
    var current = host;
    while (true) {
      final rules = pathMap[current];
      if (rules != null) {
        for (final prefix in rules) {
          if (path.startsWith(prefix)) return true;
        }
      }
      final dotIndex = current.indexOf('.');
      if (dotIndex <= 0 || dotIndex >= current.length - 1) break;
      current = current.substring(dotIndex + 1);
    }
    return false;
  }

  bool _isFontUrl(String path) {
    final lower = path.toLowerCase();
    for (final ext in rules.fontExtensions) {
      if (lower.endsWith(ext)) return true;
    }
    return false;
  }
}
