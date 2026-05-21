import 'dart:convert';
import 'rule_set.dart';

class FilterListParser {
  RuleSet parse(String content, {String? sourceUrl}) {
    var domainFilters = <String>{};
    var exceptionDomains = <String>{};
    var blockedPaths = <String, Set<String>>{};
    var exceptionPaths = <String, Set<String>>{};

    final lines = const LineSplitter().convert(content);
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('!') || t.startsWith('[')) continue;

      if (t.startsWith('@@')) {
        var rule = t.substring(2).trim();
        if (rule.startsWith('||') && rule.endsWith('^')) {
          exceptionDomains.add(rule.substring(2, rule.length - 1));
        } else if (rule.startsWith('||')) {
          _parsePathRule(rule.substring(2), exceptionPaths, exceptionDomains);
        }
        continue;
      }

      if (t.contains('##') || t.contains('#')) continue;

      if (t.startsWith('||') && t.endsWith('^')) {
        domainFilters.add(t.substring(2, t.length - 1));
        continue;
      }

      if (t.startsWith('||')) {
        _parsePathRule(t.substring(2), blockedPaths, domainFilters);
      }
    }

    return RuleSet(
      domainFilters: domainFilters,
      exceptionDomains: exceptionDomains,
      blockedPaths: blockedPaths,
      exceptionPaths: exceptionPaths,
      hardBlockedDomains: const {},
      fontExtensions: const {},
    );
  }

  void _parsePathRule(
    String rest,
    Map<String, Set<String>> pathTarget,
    Set<String> domainTarget,
  ) {
    final caretIndex = rest.indexOf('^');
    if (caretIndex < 0) {
      domainTarget.add(rest);
      return;
    }

    final domain = rest.substring(0, caretIndex);
    final afterCaret = rest.substring(caretIndex + 1);

    if (afterCaret.startsWith('/')) {
      pathTarget.putIfAbsent(domain, () => {}).add(afterCaret);
    } else if (domain.contains('/')) {
      final slashIndex = domain.indexOf('/');
      pathTarget
          .putIfAbsent(domain.substring(0, slashIndex), () => {})
          .add(domain.substring(slashIndex));
    } else {
      domainTarget.add(domain);
    }
  }
}
