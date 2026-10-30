import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ngaji/data/kajian_content.dart';
import 'package:ngaji/data/study_repository.dart';

String _json({int version = 2, int schema = 1, List<Map<String, dynamic>>? hadiths, Map<String, dynamic>? tags}) =>
    jsonEncode({
      'schema': schema,
      'version': version,
      'tags': tags ?? {'2:255': ['Tauhid']},
      'histories': [
        {'surah': 2, 'from': 255, 'to': 255, 'title': 'Ayat Kursi', 'content': 'Isi.'},
      ],
      'hadiths': hadiths ??
          [
            {'id': 'a', 'surah': 2, 'ayat': 255, 'translation': 'Teks.', 'source': 'HR. Muslim no. 810'},
          ],
    });

void main() {
  // Pemeriksaan yang sama dijalankan GitHub Actions setiap kali kajian.json diubah.
  test('assets/data/kajian.json lolos validasi aplikasi', () {
    final content = KajianContent.parse(File('assets/data/kajian.json').readAsStringSync());
    expect(content.version, greaterThanOrEqualTo(1));
    expect(content.hadiths, isNotEmpty);
  });

  group('validasi', () {
    test('menerima file yang benar', () {
      final c = KajianContent.tryParse(_json())!;
      expect(c.version, 2);
      expect(c.tags['2:255'], ['Tauhid']);
    });

    test('menolak JSON rusak, schema baru, dan isian yang salah', () {
      expect(KajianContent.tryParse('{"version": 2,'), isNull);
      expect(KajianContent.tryParse(_json(schema: KajianContent.supportedSchema + 1)), isNull);
      expect(KajianContent.tryParse(_json(tags: {'2-255': ['Tauhid']})), isNull);
      expect(KajianContent.tryParse(_json(hadiths: [{'id': 'a', 'surah': 2}])), isNull);
    });

    test('pesan kesalahan menyebut penyebabnya', () {
      final dup = {'id': 'x', 'surah': 1, 'ayat': 1, 'translation': 't', 'source': 's'};
      expect(
        () => KajianContent.parse(_json(hadiths: [dup, dup])),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('"x"'))),
      );
    });
  });

  group('pembaruan dari GitHub', () {
    StudyRepository repo(http.Client client) =>
        StudyRepository(client: client)..useContent(KajianContent.parse(_json(version: 2)));

    test('konten valid langsung dipakai', () async {
      final r = repo(MockClient((_) async => http.Response(_json(version: 3, tags: {'1:1': ['Basmalah']}), 200)));
      expect(await r.refreshContent(), isTrue);
      expect(r.contentVersion, 3);
      expect(r.tagsFor(1, 1), ['Basmalah']);
    });

    test('versi sama tetap diterima (penyunting lupa menaikkan version)', () async {
      final r = repo(MockClient((_) async => http.Response(_json(version: 2, tags: {'1:1': ['Baru']}), 200)));
      expect(await r.refreshContent(), isTrue);
      expect(r.tagsFor(1, 1), ['Baru']);
    });

    test('file rusak, versi lebih lama, error server, dan offline diabaikan', () async {
      for (final client in [
        MockClient((_) async => http.Response('{rusak', 200)),
        MockClient((_) async => http.Response(_json(version: 1), 200)),
        MockClient((_) async => http.Response('Not Found', 404)),
        MockClient((_) async => throw const SocketException('offline')),
      ]) {
        final r = repo(client);
        expect(await r.refreshContent(), isFalse);
        expect(r.contentVersion, 2);
        expect(r.tagsFor(2, 255), ['Tauhid']);
      }
    });
  });
}
