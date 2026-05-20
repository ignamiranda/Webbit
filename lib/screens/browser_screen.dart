import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../adblock/adblock_engine.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final AdblockEngine _adblock = AdblockEngine();
  final String _userAgent;

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
    );
  }
}
