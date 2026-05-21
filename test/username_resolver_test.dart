import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:webbit/services/username_resolver.dart';

class FakeHttpClient extends http.BaseClient {
  final Map<String, http.Response> responses;

  FakeHttpClient(this.responses);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    final response = responses[url];
    if (response != null) {
      return http.StreamedResponse(
        http.ByteStream.fromBytes(response.bodyBytes),
        response.statusCode,
        headers: response.headers,
      );
    }
    return http.StreamedResponse(
      http.ByteStream.fromBytes(utf8.encode('{"error": "not found"}')),
      404,
    );
  }
}

class _CapturingHttpClient extends http.BaseClient {
  final void Function(http.BaseRequest) onSend;

  _CapturingHttpClient(this.onSend);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    onSend(request);
    return http.StreamedResponse(
      http.ByteStream.fromBytes(
          utf8.encode(jsonEncode({'data': {'name': 'u'}}))),
      200,
    );
  }
}

class FakeUsernameResolver implements UsernameResolver {
  final String? result;
  final bool shouldThrow;

  FakeUsernameResolver({this.result, this.shouldThrow = false});

  @override
  Future<String?> resolve() async {
    if (shouldThrow) throw Exception('fake error');
    return result;
  }
}

void main() {
  group('ApiUsernameResolver', () {
    test('returns username from successful API response', () async {
      final client = FakeHttpClient({
        'https://www.reddit.com/api/me.json': http.Response(
          jsonEncode({'data': {'name': 'testuser'}}),
          200,
        ),
      });

      final resolver = ApiUsernameResolver(cookies: [], client: client);
      final result = await resolver.resolve();
      expect(result, 'testuser');
    });

    test('returns null on non-200 response', () async {
      final client = FakeHttpClient({
        'https://www.reddit.com/api/me.json': http.Response(
          jsonEncode({'error': 'unauthorized'}),
          401,
        ),
      });

      final resolver = ApiUsernameResolver(cookies: [], client: client);
      final result = await resolver.resolve();
      expect(result, isNull);
    });

    test('returns null on network error', () async {
      final client = FakeHttpClient({});

      final resolver = ApiUsernameResolver(cookies: [], client: client);
      final result = await resolver.resolve();
      expect(result, isNull);
    });

    test('includes cookies in request headers', () async {
      http.BaseRequest? capturedRequest;
      final capturingClient = _CapturingHttpClient((r) => capturedRequest = r);

      final resolver = ApiUsernameResolver(
        cookies: [
          Cookie(name: 'reddit_session', value: 'abc123', domain: 'reddit.com'),
        ],
        client: capturingClient,
      );
      await resolver.resolve();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.headers['Cookie'],
          contains('reddit_session=abc123'));
    });
  });

  group('CompositeUsernameResolver', () {
    test('returns result from first resolver that succeeds', () async {
      final resolver = CompositeUsernameResolver([
        FakeUsernameResolver(result: null),
        FakeUsernameResolver(result: 'found'),
        FakeUsernameResolver(result: 'ignored'),
      ]);

      final result = await resolver.resolve();
      expect(result, 'found');
    });

    test('returns null when all resolvers return null', () async {
      final resolver = CompositeUsernameResolver([
        FakeUsernameResolver(result: null),
        FakeUsernameResolver(result: null),
      ]);

      final result = await resolver.resolve();
      expect(result, isNull);
    });

    test('skips resolvers that throw', () async {
      final resolver = CompositeUsernameResolver([
        FakeUsernameResolver(shouldThrow: true),
        FakeUsernameResolver(result: 'works'),
      ]);

      final result = await resolver.resolve();
      expect(result, 'works');
    });

    test('returns null with empty resolver list', () async {
      final resolver = CompositeUsernameResolver([]);
      final result = await resolver.resolve();
      expect(result, isNull);
    });
  });
}
