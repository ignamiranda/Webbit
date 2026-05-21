import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class CookieStore {
  Future<void> deleteAllCookies();
  Future<void> setCookie({
    required WebUri url,
    required String name,
    required String value,
    String path = '/',
    String? domain,
    bool? isSecure,
    bool? isHttpOnly,
    int? expiresDate,
  });
  Future<List<Cookie>> getCookies(WebUri url);
}

class WebViewCookieStore implements CookieStore {
  final CookieManager _cm;

  WebViewCookieStore() : _cm = CookieManager.instance();

  @override
  Future<void> deleteAllCookies() => _cm.deleteAllCookies();

  @override
  Future<void> setCookie({
    required WebUri url,
    required String name,
    required String value,
    String path = '/',
    String? domain,
    bool? isSecure,
    bool? isHttpOnly,
    int? expiresDate,
  }) =>
      _cm.setCookie(
        url: url,
        name: name,
        value: value,
        path: path,
        domain: domain,
        isSecure: isSecure,
        isHttpOnly: isHttpOnly,
        expiresDate: expiresDate,
      );

  @override
  Future<List<Cookie>> getCookies(WebUri url) => _cm.getCookies(url: url);
}

class FakeCookieStore implements CookieStore {
  final List<Cookie> _cookies = [];

  @override
  Future<void> deleteAllCookies() async {
    _cookies.clear();
  }

  @override
  Future<void> setCookie({
    required WebUri url,
    required String name,
    required String value,
    String path = '/',
    String? domain,
    bool? isSecure,
    bool? isHttpOnly,
    int? expiresDate,
  }) async {
    _cookies.removeWhere((c) => c.name == name && c.domain == domain);
    _cookies.add(Cookie(
      name: name,
      value: value,
      domain: domain,
      path: path,
      isSecure: isSecure ?? false,
      isHttpOnly: isHttpOnly ?? false,
    ));
  }

  @override
  Future<List<Cookie>> getCookies(WebUri url) async {
    final host = url.host;
    return _cookies.where((c) {
      final d = c.domain ?? host;
      return d == host ||
          d == '.$host' ||
          host.endsWith('.${d.startsWith('.') ? d.substring(1) : d}');
    }).toList();
  }
}
