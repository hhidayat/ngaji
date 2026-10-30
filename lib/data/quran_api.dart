import '../models/quran.dart';
import 'json_cache.dart';

/// Mengambil teks Al-Qur'an, terjemahan dan tafsir Kemenag dari equran.id.
/// Setiap respons disimpan ke disk sehingga surat yang pernah dibuka
/// tetap bisa dibaca tanpa internet.
class QuranApi {
  static const _base = 'https://equran.id/api/v2';

  final JsonCache _cache;

  QuranApi({JsonCache? cache}) : _cache = cache ?? JsonCache('quran_cache');

  Future<List<Surah>> surahs() async {
    final data = await _get('surat', 'surat.json') as List<dynamic>;
    return data.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SurahDetail> surah(int number) async {
    final data = await _get('surat/$number', 'surat_$number.json') as Map<String, dynamic>;
    final ayatList = (data['ayat'] as List<dynamic>)
        .map((e) => Ayat.fromJson(number, e as Map<String, dynamic>))
        .toList();
    return SurahDetail(Surah.fromJson(data), ayatList);
  }

  /// Tafsir Kemenag per ayat, dipetakan dari nomor ayat ke teks tafsir.
  Future<Map<int, String>> tafsir(int surah) async {
    final data = await _get('tafsir/$surah', 'tafsir_$surah.json') as Map<String, dynamic>;
    return {
      for (final t in data['tafsir'] as List<dynamic>)
        (t as Map<String, dynamic>)['ayat'] as int: (t['teks'] as String).trim(),
    };
  }

  Future<dynamic> _get(String path, String cacheName) async =>
      (await _cache.get('$_base/$path', cacheName))['data'];
}
