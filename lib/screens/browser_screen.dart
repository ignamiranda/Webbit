import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import '../adblock/adblock_engine.dart';
import '../services/account_manager.dart';
import 'account_sheet.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final AdblockEngine _adblock = AdblockEngine();
  final AccountManager _accountManager = AccountManager();
  final String _userAgent;
  InAppWebViewController? _webViewController;
  String? _activeAccountId;
  bool _awaitingLogin = false;

  _BrowserScreenState()
      : _userAgent = 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';

  static const _preconnectJS = '''
(function() {
  var links = [
    {rel:"preconnect", href:"https://www.redditstatic.com"},
    {rel:"preconnect", href:"https://www.redditmedia.com"},
    {rel:"preconnect", href:"https://preview.redd.it"},
    {rel:"preconnect", href:"https://i.redd.it"},
    {rel:"dns-prefetch", href:"https://www.redditstatic.com"},
    {rel:"dns-prefetch", href:"https://www.redditmedia.com"},
    {rel:"dns-prefetch", href:"https://preview.redd.it"},
    {rel:"dns-prefetch", href:"https://i.redd.it"},
  ];
  var head = document.head || document.querySelector("head");
  if (head) {
    links.forEach(function(l) {
      try {
        if (!head.querySelector('link[rel="'+l.rel+'"][href="'+l.href+'"]')) {
          var el = document.createElement("link");
          el.rel = l.rel;
          el.href = l.href;
          head.appendChild(el);
        }
      } catch(e) {}
    });
  }
})();
''';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));
    _initAdblock();
    _initAccountManager();
  }

  Future<void> _initAdblock() async {
    await _adblock.initializeFromCache();
    _adblock.updateFilterLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(top: true, bottom: false, child: _buildWebView()),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('https://www.reddit.com'),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'none',
          'Sec-Fetch-User': '?1',
          'Upgrade-Insecure-Requests': '1',
        },
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useWideViewPort: false,
        supportZoom: true,
        userAgent: _userAgent,
        cacheEnabled: true,
        cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      ),
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source: _adblock.initialCSSInjectionJS,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      onWebViewCreated: (controller) {
        _webViewController = controller;
        controller.addJavaScriptHandler(
          handlerName: 'WebbitSwitchAccount',
          callback: (_) => _showAccountSheet(),
        );
      },
      shouldInterceptRequest: (controller, request) async {
        final url = request.url.toString();
        if (request.isForMainFrame != true && _adblock.shouldBlock(url)) {
          return WebResourceResponse(
            data: Uint8List(0),
            statusCode: 204,
            reasonPhrase: 'Blocked by Webbit',
            contentType: 'text/plain',
          );
        }
        return null;
      },
      onLoadStart: (controller, url) async {
        await controller.evaluateJavascript(source: _preconnectJS);
      },
      onLoadStop: (controller, url) async {
        try {
          await controller.evaluateJavascript(source: _injectMenuJS);
        } catch (_) {}
        await _handlePageLoad(url);
      },
    );
  }



  static const _injectMenuJS = '''
(function() {
  var ID = "webbit-swn";
  if (document.getElementById(ID)) return;

  function inject() {
    var links = document.querySelectorAll("a[href*='settings'],a[href*='/user/'],a[href*='logout'],a[href*='draft']");
    for (var i = 0; i < links.length; i++) {
      var t = (links[i].textContent||"").replace(/\\s+/g," ").trim().toLowerCase();
      if (!t.includes("edit avatar") && !t.includes("log out") && !t.includes("view profile")) continue;
      var p = links[i].parentNode;
      if (!p) continue;
      var first = p.querySelector("a");
      if (!first || first.querySelector("#"+ID)) continue;
      first.style.display = "flex";
      first.style.justifyContent = "space-between";
      first.style.alignItems = "center";
      var s = document.createElement("span");
      s.id = ID;
      s.textContent = "Switch Account";
      s.style.cssText = "cursor:pointer;white-space:nowrap;margin-left:auto;padding-left:16px;font-size:14px";
      s.addEventListener("click", function(e) {
        e.preventDefault(); e.stopPropagation();
        try { window.flutter_inappwebview.callHandler("WebbitSwitchAccount"); } catch(e) {}
      });
      first.appendChild(s);
      return true;
    }
    return false;
  }

  if (!inject()) {
    new MutationObserver(function() { inject(); })
      .observe(document.body, {childList:true, subtree:true});
  }
})();
''';

  Future<void> _initAccountManager() async {
    await _accountManager.initialize();
    final activeId = await _accountManager.lastActiveAccountId();
    if (mounted && activeId != null) {
      setState(() => _activeAccountId = activeId);
    }
  }

  Future<void> _handlePageLoad(WebUri? url) async {
    if (url == null) return;
    if (_awaitingLogin) {
      final loggedIn =
          await CookieManager.instance().getCookie(
        url: WebUri('https://www.reddit.com'),
        name: 'reddit_session',
      );
      if (loggedIn != null) {
        _awaitingLogin = false;
        await _handleLoginSuccess();
      }
    }
  }

  Future<void> _handleLoginSuccess() async {
    final cookies = await _accountManager.captureCookies();
    if (cookies.isEmpty) return;
    String? username;
    try {
      final js = await _webViewController?.evaluateJavascript(
        source: '''(function() {
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
        })()''',
      );
      if (js is String && js.isNotEmpty) username = js;
    } catch (_) {}
    if (username == null) {
      try {
        final cookieStr = cookies
            .map((c) => '${c.name}=${c.value?.toString() ?? ''}')
            .join('; ');
        final resp = await http.get(
          Uri.parse('https://www.reddit.com/api/me.json'),
          headers: {'Cookie': cookieStr},
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map?;
          final data = body?['data'] as Map?;
          final name = data?['name'] as String?;
          if (name != null && name.isNotEmpty) username = name;
        }
      } catch (_) {}
    }
    final displayName = username ?? 'Account ${_accountManager.accounts.length + 1}';
    await _accountManager.addAccount(displayName, cookies, username: username);
    if (mounted) {
      setState(() => _activeAccountId = _accountManager.lastActiveId);
    }
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://www.reddit.com')),
    );
  }

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => AccountSheet(
        accounts: _accountManager.accounts,
        activeAccountId: _activeAccountId,
        onSwitchTo: (id) {
          Navigator.pop(ctx);
          _switchToAccount(id);
        },
        onAdd: () {
          Navigator.pop(ctx);
          _startAddAccount();
        },
        onDelete: (id) async {
          Navigator.pop(ctx);
          final wasActive = id == _activeAccountId;
          await _accountManager.removeAccount(id);
          if (wasActive) {
            await CookieManager.instance()
                .deleteCookies(url: WebUri('https://www.reddit.com'));
            await CookieManager.instance()
                .deleteCookies(url: WebUri('https://reddit.com'));
            _webViewController?.reload();
          }
          if (mounted) {
            setState(() {
              _activeAccountId = _accountManager.accounts.isNotEmpty
                  ? _accountManager.accounts.last.id
                  : null;
            });
          }
        },
      ),
    );
  }

  void _startAddAccount() {
    _awaitingLogin = true;
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://www.reddit.com/login')),
    );
  }

  void _switchToAccount(String id) async {
    await _accountManager.switchToAccount(id);
    if (mounted) {
      setState(() => _activeAccountId = id);
    }
    _webViewController?.reload();
  }
}
