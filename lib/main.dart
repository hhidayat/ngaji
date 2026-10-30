import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_scope.dart';
import 'data/app_prefs.dart';
import 'data/hadith_api.dart';
import 'data/quran_api.dart';
import 'data/study_repository.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font Amiri dibundel di assets/google_fonts agar teks Arab tampil offline
  // dan aplikasi tidak menghubungi server Google Fonts.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Amiri'], license);
  });
  final study = StudyRepository();
  final prefs = AppPrefs();
  await (study.load(), prefs.load()).wait;
  runApp(NgajiApp(api: QuranApi(), hadithApi: HadithApi(), study: study, prefs: prefs));
  // Ambil konten kajian terbaru dari GitHub di latar belakang.
  unawaited(study.refreshContent());
}

class NgajiApp extends StatelessWidget {
  final QuranApi api;
  final HadithApi hadithApi;
  final StudyRepository study;
  final AppPrefs prefs;

  const NgajiApp({
    super.key,
    required this.api,
    required this.hadithApi,
    required this.study,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: api,
      hadithApi: hadithApi,
      study: study,
      prefs: prefs,
      child: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => MaterialApp(
          title: 'Ngaji',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: prefs.themeMode,
          home: prefs.onboarded ? const HomeScreen() : const OnboardingScreen(),
        ),
      ),
    );
  }
}
