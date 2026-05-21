import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/services/cookie_session_manager.dart';
import 'package:webbit/services/cookie_store.dart';

void main() {
  group('CookieSessionManager', () {
    late FakeCookieStore store;
    late CookieSessionManager sessionManager;

    setUp(() {
      store = FakeCookieStore();
      sessionManager = CookieSessionManager(store: store);
    });

    group('switchToSession', () {
      test('deletes all cookies then sets account cookies', () async {
        await store.setCookie(
          url: WebUri('https://old.example.com'),
          name: 'old',
          value: 'stuff',
        );

        await sessionManager.switchToSession([
          Cookie(name: 'reddit_session', value: 'abc123', domain: 'www.reddit.com'),
          Cookie(name: 'token', value: 'xyz', domain: '.reddit.com'),
        ]);

        final oldCookies = await store.getCookies(WebUri('https://old.example.com'));
        expect(oldCookies, isEmpty);

        final sessionCookies = await store.getCookies(WebUri('https://www.reddit.com'));
        expect(sessionCookies.any((c) => c.name == 'reddit_session'), true);
      });

      test('handles cookie with leading dot in domain', () async {
        await sessionManager.switchToSession([
          Cookie(name: 'session', value: 'val', domain: '.reddit.com'),
        ]);

        final www = await store.getCookies(WebUri('https://www.reddit.com'));
        expect(www.any((c) => c.name == 'session'), true);
      });
    });

    group('captureSession', () {
      test('returns empty list when no cookies', () async {
        final cookies = await sessionManager.captureSession();
        expect(cookies, isEmpty);
      });

      test('captures cookies from www.reddit.com and reddit.com', () async {
        await store.setCookie(
          url: WebUri('https://www.reddit.com'),
          name: 'session',
          value: 'val',
          domain: 'www.reddit.com',
        );
        await store.setCookie(
          url: WebUri('https://reddit.com'),
          name: 'token',
          value: 'tok',
          domain: 'reddit.com',
        );

        final cookies = await sessionManager.captureSession();
        expect(cookies.length, 2);
        expect(cookies.any((c) => c.name == 'session'), true);
        expect(cookies.any((c) => c.name == 'token'), true);
      });

      test('deduplicates cookies with same name and domain', () async {
        await store.setCookie(
          url: WebUri('https://www.reddit.com'),
          name: 'session',
          value: 'val1',
          domain: 'www.reddit.com',
        );
        await store.setCookie(
          url: WebUri('https://www.reddit.com'),
          name: 'session',
          value: 'val2',
          domain: 'www.reddit.com',
        );

        final cookies = await sessionManager.captureSession();
        expect(cookies.length, 1);
        expect(cookies.first.value, 'val2');
      });
    });

    group('hasSession', () {
      test('returns false when no reddit_session cookie', () async {
        expect(await sessionManager.hasSession(), false);
      });

      test('returns true when reddit_session cookie exists', () async {
        await store.setCookie(
          url: WebUri('https://www.reddit.com'),
          name: 'reddit_session',
          value: 'abc123',
          domain: 'www.reddit.com',
        );
        expect(await sessionManager.hasSession(), true);
      });
    });
  });
}
