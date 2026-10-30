import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../models/hadith_library.dart';
import '../models/quran.dart';
import '../models/study.dart';
import '../widgets/common.dart';
import 'ayat_screen.dart';
import 'forms.dart';

/// Tab "Hadist": kumpulan kitab hadist yang bisa dibaca per bab.
class HadithLibraryTab extends StatefulWidget {
  const HadithLibraryTab({super.key});

  @override
  State<HadithLibraryTab> createState() => _HadithLibraryTabState();
}

class _HadithLibraryTabState extends State<HadithLibraryTab> {
  Future<List<HadithBook>>? _books;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _books ??= AppScope.of(context).hadithApi.books();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kumpulan Hadist')),
      body: FutureBuilder(
        future: _books,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final books = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == books.length) {
                return Text(
                  'Teks Arab dan terjemahan Indonesia dari proyek terbuka hadith-api '
                  '(fawazahmed0). Bab yang pernah dibuka dapat dibaca tanpa internet.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                );
              }
              final book = books[i];
              return Card.outlined(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.menu_book, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  title: Text(book.name, style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    '${book.author}\n${book.chapters.length} bab · '
                    '${formatThousands(book.hadithCount)} hadist',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookScreen(book: book)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Daftar bab dalam satu kitab, dengan pencarian nama bab dan lompat ke nomor.
class BookScreen extends StatefulWidget {
  final HadithBook book;

  const BookScreen({super.key, required this.book});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  String _query = '';

  Future<void> _goToNumber() async {
    final book = widget.book;
    final controller = TextEditingController();
    final number = await showDialog<int>(
      context: context,
      builder: (context) {
        void submit() {
          final n = int.tryParse(controller.text.trim());
          if (n != null && n >= book.firstNumber && n <= book.lastNumber) {
            Navigator.pop(context, n);
          }
        }

        return AlertDialog(
          title: const Text('Buka nomor hadist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nomor',
              helperText: 'Antara ${book.firstNumber} dan ${book.lastNumber}',
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(onPressed: submit, child: const Text('Buka')),
          ],
        );
      },
    );
    controller.dispose();
    if (number == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HadithNumberScreen(book: book, number: number),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final chapters = book.chapters
        .where((c) => _query.isEmpty || c.name.toLowerCase().contains(_query))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(book.name),
        actions: [
          IconButton(
            tooltip: 'Buka nomor hadist',
            icon: const Icon(Icons.pin_outlined),
            onPressed: _goToNumber,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Cari bab, mis. shalat, puasa, adab',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: chapters.isEmpty
                ? const EmptyState(icon: Icons.search_off, message: 'Tidak ada bab yang cocok.')
                : ListView.separated(
                    itemCount: chapters.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final c = chapters[i];
                      return ListTile(
                        leading: NumberBadge(c.number),
                        title: Text('Kitab ${c.name}'),
                        subtitle: Text('${c.count} hadist'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChapterScreen(book: book, chapter: c),
                        )),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChapterScreen extends StatefulWidget {
  final HadithBook book;
  final HadithChapter chapter;

  const ChapterScreen({super.key, required this.book, required this.chapter});

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  Future<List<LibraryHadith>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).hadithApi.chapter(widget.book, widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitab ${widget.chapter.name}'),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetry(
              error: snapshot.error!,
              onRetry: () => setState(() {
                _future = AppScope.of(context).hadithApi.chapter(widget.book, widget.chapter);
              }),
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final hadiths = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: hadiths.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => LibraryHadithCard(hadith: hadiths[i]),
          );
        },
      ),
    );
  }
}

class HadithNumberScreen extends StatefulWidget {
  final HadithBook book;
  final int number;

  const HadithNumberScreen({super.key, required this.book, required this.number});

  @override
  State<HadithNumberScreen> createState() => _HadithNumberScreenState();
}

class _HadithNumberScreenState extends State<HadithNumberScreen> {
  Future<LibraryHadith?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).hadithApi.hadith(widget.book, widget.number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.book.name} no. ${widget.number}')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetry(
              error: snapshot.error!,
              onRetry: () => setState(() {
                _future = AppScope.of(context).hadithApi.hadith(widget.book, widget.number);
              }),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final hadith = snapshot.data;
          if (hadith == null) {
            return const EmptyState(icon: Icons.search_off, message: 'Hadist dengan nomor ini tidak ditemukan.');
          }
          final chapter = widget.book.chapterByNumber(hadith.chapter);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (chapter != null) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.list),
                  label: Text('Lihat seluruh Kitab ${chapter.name}'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChapterScreen(book: widget.book, chapter: chapter),
                  )),
                ),
                const SizedBox(height: 12),
              ],
              LibraryHadithCard(hadith: hadith),
            ],
          );
        },
      ),
    );
  }
}

/// Teks terjemahan menandai nama perawi dengan [kurung siku]; nama-nama itu
/// ditebalkan dan kurungnya dihilangkan agar sanad mudah dibaca.
List<TextSpan> _narratorSpans(String text, TextStyle? bold) {
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in RegExp(r'\[([^\]]+)\]').allMatches(text)) {
    spans.add(TextSpan(text: text.substring(last, m.start)));
    spans.add(TextSpan(text: m.group(1), style: bold));
    last = m.end;
  }
  spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

String _plain(String text) => text.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (m) => m.group(1)!);

class LibraryHadithCard extends StatelessWidget {
  final LibraryHadith hadith;

  const LibraryHadithCard({super.key, required this.hadith});

  Future<void> _linkToAyat(BuildContext context) async {
    final target = await showDialog<(int, int)>(
      context: context,
      builder: (_) => const _PickAyatDialog(),
    );
    if (target == null || !context.mounted) return;
    final (surah, ayat) = target;
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => HadithForm(
        surah: surah,
        ayat: ayat,
        draft: Hadith(
          id: 'user-${DateTime.now().microsecondsSinceEpoch}',
          surah: surah,
          ayat: ayat,
          arabic: hadith.arabic,
          translation: _plain(hadith.indonesian),
          narrator: '',
          source: hadith.citation,
          grade: hadith.grade,
        ),
      ),
    ));
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Hadist dikaitkan ke QS $surah:$ayat'),
      action: SnackBarAction(
        label: 'Lihat',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AyatScreen(surahNumber: surah, ayatNumber: ayat),
        )),
      ),
    ));
  }

  void _copy(BuildContext context) {
    final text = [
      if (hadith.arabic.isNotEmpty) hadith.arabic,
      if (hadith.indonesian.isNotEmpty) _plain(hadith.indonesian),
      '(${hadith.citation})',
    ].join('\n\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hadist disalin')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = hadith;
    final showSequence = h.referenceNumber != '${h.number}';
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      showSequence
                          ? 'No. ${h.referenceNumber} (urutan ${h.number})'
                          : 'No. ${h.referenceNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  if (h.grade != HadithGrade.unknown) GradeChip(h.grade),
                ],
              ),
            ),
            if (h.arabic.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ArabicText(h.arabic, size: 22),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: h.indonesian.isEmpty
                  ? Text(
                      'Terjemahan Indonesia belum tersedia untuk hadist ini.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    )
                  : Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                        children: _narratorSpans(
                          h.indonesian,
                          const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
            ),
            if (h.grades.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Penilaian: ${h.grades.map((g) => '${g.scholar}: ${g.grade}').join(' · ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Salin'),
                  onPressed: () => _copy(context),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Kaitkan ke ayat'),
                  onPressed: () => _linkToAyat(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog memilih surat dan nomor ayat.
class _PickAyatDialog extends StatefulWidget {
  const _PickAyatDialog();

  @override
  State<_PickAyatDialog> createState() => _PickAyatDialogState();
}

class _PickAyatDialogState extends State<_PickAyatDialog> {
  Future<List<Surah>>? _surahs;
  Surah? _surah;
  final _ayat = TextEditingController();
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _surahs ??= AppScope.of(context).api.surahs();
  }

  @override
  void dispose() {
    _ayat.dispose();
    super.dispose();
  }

  void _submit() {
    final surah = _surah;
    final ayat = int.tryParse(_ayat.text.trim());
    if (surah == null) {
      setState(() => _error = 'Pilih surat terlebih dahulu');
    } else if (ayat == null || ayat < 1 || ayat > surah.ayatCount) {
      setState(() => _error = 'Nomor ayat harus 1–${surah.ayatCount}');
    } else {
      Navigator.pop(context, (surah.number, ayat));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kaitkan ke ayat'),
      content: FutureBuilder(
        future: _surahs,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Daftar surat belum bisa dimuat. Periksa koneksi internet.');
          }
          if (!snapshot.hasData) {
            return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownMenu<Surah>(
                label: const Text('Surat'),
                enableFilter: true,
                requestFocusOnTap: true,
                expandedInsets: EdgeInsets.zero,
                menuHeight: 320,
                dropdownMenuEntries: [
                  for (final s in snapshot.data!)
                    DropdownMenuEntry(value: s, label: '${s.number}. ${s.latinName}'),
                ],
                onSelected: (s) => setState(() {
                  _surah = s;
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ayat,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nomor ayat',
                  helperText: _surah == null ? null : '1–${_surah!.ayatCount}',
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Lanjut')),
      ],
    );
  }
}
