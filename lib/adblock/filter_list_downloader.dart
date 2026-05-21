import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FilterListDownloader {
  static const filterListUrls = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
    'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt',
    'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt',
  ];

  static String _listName(String url) {
    final parts = url.split('/');
    final last = parts.last;
    return last.endsWith('.txt') ? last.substring(0, last.length - 4) : last;
  }

  Future<Directory> _cacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/webbit/filters');
  }

  Future<Map<String, String>> loadFromCache() async {
    final cacheDir = await _cacheDir();
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return _readFromDir(cacheDir);
  }

  Future<Map<String, String>> _readFromDir(Directory dir) async {
    final result = <String, String>{};
    for (final url in filterListUrls) {
      final file = File('${dir.path}/${_listName(url)}.txt');
      if (await file.exists()) {
        result[url] = await file.readAsString();
      }
    }
    return result;
  }

  Future<Map<String, String>> download({http.Client? client}) async {
    final cacheDir = await _cacheDir();
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final c = client ?? http.Client();
    final result = <String, String>{};
    for (final url in filterListUrls) {
      try {
        final response = await c.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode == 200) {
          final file = File('${cacheDir.path}/${_listName(url)}.txt');
          await file.writeAsString(response.body);
          result[url] = response.body;
        }
      } catch (_) {}
    }
    return result;
  }
}
