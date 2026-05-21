import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'cookie_store.dart';

class CookieSessionManager {
  final CookieStore _store;

  CookieSessionManager({CookieStore? store}) : _store = store ?? WebViewCookieStore();

  Future<void> switchToSession(List<Cookie> cookies) async {
    await _store.deleteAllCookies();
    for (final cookie in cookies) {
      final domain = cookie.domain ?? 'www.reddit.com';
      final url = domain.startsWith('.')
          ? WebUri('https://${domain.substring(1)}')
          : WebUri('https://$domain');
      await _store.setCookie(
        url: url,
        name: cookie.name,
        value: cookie.value?.toString() ?? '',
        domain: cookie.domain,
        path: cookie.path ?? '/',
        isSecure: cookie.isSecure,
        isHttpOnly: cookie.isHttpOnly,
        expiresDate: cookie.expiresDate,
      );
    }
  }

  Future<List<Cookie>> captureSession() async {
    final cookies = <Cookie>[];
    for (final url in ['https://www.reddit.com', 'https://reddit.com']) {
      final fetched = await _store.getCookies(WebUri(url));
      for (final cookie in fetched) {
        final isDuplicate = cookies.any(
          (c) => c.name == cookie.name && c.domain == cookie.domain,
        );
        if (!isDuplicate) {
          cookies.add(cookie);
        }
      }
    }
    return cookies;
  }

  Future<bool> hasSession() async {
    final cookies = await _store.getCookies(WebUri('https://www.reddit.com'));
    return cookies.any((c) => c.name == 'reddit_session');
  }
}
