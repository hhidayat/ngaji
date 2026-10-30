import 'dart:convert';

import '../models/study.dart';

/// Konten kajian bawaan (sejarah, hadist penjelas, tema) dari `kajian.json`.
///
/// File yang sama dibundel di aplikasi dan dibaca dari GitHub, sehingga
/// konten bisa diperbarui tanpa merilis versi aplikasi baru.
class KajianContent {
  /// Alamat file konten terbaru. Repo GitHub harus publik.
  static const remoteUrl =
      'https://raw.githubusercontent.com/hhidayat/ngaji/main/assets/data/kajian.json';

  /// Versi format file yang dipahami aplikasi ini. Naikkan hanya bila struktur
  /// JSON berubah; aplikasi lama akan mengabaikan file dengan schema lebih baru.
  static const supportedSchema = 1;

  final int version;
  final List<AyatHistory> histories;
  final List<Hadith> hadiths;
  final Map<String, List<String>> tags;

  const KajianContent({
    required this.version,
    required this.histories,
    required this.hadiths,
    required this.tags,
  });

  /// Membaca dan memvalidasi isi `kajian.json`. Mengembalikan null bila file
  /// rusak, formatnya tidak didukung, atau isinya tidak masuk akal, agar
  /// aplikasi tetap memakai konten sebelumnya.
  static KajianContent? tryParse(String source) {
    try {
      return parse(source);
    } on FormatException {
      return null;
    }
  }

  /// Seperti [tryParse], tetapi melempar [FormatException] berisi alasan
  /// penolakan. Dipakai oleh tes/CI agar penyunting tahu apa yang salah.
  static KajianContent parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw FormatException('JSON tidak valid: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) throw const FormatException('Isi file harus berupa objek JSON');

    final schema = decoded['schema'] ?? 1;
    if (schema is! int || schema > supportedSchema) {
      throw FormatException('schema $schema belum didukung (maks. $supportedSchema)');
    }
    final version = decoded['version'];
    if (version is! int || version < 1) throw const FormatException('"version" harus bilangan bulat ≥ 1');

    final KajianContent content;
    try {
      content = KajianContent(
        version: version,
        histories: [
          for (final e in decoded['histories'] as List<dynamic>? ?? [])
            AyatHistory.fromJson(e as Map<String, dynamic>),
        ],
        hadiths: [
          for (final e in decoded['hadiths'] as List<dynamic>? ?? [])
            Hadith.fromJson(e as Map<String, dynamic>),
        ],
        tags: {
          for (final e in (decoded['tags'] as Map<String, dynamic>? ?? {}).entries)
            e.key: (e.value as List<dynamic>).cast<String>().toList(),
        },
      );
    } on TypeError catch (e) {
      throw FormatException('Ada isian yang hilang atau salah tipe: $e');
    }
    content._validate();
    return content;
  }

  void _validate() {
    void check(bool ok, String message) {
      if (!ok) throw FormatException(message);
    }

    for (final h in histories) {
      check(h.surah >= 1 && h.surah <= 114, 'Sejarah "${h.title}": nomor surat ${h.surah} tidak valid');
      check(h.fromAyat >= 1 && h.fromAyat <= h.toAyat, 'Sejarah "${h.title}": rentang ayat tidak valid');
      check(h.title.trim().isNotEmpty && h.content.trim().isNotEmpty, 'Sejarah ${h.rangeLabel}: judul dan isi wajib diisi');
    }
    final ids = <String>{};
    for (final h in hadiths) {
      check(ids.add(h.id), 'id hadist "${h.id}" dipakai lebih dari sekali');
      check(h.surah >= 1 && h.surah <= 114 && h.ayat >= 1, 'Hadist "${h.id}": surat/ayat tidak valid');
      check(h.translation.trim().isNotEmpty && h.source.trim().isNotEmpty, 'Hadist "${h.id}": terjemahan dan sumber wajib diisi');
    }
    for (final MapEntry(:key, :value) in tags.entries) {
      check(RegExp(r'^\d{1,3}:\d{1,3}$').hasMatch(key), 'Kunci tema "$key" harus berformat surat:ayat, mis. 2:255');
      check(value.every((t) => t.trim().isNotEmpty), 'Tema kosong pada ayat $key');
      check(value.toSet().length == value.length, 'Tema dobel pada ayat $key');
    }
  }
}
