import 'package:flutter/widgets.dart';

import 'data/app_prefs.dart';
import 'data/hadith_api.dart';
import 'data/quran_api.dart';
import 'data/study_repository.dart';

/// Menyediakan [QuranApi], [HadithApi], [StudyRepository] dan [AppPrefs] ke
/// seluruh widget. Widget yang memanggil [AppScope.of] ikut dibangun ulang
/// saat kajian atau pengaturan berubah.
class AppScope extends InheritedNotifier<Listenable> {
  final QuranApi api;
  final HadithApi hadithApi;
  final StudyRepository study;
  final AppPrefs prefs;

  AppScope({
    super.key,
    required this.api,
    required this.hadithApi,
    required this.study,
    required this.prefs,
    required super.child,
  }) : super(notifier: Listenable.merge([study, prefs]));

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  /// Seperti [of], tetapi mengembalikan null bila tidak ada AppScope
  /// (misalnya pada widget test yang merender widget secara terpisah).
  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();
}
