import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/adblock/rule_set.dart';
import 'package:webbit/adblock/url_matcher.dart';

void main() {
  group('UrlMatcher', () {
    test('blocks by hardcoded domain', () {
      final matcher = UrlMatcher(const RuleSet());
      expect(matcher.shouldBlock('https://pixel.redditmedia.com/track'), true);
      expect(matcher.shouldBlock('https://out.reddit.com/t'), true);
    });

    test('blocks font extensions', () {
      final matcher = UrlMatcher(const RuleSet());
      expect(
          matcher.shouldBlock(
              'https://fonts.gstatic.com/s/roboto/KFOmCnqEu92Fr1Mu4mxP.ttf'),
          true);
      expect(matcher.shouldBlock('https://example.com/font.woff2'), true);
      expect(matcher.shouldBlock('https://example.com/font.woff'), true);
      expect(matcher.shouldBlock('https://example.com/font.eot'), true);
      expect(matcher.shouldBlock('https://example.com/font.otf'), true);
    });

    test('allows normal sub-resources', () {
      final matcher = UrlMatcher(const RuleSet());
      expect(
          matcher.shouldBlock('https://www.redditstatic.com/icon.png'), false);
      expect(matcher.shouldBlock('https://i.redd.it/abc123.jpg'), false);
      expect(matcher.shouldBlock('https://www.reddit.com'), false);
    });

    test('matches hardcoded domain on subdomain', () {
      final matcher = UrlMatcher(const RuleSet());
      expect(
          matcher.shouldBlock('https://sub.fonts.googleapis.com/css2'), true);
    });

    test('blocks by parsed domain filter', () {
      final matcher = UrlMatcher(const RuleSet(
        domainFilters: {'ads.example.com'},
        hardBlockedDomains: {},
        fontExtensions: {},
      ));
      expect(matcher.shouldBlock('https://ads.example.com/banner.png'), true);
    });

    test('blocks by parsed domain filter with subdomain match', () {
      final matcher = UrlMatcher(const RuleSet(
        domainFilters: {'example.com'},
        hardBlockedDomains: {},
        fontExtensions: {},
      ));
      expect(matcher.shouldBlock('https://ads.example.com/banner.png'), true);
      expect(matcher.shouldBlock('https://sub.ads.example.com/foo'), true);
    });

    test('blocks by path prefix', () {
      final matcher = UrlMatcher(const RuleSet(
        blockedPaths: {'ads.example.com': {'/track'}},
        hardBlockedDomains: {},
        fontExtensions: {},
      ));
      expect(matcher.shouldBlock('https://ads.example.com/track/pixel.gif'),
          true);
      expect(
          matcher.shouldBlock('https://ads.example.com/other'), false);
    });

    test('exception overrides domain block', () {
      final matcher = UrlMatcher(const RuleSet(
        domainFilters: {'ads.example.com'},
        exceptionDomains: {'ads.example.com'},
        hardBlockedDomains: {},
        fontExtensions: {},
      ));
      expect(matcher.shouldBlock('https://ads.example.com/banner.png'), false);
    });

    test('exception overrides path block', () {
      final matcher = UrlMatcher(const RuleSet(
        blockedPaths: {'tracker.example.com': {'/pixel'}},
        exceptionPaths: {'tracker.example.com': {'/pixel/allow'}},
        hardBlockedDomains: {},
        fontExtensions: {},
      ));
      expect(matcher.shouldBlock('https://tracker.example.com/pixel/allow'),
          false);
    });

    test('main frame requests pass through (no special handling needed)', () {
      final matcher = UrlMatcher(const RuleSet(
        hardBlockedDomains: {},
        fontExtensions: {},
      ));
      expect(matcher.shouldBlock('https://www.reddit.com'), false);
      expect(matcher.shouldBlock('https://www.reddit.com/r/flutter'), false);
    });

    test('handles malformed URLs gracefully', () {
      final matcher = UrlMatcher(const RuleSet());
      expect(matcher.shouldBlock(''), false);
      expect(matcher.shouldBlock('not-a-url'), false);
    });
  });
}
