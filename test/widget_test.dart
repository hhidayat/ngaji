import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ngaji/models/study.dart';

void main() {
  final seed = jsonDecode(File('assets/data/kajian.json').readAsStringSync()) as Map<String, dynamic>;
  final histories = (seed['histories'] as List).map((e) => AyatHistory.fromJson(e)).toList();
  final hadiths = (seed['hadiths'] as List).map((e) => Hadith.fromJson(e)).toList();

  test('data kajian bawaan valid', () {
    expect(histories, isNotEmpty);
    expect(hadiths, isNotEmpty);
    expect(hadiths.map((h) => h.id).toSet().length, hadiths.length, reason: 'id hadist harus unik');
    for (final h in histories) {
      expect(h.fromAyat, lessThanOrEqualTo(h.toAyat), reason: h.title);
      expect(h.surah, inInclusiveRange(1, 114));
    }
    for (final h in hadiths) {
      expect(h.source, isNotEmpty, reason: h.id);
      expect(h.grade, isNot(HadithGrade.unknown), reason: h.id);
    }
  });

  test('tag bawaan memakai key surah:ayat yang valid', () {
    final tags = (seed['tags'] as Map<String, dynamic>).cast<String, List<dynamic>>();
    expect(tags, isNotEmpty);
    for (final MapEntry(:key, :value) in tags.entries) {
      expect(key, matches(RegExp(r'^\d{1,3}:\d{1,3}$')));
      expect(value, isNotEmpty, reason: key);
      expect(value.toSet().length, value.length, reason: 'tag dobel di $key');
    }
  });

  test('sejarah berlaku untuk rentang ayat', () {
    final iqra = histories.firstWhere((h) => h.surah == 96);
    expect(iqra.covers(96, 1), isTrue);
    expect(iqra.covers(96, 5), isTrue);
    expect(iqra.covers(96, 6), isFalse);
    expect(iqra.rangeLabel, '96:1-5');
  });

  test('hadist pengguna bisa disimpan dan dibaca ulang', () {
    final h = hadiths.first;
    final restored = Hadith.fromJson(h.toJson(), isUser: true);
    expect(restored.translation, h.translation);
    expect(restored.grade, h.grade);
    expect(restored.isUser, isTrue);
  });
}
