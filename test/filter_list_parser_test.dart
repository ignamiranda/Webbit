import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/adblock/filter_list_parser.dart';

void main() {
  late FilterListParser parser;

  setUp(() {
    parser = FilterListParser();
  });

  group('FilterListParser', () {
    test('parses domain filter from ||domain^', () {
      final rules = parser.parse('||ads.example.com^\n');
      expect(rules.domainFilters, contains('ads.example.com'));
    });

    test('parses domain with path filter', () {
      final rules = parser.parse('||ads.example.com^/track/pixel\n');
      expect(rules.domainFilters, isEmpty);
      expect(
          rules.blockedPaths,
          containsPair('ads.example.com',
              contains('/track/pixel')));
    });

    test('parses exception domain from @@||domain^', () {
      final rules = parser.parse('@@||example.com^\n');
      expect(rules.exceptionDomains, contains('example.com'));
    });

    test('parses exception with path', () {
      final rules = parser.parse('@@||example.com^/allow\n');
      expect(
          rules.exceptionPaths,
          containsPair('example.com',
              contains('/allow')));
    });

    test('skips cosmetic rules with ##', () {
      final rules = parser.parse('example.com##.ad-banner\n');
      expect(rules.domainFilters, isEmpty);
    });

    test('skips comments starting with !', () {
      final rules = parser.parse('! this is a comment\n||blocked.com^\n');
      expect(rules.domainFilters, contains('blocked.com'));
      expect(rules.domainFilters.length, 1);
    });

    test('skips metadata lines starting with [', () {
      final rules = parser.parse('[Adblock Plus 2.0]\n||blocked.com^\n');
      expect(rules.domainFilters, contains('blocked.com'));
    });

    test('skips empty lines', () {
      final rules = parser.parse('||blocked.com^\n\n||also.com^\n');
      expect(rules.domainFilters, contains('blocked.com'));
      expect(rules.domainFilters, contains('also.com'));
    });

    test('parses domain without trailing ^', () {
      final rules = parser.parse('||tracking.example.com\n');
      expect(rules.domainFilters, contains('tracking.example.com'));
    });

    test('parses multiple rules from one list', () {
      final content = '''
! Title
||ads.example.com^
||tracker.example.com^/pixel
@@||allowed.example.com^
@@||allowed.example.com^/path
''';
      final rules = parser.parse(content);
      expect(rules.domainFilters, contains('ads.example.com'));
      expect(rules.blockedPaths,
          containsPair('tracker.example.com', contains('/pixel')));
      expect(rules.exceptionDomains, contains('allowed.example.com'));
      expect(rules.exceptionPaths,
          containsPair('allowed.example.com', contains('/path')));
    });

    test('returns empty RuleSet for empty content', () {
      final rules = parser.parse('');
      expect(rules.domainFilters, isEmpty);
      expect(rules.exceptionDomains, isEmpty);
      expect(rules.blockedPaths, isEmpty);
      expect(rules.exceptionPaths, isEmpty);
    });

    test('hardBlockedDomains and fontExtensions are empty in parsed rules',
        () {
      final rules = parser.parse('||blocked.com^\n');
      expect(rules.hardBlockedDomains, isEmpty);
      expect(rules.fontExtensions, isEmpty);
    });
  });
}
