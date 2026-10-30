/// Sejarah / asbabun nuzul sebuah ayat. Satu ayat memiliki satu sejarah,
/// tetapi satu sejarah boleh berlaku untuk rentang ayat (misal 96:1-5).
class AyatHistory {
  final int surah;
  final int fromAyat;
  final int toAyat;
  final String title;
  final String period;
  final String content;
  final String sources;
  final bool isUser;

  const AyatHistory({
    required this.surah,
    required this.fromAyat,
    required this.toAyat,
    required this.title,
    required this.period,
    required this.content,
    required this.sources,
    this.isUser = false,
  });

  String get rangeLabel =>
      fromAyat == toAyat ? '$surah:$fromAyat' : '$surah:$fromAyat-$toAyat';

  bool covers(int s, int a) => s == surah && a >= fromAyat && a <= toAyat;

  factory AyatHistory.fromJson(Map<String, dynamic> json, {bool isUser = false}) =>
      AyatHistory(
        surah: json['surah'] as int,
        fromAyat: json['from'] as int,
        toAyat: (json['to'] ?? json['from']) as int,
        title: json['title'] as String,
        period: json['period'] as String? ?? '',
        content: json['content'] as String,
        sources: json['sources'] as String? ?? '',
        isUser: isUser,
      );

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'from': fromAyat,
        'to': toAyat,
        'title': title,
        'period': period,
        'content': content,
        'sources': sources,
      };
}

enum HadithGrade {
  shahih('Shahih'),
  hasan('Hasan'),
  dhaif("Dha'if"),
  unknown('Belum diketahui');

  final String label;
  const HadithGrade(this.label);

  static HadithGrade parse(String? value) => HadithGrade.values.firstWhere(
        (g) => g.name == value,
        orElse: () => HadithGrade.unknown,
      );
}

/// Hadist yang menjelaskan sebuah ayat. Satu ayat bisa memiliki banyak hadist.
class Hadith {
  final String id;
  final int surah;
  final int ayat;
  final String arabic;
  final String translation;
  final String narrator;
  final String source;
  final HadithGrade grade;
  final String explanation;
  final bool isUser;

  const Hadith({
    required this.id,
    required this.surah,
    required this.ayat,
    this.arabic = '',
    required this.translation,
    required this.narrator,
    required this.source,
    this.grade = HadithGrade.unknown,
    this.explanation = '',
    this.isUser = false,
  });

  factory Hadith.fromJson(Map<String, dynamic> json, {bool isUser = false}) => Hadith(
        id: json['id'] as String,
        surah: json['surah'] as int,
        ayat: (json['ayat'] ?? json['ayah']) as int, // 'ayah': format lama
        arabic: json['arabic'] as String? ?? '',
        translation: json['translation'] as String,
        narrator: json['narrator'] as String? ?? '',
        source: json['source'] as String? ?? '',
        grade: HadithGrade.parse(json['grade'] as String?),
        explanation: json['explanation'] as String? ?? '',
        isUser: isUser,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'surah': surah,
        'ayat': ayat,
        'arabic': arabic,
        'translation': translation,
        'narrator': narrator,
        'source': source,
        'grade': grade.name,
        'explanation': explanation,
      };
}
