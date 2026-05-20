import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/adblock/adblock_engine.dart';

void main() {
  group('AdblockEngine', () {
    test('shouldBlock returns false for main frame content', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://www.reddit.com'), false);
    });

    test('shouldBlock blocks font extensions', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://fonts.gstatic.com/s/roboto/v18/KFOmCnqEu92Fr1Mu4mxP.ttf'), true);
      expect(engine.shouldBlock('https://example.com/font.woff2'), true);
      expect(engine.shouldBlock('https://example.com/font.woff'), true);
    });

    test('shouldBlock blocks hardcoded tracking domains', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://pixel.redditmedia.com/track'), true);
      expect(engine.shouldBlock('https://out.reddit.com/t'), true);
    });

    test('shouldBlock allows normal sub-resources', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://www.redditstatic.com/icon.png'), false);
      expect(engine.shouldBlock('https://i.redd.it/abc123.jpg'), false);
    });

    test('domain matching checks parent domains', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://fonts.googleapis.com/css2'), true);
      expect(engine.shouldBlock('https://sub.fonts.googleapis.com/foo'), true);
    });
  });
}
