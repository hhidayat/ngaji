import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Mengambil dokumen JSON lewat HTTP dan menyimpannya di memori serta di disk,
/// sehingga data yang pernah dimuat tetap tersedia tanpa internet.
class JsonCache {
  final String folder;
  final http.Client _client;
  final Map<String, Map<String, dynamic>> _memory = {};

  JsonCache(this.folder, {http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String url, String cacheName) async {
    final cached = _memory[cacheName];
    if (cached != null) return cached;

    final file = await _cacheFile(cacheName);
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _memory[cacheName] = json;
    }

    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw HttpException('Gagal memuat data (${response.statusCode})');
    }
    final body = utf8.decode(response.bodyBytes);
    final json = jsonDecode(body) as Map<String, dynamic>;
    await file.writeAsString(body);
    return _memory[cacheName] = json;
  }

  Future<File> _cacheFile(String name) async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/$folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$name');
  }
}
