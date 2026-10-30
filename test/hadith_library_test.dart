import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ngaji/models/hadith_library.dart';
import 'package:ngaji/models/study.dart';
import 'package:ngaji/widgets/common.dart';

void main() {
  final books = ((jsonDecode(File('assets/data/hadith_books.json').readAsStringSync())
          as Map<String, dynamic>)['books'] as List<dynamic>)
      .map((e) => HadithBook.fromJson(e as Map<String, dynamic>))
      .toList();

  test('indeks kitab: setiap bab bernama, berisi hadist, dan bernomor unik', () {
    expect(books.map((b) => b.slug), containsAll(['bukhari', 'muslim', 'tirmidhi']));
    for (final book in books) {
      expect(book.chapters, isNotEmpty, reason: book.slug);
      expect(book.chapters.map((c) => c.number).toSet().length, book.chapters.length, reason: book.slug);
      for (final c in book.chapters) {
        expect(c.name.trim(), isNotEmpty, reason: '${book.slug} bab ${c.number}');
        expect(c.count, greaterThan(0), reason: '${book.slug} bab ${c.number}');
        expect(c.first, lessThanOrEqualTo(c.last), reason: '${book.slug} bab ${c.number}');
      }
    }
  });

  test('jumlah hadist per kitab dan format ribuan', () {
    expect(books.firstWhere((b) => b.slug == 'muslim').hadithCount, 7563);
    expect(formatThousands(7563), '7.563');
    expect(formatThousands(999), '999');
    expect(formatThousands(1234567), '1.234.567');
  });

  test('bab dapat dicari dari nomornya', () {
    final bukhari = books.firstWhere((b) => b.slug == 'bukhari');
    expect(bukhari.chapterByNumber(1)?.name, 'Permulaan Wahyu');
    expect(bukhari.chapterByNumber(10)?.name, 'Adzan');
    expect(books.firstWhere((b) => b.slug == 'muslim').chapterByNumber(0)?.name, contains('Muqaddimah'));
  });

  LibraryHadith sample(String slug, List<HadithGradeNote> grades) => LibraryHadith(
        book: books.firstWhere((b) => b.slug == slug),
        number: 1,
        referenceNumber: '1',
        arabic: '',
        indonesian: '',
        grades: grades,
      );

  test('derajat: Shahihain shahih, kitab lain mengikuti Al-Albani', () {
    expect(sample('muslim', []).grade, HadithGrade.shahih);
    expect(
      sample('tirmidhi', const [
        HadithGradeNote('Zubair Ali Zai', 'Daif'),
        HadithGradeNote('Al-Albani', 'Hasan'),
      ]).grade,
      HadithGrade.hasan,
    );
    expect(sample('abudawud', const [HadithGradeNote('Al-Albani', "Da'if")]).grade, HadithGrade.dhaif);
    expect(sample('nasai', []).grade, HadithGrade.unknown);
    expect(sample('ibnmajah', []).citation, 'HR. Ibnu Majah no. 1');
  });
}
