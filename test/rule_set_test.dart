import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/adblock/rule_set.dart';

void main() {
  group('RuleSet', () {
    test('merge combines two rule sets', () {
      final a = const RuleSet(
        domainFilters: {'a.com'},
        hardBlockedDomains: {},
        fontExtensions: {},
      );
      final b = const RuleSet(
        domainFilters: {'b.com'},
        exceptionDomains: {'c.com'},
        hardBlockedDomains: {},
        fontExtensions: {},
      );
      final merged = a.merge(b);
      expect(merged.domainFilters, contains('a.com'));
      expect(merged.domainFilters, contains('b.com'));
      expect(merged.exceptionDomains, contains('c.com'));
    });

    test('merge combines path maps', () {
      final a = const RuleSet(
        blockedPaths: {'a.com': {'/path1'}},
        hardBlockedDomains: {},
        fontExtensions: {},
      );
      final b = const RuleSet(
        blockedPaths: {'b.com': {'/path2'}},
        hardBlockedDomains: {},
        fontExtensions: {},
      );
      final merged = a.merge(b);
      expect(merged.blockedPaths,
          containsPair('a.com', contains('/path1')));
      expect(merged.blockedPaths,
          containsPair('b.com', contains('/path2')));
    });

    test('default constructor has hardcoded block lists', () {
      const rules = RuleSet();
      expect(rules.hardBlockedDomains, isNotEmpty);
      expect(rules.fontExtensions, isNotEmpty);
    });

    test('merge with empty returns same', () {
      const a = RuleSet(
        domainFilters: {'a.com'},
        hardBlockedDomains: {},
        fontExtensions: {},
      );
      final merged = a.merge(const RuleSet(
        hardBlockedDomains: {},
        fontExtensions: {},
      ));
      expect(merged.domainFilters, contains('a.com'));
    });
  });
}
