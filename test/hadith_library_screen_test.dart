import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ngaji/app_scope.dart';
import 'package:ngaji/data/app_prefs.dart';
import 'package:ngaji/data/hadith_api.dart';
import 'package:ngaji/data/json_cache.dart';
import 'package:ngaji/data/quran_api.dart';
import 'package:ngaji/data/study_repository.dart';
import 'package:ngaji/screens/hadith_library.dart';

/// Cache tiruan: mengembalikan data contoh tanpa jaringan.
class _FakeCache extends JsonCache {
  _FakeCache() : super('test');

  @override
  Future<Map<String, dynamic>> get(String url, String cacheName) async {
    if (url.contains('equran.id')) {
      return {
        'data': [
          {'nomor': 1, 'nama': 'الفاتحة', 'namaLatin': 'Al-Fatihah', 'jumlahAyat': 7,
           'tempatTurun': 'Mekah', 'arti': 'Pembukaan', 'deskripsi': ''},
        ],
      };
    }
    final arabic = url.contains('/ara-');
    return {
      'metadata': {'section': {'1': 'Revelation'}},
      'hadiths': [
        {
          'hadithnumber': 1,
          'arabicnumber': 1,
          'text': arabic
              ? 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ'
              : 'Telah menceritakan kepada kami [Al-Humaidi] ... "Semua perbuatan tergantung niatnya."',
          'grades': [],
        },
      ],
    };
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('menelusuri kitab sampai kartu hadist dan dialog kaitkan ayat', (tester) async {
    final cache = _FakeCache();
    await tester.pumpWidget(AppScope(
      api: QuranApi(cache: cache),
      hadithApi: HadithApi(cache: cache),
      study: StudyRepository(),
      prefs: AppPrefs(),
      child: const MaterialApp(home: HadithLibraryTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Shahih Al-Bukhari'), findsOneWidget);
    await tester.tap(find.text('Shahih Al-Bukhari'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kitab Permulaan Wahyu'));
    await tester.pumpAndSettle();

    expect(find.text('No. 1'), findsOneWidget);
    expect(find.textContaining('Semua perbuatan tergantung niatnya', findRichText: true), findsOneWidget);
    expect(find.text('Shahih'), findsOneWidget);

    await tester.tap(find.text('Kaitkan ke ayat'));
    await tester.pumpAndSettle();
    expect(find.text('Nomor ayat'), findsOneWidget);

    // Tanpa memilih surat, tombol Lanjut menampilkan pesan kesalahan.
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih surat terlebih dahulu'), findsOneWidget);
  });
}
