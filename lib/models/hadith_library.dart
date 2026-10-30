import 'study.dart';

/// Kitab hadist dalam perpustakaan, misalnya Shahih Al-Bukhari.
class HadithBook {
  final String slug;
  final String name;
  final String author;
  final List<HadithChapter> chapters;

  const HadithBook({
    required this.slug,
    required this.name,
    required this.author,
    required this.chapters,
  });

  int get hadithCount => chapters.fold(0, (sum, c) => sum + c.count);

  int get firstNumber => chapters.map((c) => c.first).reduce((a, b) => a < b ? a : b);
  int get lastNumber => chapters.map((c) => c.last).reduce((a, b) => a > b ? a : b);

  /// Nama kitab dalam penulisan rujukan, misalnya "HR. Al-Bukhari no. 1".
  String get citationName => switch (slug) {
        'bukhari' => 'Al-Bukhari',
        'muslim' => 'Muslim',
        'abudawud' => 'Abu Dawud',
        'tirmidhi' => 'At-Tirmidzi',
        'nasai' => "An-Nasa'i",
        'ibnmajah' => 'Ibnu Majah',
        'malik' => 'Malik',
        _ => name,
      };

  HadithChapter? chapterByNumber(int? number) =>
      chapters.where((c) => c.number == number).firstOrNull;

  factory HadithBook.fromJson(Map<String, dynamic> json) => HadithBook(
        slug: json['slug'] as String,
        name: json['name'] as String,
        author: json['author'] as String,
        chapters: (json['chapters'] as List<dynamic>)
            .map((e) => HadithChapter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Bab (kitab bagian) di dalam sebuah kitab hadist.
///
/// [first] dan [last] adalah nomor terkecil dan terbesar di bab itu. Pada
/// beberapa kitab rentang ini tumpang tindih dengan bab lain, jadi jumlah
/// hadist disimpan terpisah di [count].
class HadithChapter {
  final int number;
  final String name;
  final int first;
  final int last;
  final int count;

  const HadithChapter({
    required this.number,
    required this.name,
    required this.first,
    required this.last,
    required this.count,
  });

  factory HadithChapter.fromJson(Map<String, dynamic> json) => HadithChapter(
        number: json['number'] as int,
        name: json['name'] as String,
        first: json['first'] as int,
        last: json['last'] as int,
        count: json['count'] as int,
      );
}

class HadithGradeNote {
  final String scholar;
  final String grade;

  const HadithGradeNote(this.scholar, this.grade);
}

/// Satu hadist dari kitab, berisi teks Arab dan terjemahan Indonesia.
class LibraryHadith {
  final HadithBook book;

  /// Nomor bab tempat hadist ini berada.
  final int? chapter;

  /// Nomor urut di dalam data sumber.
  final int number;

  /// Nomor yang lazim dipakai dalam rujukan. Untuk Shahih Muslim ini adalah
  /// penomoran Fuad Abdul Baqi; untuk kitab lain sama dengan [number].
  final String referenceNumber;
  final String arabic;
  final String indonesian;
  final List<HadithGradeNote> grades;

  const LibraryHadith({
    required this.book,
    this.chapter,
    required this.number,
    required this.referenceNumber,
    required this.arabic,
    required this.indonesian,
    required this.grades,
  });

  String get citation => 'HR. ${book.citationName} no. $referenceNumber';

  /// Derajat ringkas: Shahihain dianggap shahih; kitab lain mengikuti
  /// penilaian Al-Albani bila tersedia.
  HadithGrade get grade {
    if (book.slug == 'bukhari' || book.slug == 'muslim') return HadithGrade.shahih;
    final albani = grades.where((g) => g.scholar.contains('Albani')).firstOrNull;
    final text = (albani ?? grades.firstOrNull)?.grade.toLowerCase() ?? '';
    if (text.contains('sahih') || text.contains('shahih')) return HadithGrade.shahih;
    if (text.contains('hasan')) return HadithGrade.hasan;
    if (text.contains('da') && text.contains('if')) return HadithGrade.dhaif;
    return HadithGrade.unknown;
  }
}
