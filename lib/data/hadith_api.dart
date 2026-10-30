import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/hadith_library.dart';
import 'json_cache.dart';

/// Perpustakaan kitab hadist dari proyek terbuka fawazahmed0/hadith-api
/// (dilayani lewat CDN jsDelivr). Teks Indonesia dan Arab diambil per bab
/// lalu digabung berdasarkan nomor hadist.
class HadithApi {
  static const _base = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  final JsonCache _cache;
  List<HadithBook>? _books;

  HadithApi({JsonCache? cache}) : _cache = cache ?? JsonCache('hadith_cache');

  /// Daftar kitab dan bab (berbahasa Indonesia) dibundel di aplikasi.
  Future<List<HadithBook>> books() async => _books ??= ((jsonDecode(
              await rootBundle.loadString('assets/data/hadith_books.json'))
          as Map<String, dynamic>)['books'] as List<dynamic>)
      .map((e) => HadithBook.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<LibraryHadith>> chapter(HadithBook book, HadithChapter chapter) => _load(
        book,
        'sections/${chapter.number}.json',
        '${book.slug}_bab_${chapter.number}',
      );

  Future<LibraryHadith?> hadith(HadithBook book, int number) async =>
      (await _load(book, '$number.json', '${book.slug}_no_$number')).firstOrNull;

  Future<List<LibraryHadith>> _load(HadithBook book, String path, String cacheName) async {
    final (indo, arab) = await (
      _cache.get('$_base/ind-${book.slug}/$path', 'ind_$cacheName.json'),
      _cache.get('$_base/ara-${book.slug}/$path', 'ara_$cacheName.json'),
    ).wait;

    final arabicByNumber = {
      for (final h in arab['hadiths'] as List<dynamic>)
        (h as Map<String, dynamic>)['hadithnumber'] as num: h,
    };
    final section = (indo['metadata'] as Map<String, dynamic>?)?['section'] as Map<String, dynamic>?;
    final chapter = int.tryParse(section?.keys.firstOrNull ?? '');
    final result = <LibraryHadith>[];
    for (final h in indo['hadiths'] as List<dynamic>) {
      h as Map<String, dynamic>;
      final number = h['hadithnumber'] as num;
      final ar = arabicByNumber[number];
      final arabic = (ar?['text'] as String? ?? '').trim();
      final indonesian = (h['text'] as String? ?? '').trim();
      if (arabic.isEmpty && indonesian.isEmpty) continue;
      result.add(LibraryHadith(
        book: book,
        chapter: chapter,
        number: number.toInt(),
        referenceNumber: _referenceNumber(h['arabicnumber'] ?? ar?['arabicnumber'], number),
        arabic: arabic,
        indonesian: indonesian,
        grades: [
          for (final g in (h['grades'] ?? ar?['grades'] ?? []) as List<dynamic>)
            HadithGradeNote((g as Map<String, dynamic>)['name'] as String, g['grade'] as String),
        ],
      ));
    }
    return result;
  }

  /// "156.01" (riwayat kedua dari hadist 156) dirujuk sebagai nomor 156.
  static String _referenceNumber(dynamic arabicNumber, num number) {
    final parsed = num.tryParse('${arabicNumber ?? ''}');
    return '${(parsed ?? number).floor()}';
  }
}
