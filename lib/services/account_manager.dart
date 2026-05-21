import 'dart:convert';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reddit_account.dart';

class AccountManager {
  static int _idCounter = 0;
  List<RedditAccount> _accounts = [];
  String? _lastActiveId;
  String? _storagePath;
  bool _loaded = false;

  AccountManager({String? storagePath}) : _storagePath = storagePath;

  bool get isLoaded => _loaded;
  List<RedditAccount> get accounts => List.unmodifiable(_accounts);
  String? get lastActiveId => _lastActiveId;

  Future<void> initialize() async {
    _storagePath ??= '${(await getApplicationDocumentsDirectory()).path}/webbit/accounts.json';
    await _load();
    _loaded = true;
  }

  Future<String?> lastActiveAccountId() async {
    if (!_loaded) await initialize();
    if (_lastActiveId != null &&
        _accounts.any((a) => a.id == _lastActiveId)) {
      return _lastActiveId;
    }
    return null;
  }

  RedditAccount? findById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addAccount(
    String displayName,
    List<Cookie> cookies, {
    String? username,
  }) async {
    final now = DateTime.now();
    final account = RedditAccount(
      id: '${now.microsecondsSinceEpoch}_${_idCounter++}',
      displayName: displayName,
      username: username,
      createdAt: now,
      lastUsedAt: now,
      cookies: cookies,
    );
    _accounts.add(account);
    _lastActiveId = account.id;
    await _save();
  }

  Future<void> removeAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    if (_lastActiveId == id) {
      _lastActiveId = _accounts.isNotEmpty ? _accounts.last.id : null;
    }
    await _save();
  }

  Future<void> switchToAccount(String id) async {
    final account = _accounts.firstWhere((a) => a.id == id);
    await CookieManager.instance().deleteAllCookies();
    for (final cookie in account.cookies) {
      final domain = cookie.domain ?? 'www.reddit.com';
      final url = domain.startsWith('.')
          ? WebUri('https://${domain.substring(1)}')
          : WebUri('https://$domain');
      await CookieManager.instance().setCookie(
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
    account.lastUsedAt = DateTime.now();
    _lastActiveId = id;
    await _save();
  }

  Future<List<Cookie>> captureCookies() async {
    final cookies = <Cookie>[];
    for (final url in ['https://www.reddit.com', 'https://reddit.com']) {
      final fetched =
          await CookieManager.instance().getCookies(url: WebUri(url));
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

  Future<bool> isLoggedIn() async {
    final cookies =
        await CookieManager.instance().getCookies(url: WebUri('https://www.reddit.com'));
    return cookies.any((c) => c.name == 'reddit_session');
  }

  Future<void> _load() async {
    final path = _storagePath;
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _lastActiveId = json['lastActiveId'] as String?;
      final list = json['accounts'] as List;
      _accounts = list
          .map((e) => RedditAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _accounts = [];
      _lastActiveId = null;
    }
  }

  Future<void> _save() async {
    final path = _storagePath;
    if (path == null) return;
    final dir = Directory(path).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final json = jsonEncode({
      'lastActiveId': _lastActiveId,
      'accounts': _accounts.map((a) => a.toJson()).toList(),
    });
    await File(path).writeAsString(json);
  }
}
