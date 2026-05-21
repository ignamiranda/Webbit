import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

abstract class UsernameResolver {
  Future<String?> resolve();
}

class DomUsernameResolver implements UsernameResolver {
  final InAppWebViewController controller;

  DomUsernameResolver(this.controller);

  @override
  Future<String?> resolve() async {
    try {
      final js = await controller.evaluateJavascript(source: '''
(function() {
  var el = document.querySelector('shreddit-app');
  if (el && el.getAttribute('username')) return el.getAttribute('username');
  var meta = document.querySelector('meta[name="twitter:data1"]');
  if (meta && meta.getAttribute('value')) return meta.getAttribute('value');
  var links = document.querySelectorAll('a[href*="/user/"]');
  for (var i = 0; i < links.length; i++) {
    var m = links[i].href.match(/\\/user\\/([^\\/?#]+)/);
    if (m && m[1] && !m[1].startsWith('t2_') && m[1].length < 25) {
      if (links[i].closest('header, [class*="Header"], [class*="navbar"], [class*="top"]'))
        return m[1];
    }
  }
  return '';
})()
''');
      if (js is String && js.isNotEmpty) return js;
    } catch (_) {}
    return null;
  }
}

class ApiUsernameResolver implements UsernameResolver {
  final List<Cookie> cookies;
  final http.Client _client;

  ApiUsernameResolver({required this.cookies, http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<String?> resolve() async {
    try {
      final cookieStr = cookies
          .map((c) => '${c.name}=${c.value?.toString() ?? ''}')
          .join('; ');
      final resp = await _client.get(
        Uri.parse('https://www.reddit.com/api/me.json'),
        headers: {'Cookie': cookieStr},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map?;
        final data = body?['data'] as Map?;
        final name = data?['name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _client.close();
  }
}

class CompositeUsernameResolver implements UsernameResolver {
  final List<UsernameResolver> resolvers;

  CompositeUsernameResolver(this.resolvers);

  @override
  Future<String?> resolve() async {
    for (final resolver in resolvers) {
      try {
        final result = await resolver.resolve();
        if (result != null) return result;
      } catch (_) {}
    }
    return null;
  }
}
