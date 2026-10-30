/// Key unik untuk satu ayat, misalnya `2:255`.
String ayatKey(int surah, int ayat) => '$surah:$ayat';

String stripHtml(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .trim();

class Surah {
  final int number;
  final String name;
  final String latinName;
  final String meaning;
  final int ayatCount;
  final String revelationPlace;
  final String description;

  const Surah({
    required this.number,
    required this.name,
    required this.latinName,
    required this.meaning,
    required this.ayatCount,
    required this.revelationPlace,
    required this.description,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        number: json['nomor'] as int,
        name: json['nama'] as String,
        latinName: json['namaLatin'] as String,
        meaning: json['arti'] as String,
        ayatCount: json['jumlahAyat'] as int,
        revelationPlace: json['tempatTurun'] as String,
        description: stripHtml(json['deskripsi'] as String? ?? ''),
      );
}

class Ayat {
  final int surah;
  final int number;
  final String arabic;
  final String latin;
  final String translation;

  const Ayat({
    required this.surah,
    required this.number,
    required this.arabic,
    required this.latin,
    required this.translation,
  });

  String get key => ayatKey(surah, number);

  factory Ayat.fromJson(int surah, Map<String, dynamic> json) => Ayat(
        surah: surah,
        number: json['nomorAyat'] as int,
        arabic: json['teksArab'] as String,
        latin: (json['teksLatin'] as String).trim(),
        translation: json['teksIndonesia'] as String,
      );
}

class SurahDetail {
  final Surah surah;
  final List<Ayat> ayatList;

  const SurahDetail(this.surah, this.ayatList);
}
