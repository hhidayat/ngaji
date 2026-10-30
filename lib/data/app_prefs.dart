import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Pengaturan tampilan dan posisi baca terakhir, disimpan di `pengaturan.json`.
class AppPrefs extends ChangeNotifier {
  static const arabicScaleRange = (0.8, 1.6);
  static const translationScaleRange = (0.85, 1.5);

  double _arabicScale = 1;
  double _translationScale = 1;
  bool _showLatin = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _onboarded = false;
  (int, int)? _lastRead;
  File? _file;

  double get arabicScale => _arabicScale;
  double get translationScale => _translationScale;
  bool get showLatin => _showLatin;
  ThemeMode get themeMode => _themeMode;
  bool get onboarded => _onboarded;

  /// Ayat terakhir yang dibuka, sebagai (surat, ayat).
  (int, int)? get lastRead => _lastRead;

  Future<void> load() async {
    _file = File('${(await getApplicationDocumentsDirectory()).path}/pengaturan.json');
    if (!await _file!.exists()) return;
    try {
      final json = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
      _arabicScale = (json['arabicScale'] as num?)?.toDouble() ?? 1;
      _translationScale = (json['translationScale'] as num?)?.toDouble() ?? 1;
      _showLatin = json['showLatin'] as bool? ?? true;
      _themeMode = ThemeMode.values.asNameMap()[json['themeMode']] ?? ThemeMode.system;
      _onboarded = json['onboarded'] as bool? ?? false;
      final last = json['lastRead'] as List<dynamic>?;
      if (last != null && last.length == 2) _lastRead = (last[0] as int, last[1] as int);
    } on FormatException catch (e) {
      debugPrint('pengaturan.json rusak, diabaikan: $e');
    }
  }

  set arabicScale(double v) => _update(() => _arabicScale = v);
  set translationScale(double v) => _update(() => _translationScale = v);
  set showLatin(bool v) => _update(() => _showLatin = v);
  set themeMode(ThemeMode v) => _update(() => _themeMode = v);

  void finishOnboarding() => _update(() => _onboarded = true);

  void setLastRead(int surah, int ayat) {
    if (_lastRead == (surah, ayat)) return;
    _update(() => _lastRead = (surah, ayat));
  }

  void _update(VoidCallback change) {
    change();
    notifyListeners();
    _file?.writeAsString(jsonEncode({
      'arabicScale': _arabicScale,
      'translationScale': _translationScale,
      'showLatin': _showLatin,
      'themeMode': _themeMode.name,
      'onboarded': _onboarded,
      if (_lastRead != null) 'lastRead': [_lastRead!.$1, _lastRead!.$2],
    }));
  }
}
