import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quran.dart';
import '../models/study.dart';
import '../widgets/ayat_preview.dart';
import '../widgets/common.dart';
import 'ayat_screen.dart';

/// Membuka halaman kajian yang sudah difilter dengan [tag].
void openKajianForTag(BuildContext context, String tag) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => KajianTab(initialTags: {tag})),
    );

/// Menjelajahi ayat bertag, sejarah ayat dan hadist, dengan filter tag.
/// Dipakai sebagai tab di beranda maupun sebagai halaman tersendiri
/// (misalnya saat pengguna mengetuk sebuah tag).
class KajianTab extends StatefulWidget {
  final Set<String> initialTags;

  const KajianTab({super.key, this.initialTags = const {}});

  @override
  State<KajianTab> createState() => _KajianTabState();
}

class _KajianTabState extends State<KajianTab> {
  Future<List<Surah>>? _surahs;
  String _query = '';
  late final Set<String> _selectedTags = {...widget.initialTags};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _surahs ??= AppScope.of(context).api.surahs();
  }

  bool _contains(List<String> fields) =>
      _query.isEmpty || fields.any((f) => f.toLowerCase().contains(_query));

  void _open(int surah, int ayat) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AyatScreen(surahNumber: surah, ayatNumber: ayat),
      ));

  void _toggleTag(String tag) => setState(() {
        if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
      });

  @override
  Widget build(BuildContext context) {
    final study = AppScope.of(context).study;
    final allTags = study.allTags;
    final hasTags = allTags.isNotEmpty;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kajian Ayat'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(hasTags ? 160 : 112),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SearchBar(
                    hintText: 'Cari tema, sejarah, hadist, perawi...',
                    leading: const Icon(Icons.search),
                    elevation: const WidgetStatePropertyAll(0),
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                if (hasTags) _tagFilterBar(allTags),
                const TabBar(tabs: [Tab(text: 'Ayat'), Tab(text: 'Sejarah'), Tab(text: 'Hadist')]),
              ],
            ),
          ),
        ),
        body: FutureBuilder(
          future: _surahs,
          builder: (context, snapshot) {
            final names = {for (final s in snapshot.data ?? <Surah>[]) s.number: s.latinName};
            String label(int surah, String range) =>
                names[surah] == null ? 'QS $range' : '${names[surah]} · $range';

            final tagged = study.ayatWithTags(_selectedTags);
            final taggedKeys = {for (final (s, a) in tagged) ayatKey(s, a)};
            bool tagMatch(int surah, int ayat) =>
                _selectedTags.isEmpty || taggedKeys.contains(ayatKey(surah, ayat));

            final ayatList = tagged
                .where((a) => _contains([
                      ...study.tagsFor(a.$1, a.$2),
                      names[a.$1] ?? '',
                      '${a.$1}:${a.$2}',
                    ]))
                .toList();
            final histories = study.allHistories
                .where((h) => [for (var a = h.fromAyat; a <= h.toAyat; a++) a]
                    .any((a) => tagMatch(h.surah, a)))
                .where((h) => _contains([h.title, h.content, h.period, h.sources, names[h.surah] ?? '']))
                .toList();
            final hadiths = study.allHadiths
                .where((h) => tagMatch(h.surah, h.ayat))
                .where((h) => _contains([h.translation, h.narrator, h.source, h.explanation, names[h.surah] ?? '']))
                .toList();

            return TabBarView(
              children: [
                _list(
                  ayatList.length,
                  (i) {
                    final (surah, ayat) = ayatList[i];
                    return AyatPreviewCard(
                      key: ValueKey(ayatKey(surah, ayat)),
                      surah: surah,
                      ayat: ayat,
                      label: label(surah, '$surah:$ayat'),
                      tags: study.tagsFor(surah, ayat),
                      selectedTags: _selectedTags,
                      onTagTap: _toggleTag,
                    );
                  },
                  emptyMessage: hasTags
                      ? 'Tidak ada ayat yang cocok dengan filter.'
                      : 'Belum ada ayat yang diberi tema. Buka sebuah ayat lalu tekan "Atur tema".',
                ),
                _list(
                  histories.length,
                  (i) {
                    final h = histories[i];
                    return _KajianCard(
                      overline: label(h.surah, h.rangeLabel),
                      title: h.title,
                      body: h.content,
                      footer: h.period,
                      isUser: h.isUser,
                      onTap: () => _open(h.surah, h.fromAyat),
                    );
                  },
                ),
                _list(
                  hadiths.length,
                  (i) {
                    final h = hadiths[i];
                    return _KajianCard(
                      overline: label(h.surah, '${h.surah}:${h.ayat}'),
                      title: h.source,
                      body: h.translation,
                      footer: 'Perawi: ${h.narrator}',
                      grade: h.grade,
                      isUser: h.isUser,
                      onTap: () => _open(h.surah, h.ayat),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tagFilterBar(List<(String, int)> allTags) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          if (_selectedTags.isNotEmpty) ...[
            ActionChip(
              avatar: const Icon(Icons.close, size: 18),
              label: const Text('Hapus filter'),
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(_selectedTags.clear),
            ),
            const SizedBox(width: 8),
          ],
          for (final (tag, count) in allTags) ...[
            FilterChip(
              label: Text('$tag ($count)'),
              selected: _selectedTags.contains(tag),
              visualDensity: VisualDensity.compact,
              onSelected: (_) => _toggleTag(tag),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _list(int count, Widget Function(int) builder,
      {String emptyMessage = 'Tidak ada kajian yang cocok.'}) {
    if (count == 0) {
      return EmptyState(icon: Icons.search_off, message: emptyMessage);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => builder(i),
    );
  }
}

class _KajianCard extends StatelessWidget {
  final String overline;
  final String title;
  final String body;
  final String footer;
  final HadithGrade? grade;
  final bool isUser;
  final VoidCallback onTap;

  const _KajianCard({
    required this.overline,
    required this.title,
    required this.body,
    required this.footer,
    this.grade,
    required this.isUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      overline,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  if (isUser) const Icon(Icons.edit_note, size: 18),
                  if (grade != null) ...[const SizedBox(width: 6), GradeChip(grade!)],
                ],
              ),
              const SizedBox(height: 6),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
              if (footer.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(footer, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
