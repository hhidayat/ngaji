import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ngaji/data/app_prefs.dart';
import 'package:ngaji/data/hadith_api.dart';
import 'package:ngaji/data/json_cache.dart';
import 'package:ngaji/data/quran_api.dart';
import 'package:ngaji/data/study_repository.dart';
import 'package:ngaji/main.dart';

/// Data equran.id tiruan: dua surat, Al-Fatihah berisi dua ayat.
class _FakeQuranCache extends JsonCache {
  _FakeQuranCache() : super('test');

  static const _fatihah = {
    'nomor': 1, 'nama': 'الفاتحة', 'namaLatin': 'Al-Fatihah', 'jumlahAyat': 2,
    'tempatTurun': 'Mekah', 'arti': 'Pembukaan',
    'deskripsi': 'Surat <i>Al Faatihah</i> adalah surat pertama.',
  };
  static const _baqarah = {
    'nomor': 2, 'nama': 'البقرة', 'namaLatin': 'Al-Baqarah', 'jumlahAyat': 286,
    'tempatTurun': 'Madinah', 'arti': 'Sapi', 'deskripsi': '',
  };

  @override
  Future<Map<String, dynamic>> get(String url, String cacheName) async {
    if (url.endsWith('/surat')) return {'data': [_fatihah, _baqarah]};
    return {
      'data': {
        ..._fatihah,
        'ayat': [
          for (final n in [1, 2])
            {
              'nomorAyat': n,
              'teksArab': 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
              'teksLatin': 'Bismillāhir-raḥmānir-raḥīm(i).',
              'teksIndonesia': 'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.',
            },
        ],
      },
    };
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('pengenalan, beranda, dan halaman surat tampil tanpa overflow di HP kecil '
      'dengan huruf terbesar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final prefs = AppPrefs()
      ..arabicScale = AppPrefs.arabicScaleRange.$2
      ..translationScale = AppPrefs.translationScaleRange.$2;
    final cache = _FakeQuranCache();
    await tester.pumpWidget(NgajiApp(
      api: QuranApi(cache: cache),
      hadithApi: HadithApi(cache: cache),
      study: StudyRepository(),
      prefs: prefs,
    ));
    await tester.pumpAndSettle();

    // Layar pengenalan: tiga kali "Lanjut", lalu "Mulai Belajar".
    expect(find.text('Ahlan wa sahlan di Ngaji'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Mulai Belajar'));
    await tester.pumpAndSettle();
    expect(prefs.onboarded, isTrue);

    // Beranda.
    expect(find.text("Assalamu'alaikum"), findsOneWidget);
    expect(find.text('Mulai dari Al-Fatihah'), findsOneWidget);
    expect(find.text('Al-Baqarah'), findsOneWidget);

    // Pencarian surat.
    await tester.enterText(find.byType(SearchBar), 'sapi');
    await tester.pumpAndSettle();
    expect(find.text('Al-Fatihah'), findsNothing);
    expect(find.text('Al-Baqarah'), findsOneWidget);
    await tester.enterText(find.byType(SearchBar), '');
    await tester.pumpAndSettle();

    // Halaman surat.
    await tester.tap(find.text('Al-Fatihah'));
    await tester.pumpAndSettle();
    expect(find.text('Pelajari ayat ini'), findsWidgets);
    expect(prefs.lastRead, (1, 1));

    // Lembar pengaturan tampilan.
    await tester.tap(find.byTooltip('Pengaturan tampilan'));
    await tester.pumpAndSettle();
    expect(find.text('Ukuran huruf Arab'), findsOneWidget);
    await tester.ensureVisible(find.text('Tampilkan tulisan latin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan tulisan latin'));
    await tester.pumpAndSettle();
    expect(prefs.showLatin, isFalse);
  });
}
