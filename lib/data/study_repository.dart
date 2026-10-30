import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/quran.dart';
import '../models/study.dart';
import 'kajian_content.dart';

/// Menyimpan sejarah, hadist, tag dan penanda ayat.
///
/// Konten bawaan dibaca dari `assets/data/kajian.json` dan diperbarui dari
/// GitHub lewat [refreshContent]; tambahan pengguna disimpan di
/// `kajian_pengguna.json`. Sejarah dan daftar tag buatan pengguna
/// untuk sebuah ayat menggantikan bawaan, sedangkan hadist pengguna ditambahkan.
class StudyRepository extends ChangeNotifier {
  final List<AyatHistory> _seedHistories = [];
  final List<Hadith> _seedHadiths = [];
  final List<AyatHistory> _userHistories = [];
  final List<Hadith> _userHadiths = [];
  final Map<String, List<String>> _seedTags = {};
  final Map<String, List<String>> _userTags = {};
  final Set<String> _bookmarks = {};
  final http.Client _client;
  int _contentVersion = 0;
  File? _userFile;
  File? _contentCache;

  StudyRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Versi konten kajian yang sedang dipakai (field "version" di kajian.json).
  int get contentVersion => _contentVersion;

  Future<void> load() async {
    final bundled = KajianContent.parse(await rootBundle.loadString('assets/data/kajian.json'));
    final support = await getApplicationSupportDirectory();
    _contentCache = File('${support.path}/kajian_terbaru.json');
    final cached = await _contentCache!.exists()
        ? KajianContent.tryParse(await _contentCache!.readAsString())
        : null;
    // Konten unduhan dipakai kecuali aplikasi versi baru membawa konten
    // bawaan dengan nomor versi yang lebih tinggi.
    useContent(cached != null && cached.version >= bundled.version ? cached : bundled);

    _userFile = File('${(await getApplicationDocumentsDirectory()).path}/kajian_pengguna.json');
    if (await _userFile!.exists()) {
      try {
        final user = jsonDecode(await _userFile!.readAsString()) as Map<String, dynamic>;
        _userHistories.addAll(_parseHistories(user['histories'], isUser: true));
        _userHadiths.addAll(_parseHadiths(user['hadiths'], isUser: true));
        _userTags.addAll(_parseTags(user['tags']));
        _bookmarks.addAll((user['bookmarks'] as List<dynamic>? ?? []).cast<String>());
      } on FormatException catch (e) {
        debugPrint('kajian_pengguna.json rusak, diabaikan: $e');
      }
    }
    notifyListeners();
  }

  /// Mengganti konten bawaan yang sedang dipakai.
  @visibleForTesting
  void useContent(KajianContent content) {
    _contentVersion = content.version;
    _seedHistories
      ..clear()
      ..addAll(content.histories);
    _seedHadiths
      ..clear()
      ..addAll(content.hadiths);
    _seedTags
      ..clear()
      ..addAll(content.tags);
    notifyListeners();
  }

  /// Mengunduh `kajian.json` terbaru dari GitHub. Konten yang valid langsung
  /// dipakai dan disimpan untuk penggunaan offline; kegagalan apa pun (tidak
  /// ada internet, file rusak) diabaikan dan konten lama tetap dipakai.
  /// Mengembalikan true bila konten berubah.
  Future<bool> refreshContent() async {
    try {
      final response = await _client
          .get(Uri.parse(KajianContent.remoteUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return false;
      final body = utf8.decode(response.bodyBytes);
      final remote = KajianContent.tryParse(body);
      if (remote == null) {
        debugPrint('kajian.json dari GitHub tidak valid, diabaikan');
        return false;
      }
      // Jangan mundur ke konten lama (mis. aplikasi baru membawa versi lebih
      // tinggi daripada file di GitHub). Versi sama tetap diterima agar
      // perubahan yang lupa menaikkan "version" tetap sampai ke pengguna.
      if (remote.version < _contentVersion) return false;
      final cache = _contentCache;
      if (cache != null && await cache.exists() && await cache.readAsString() == body) {
        return false;
      }
      await cache?.writeAsString(body);
      useContent(remote);
      return true;
    } on Exception catch (e) {
      debugPrint('Gagal memperbarui konten kajian: $e');
      return false;
    }
  }

  static List<AyatHistory> _parseHistories(dynamic list, {bool isUser = false}) =>
      (list as List<dynamic>? ?? [])
          .map((e) => AyatHistory.fromJson(e as Map<String, dynamic>, isUser: isUser))
          .toList();

  static List<Hadith> _parseHadiths(dynamic list, {bool isUser = false}) =>
      (list as List<dynamic>? ?? [])
          .map((e) => Hadith.fromJson(e as Map<String, dynamic>, isUser: isUser))
          .toList();

  static Map<String, List<String>> _parseTags(dynamic map) => {
        for (final e in (map as Map<String, dynamic>? ?? {}).entries)
          e.key: (e.value as List<dynamic>).cast<String>(),
      };

  AyatHistory? historyFor(int surah, int ayat) {
    for (final h in _userHistories) {
      if (h.covers(surah, ayat)) return h;
    }
    for (final h in _seedHistories) {
      if (h.covers(surah, ayat)) return h;
    }
    return null;
  }

  List<Hadith> hadithsFor(int surah, int ayat) => [
        ..._seedHadiths.where((h) => h.surah == surah && h.ayat == ayat),
        ..._userHadiths.where((h) => h.surah == surah && h.ayat == ayat),
      ];

  /// Semua sejarah yang aktif (sejarah pengguna menutupi bawaan pada ayat yang sama).
  List<AyatHistory> get allHistories {
    final seed = _seedHistories.where((s) => !_userHistories
        .any((u) => u.surah == s.surah && u.fromAyat <= s.toAyat && u.toAyat >= s.fromAyat));
    return [...seed, ..._userHistories]
      ..sort((a, b) => a.surah != b.surah ? a.surah - b.surah : a.fromAyat - b.fromAyat);
  }

  List<Hadith> get allHadiths => [..._seedHadiths, ..._userHadiths]
    ..sort((a, b) => a.surah != b.surah ? a.surah - b.surah : a.ayat - b.ayat);

  /// Ayat-ayat yang memiliki kajian (sejarah atau hadist), urut mushaf.
  List<(int, int)> get studiedAyat {
    final keys = <String, (int, int)>{};
    for (final h in allHistories) {
      for (var a = h.fromAyat; a <= h.toAyat; a++) {
        keys[ayatKey(h.surah, a)] = (h.surah, a);
      }
    }
    for (final h in allHadiths) {
      keys[ayatKey(h.surah, h.ayat)] = (h.surah, h.ayat);
    }
    return keys.values.toList()
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  }

  /// Menyimpan sejarah pengguna. [replacing] adalah sejarah pengguna lama
  /// yang diedit, agar ikut terhapus bila rentang ayatnya diubah.
  Future<void> saveHistory(AyatHistory history, {AyatHistory? replacing}) async {
    _userHistories.removeWhere((h) =>
        _sameRange(h, history) || (replacing != null && _sameRange(h, replacing)));
    _userHistories.add(history);
    await _persist();
  }

  Future<void> deleteHistory(AyatHistory history) async {
    _userHistories.removeWhere((h) => _sameRange(h, history));
    await _persist();
  }

  static bool _sameRange(AyatHistory a, AyatHistory b) =>
      a.surah == b.surah && a.fromAyat == b.fromAyat && a.toAyat == b.toAyat;

  Future<void> saveHadith(Hadith hadith) async {
    final i = _userHadiths.indexWhere((h) => h.id == hadith.id);
    if (i >= 0) {
      _userHadiths[i] = hadith;
    } else {
      _userHadiths.add(hadith);
    }
    await _persist();
  }

  Future<void> deleteHadith(Hadith hadith) async {
    _userHadiths.removeWhere((h) => h.id == hadith.id);
    await _persist();
  }

  /// Tag pembahasan sebuah ayat, misalnya "Tauhid" atau "Shalat".
  List<String> tagsFor(int surah, int ayat) {
    final key = ayatKey(surah, ayat);
    return _userTags[key] ?? _seedTags[key] ?? const [];
  }

  Map<String, List<String>> get _activeTags => {..._seedTags, ..._userTags}
    ..removeWhere((_, tags) => tags.isEmpty);

  /// Semua tag beserta jumlah ayatnya, urut dari yang paling banyak dipakai.
  List<(String, int)> get allTags {
    final counts = <String, int>{};
    for (final tags in _activeTags.values) {
      for (final t in tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => a.$2 != b.$2 ? b.$2 - a.$2 : a.$1.compareTo(b.$1));
  }

  /// Ayat yang memiliki semua [tags] (atau semua ayat bertag bila kosong).
  List<(int, int)> ayatWithTags(Set<String> tags) {
    final result = <(int, int)>[];
    for (final e in _activeTags.entries) {
      if (tags.every(e.value.contains)) {
        final p = e.key.split(':');
        result.add((int.parse(p[0]), int.parse(p[1])));
      }
    }
    return result..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  }

  /// Merapikan penulisan tag dan menyamakannya dengan tag yang sudah ada
  /// tanpa membedakan huruf besar/kecil, agar "tauhid" dan "Tauhid" tidak dobel.
  String normalizeTag(String raw) {
    final tag = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    for (final (existing, _) in allTags) {
      if (existing.toLowerCase() == tag.toLowerCase()) return existing;
    }
    return tag;
  }

  Future<void> setTags(int surah, int ayat, List<String> tags) async {
    _userTags[ayatKey(surah, ayat)] = tags;
    await _persist();
  }

  bool isBookmarked(String key) => _bookmarks.contains(key);

  List<(int, int)> get bookmarks => _bookmarks.map((k) {
        final p = k.split(':');
        return (int.parse(p[0]), int.parse(p[1]));
      }).toList()
        ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);

  Future<void> toggleBookmark(String key) async {
    if (!_bookmarks.remove(key)) _bookmarks.add(key);
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _userFile?.writeAsString(jsonEncode({
      'histories': _userHistories.map((h) => h.toJson()).toList(),
      'hadiths': _userHadiths.map((h) => h.toJson()).toList(),
      'tags': _userTags,
      'bookmarks': _bookmarks.toList(),
    }));
  }
}
