import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quran.dart';
import '../models/study.dart';
import '../widgets/common.dart';
import '../widgets/settings_sheet.dart';
import 'forms.dart';
import 'kajian_tab.dart';

/// Halaman kajian satu ayat: sejarah, hadist-hadist penjelas, dan tafsir.
class AyatScreen extends StatefulWidget {
  final int surahNumber;
  final int ayatNumber;

  const AyatScreen({super.key, required this.surahNumber, required this.ayatNumber});

  @override
  State<AyatScreen> createState() => _AyatScreenState();
}

class _AyatScreenState extends State<AyatScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(() => setState(() {}));
  late int _ayat = widget.ayatNumber;
  Future<SurahDetail>? _detail;
  Future<Map<int, String>>? _tafsir;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detail ??= AppScope.of(context).api.surah(widget.surahNumber);
    _tafsir ??= AppScope.of(context).api.tafsir(widget.surahNumber);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _retry() {
    final api = AppScope.of(context).api;
    setState(() {
      _detail = api.surah(widget.surahNumber);
      _tafsir = api.tafsir(widget.surahNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(), body: ErrorRetry(error: snapshot.error!, onRetry: _retry));
        }
        if (!snapshot.hasData) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        final detail = snapshot.data!;
        return _buildAyat(detail, detail.ayatList[_ayat - 1]);
      },
    );
  }

  Widget _buildAyat(SurahDetail detail, Ayat ayat) {
    final study = AppScope.of(context).study;
    final history = study.historyFor(ayat.surah, ayat.number);
    final hadiths = study.hadithsFor(ayat.surah, ayat.number);
    final bookmarked = study.isBookmarked(ayat.key);
    final prefs = AppScope.of(context).prefs;
    if (prefs.lastRead != (ayat.surah, ayat.number)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => prefs.setLastRead(ayat.surah, ayat.number));
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.surah.latinName),
                Text(
                  'Ayat ${ayat.number} dari ${detail.ayatList.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Pengaturan tampilan',
                icon: const Icon(Icons.text_fields),
                onPressed: () => showSettingsSheet(context),
              ),
              IconButton(
                tooltip: 'Salin ayat',
                icon: const Icon(Icons.copy_outlined),
                onPressed: () => copyAyat(context, ayat, detail.surah.latinName),
              ),
              IconButton(
                tooltip: bookmarked ? 'Hapus penanda' : 'Tandai ayat',
                icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_outline),
                color: bookmarked ? Theme.of(context).colorScheme.secondary : null,
                onPressed: () => study.toggleBookmark(ayat.key),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _AyatHeader(ayat: ayat)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                tabs: [
                  const Tab(icon: Icon(Icons.history_edu), text: 'Sejarah'),
                  Tab(icon: const Icon(Icons.format_quote), text: 'Hadist (${hadiths.length})'),
                  const Tab(icon: Icon(Icons.auto_stories), text: 'Tafsir'),
                ],
              ),
              Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _HistoryTab(ayat: ayat, history: history),
            _HadithTab(ayat: ayat, hadiths: hadiths),
            _TafsirTab(future: _tafsir!, ayat: ayat.number, onRetry: _retry),
          ],
        ),
      ),
      floatingActionButton: switch (_tabs.index) {
        0 => FloatingActionButton.extended(
            icon: Icon(history == null ? Icons.add : Icons.edit),
            label: Text(history == null ? 'Tulis sejarah' : 'Edit sejarah'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => HistoryForm(surah: ayat.surah, ayat: ayat.number, existing: history),
            )),
          ),
        1 => FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Tambah hadist'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => HadithForm(surah: ayat.surah, ayat: ayat.number),
            )),
          ),
        _ => null,
      },
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _ayat > 1 ? () => setState(() => _ayat--) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Sebelumnya'),
            ),
            const Spacer(),
            Text('${ayat.number} / ${detail.ayatList.length}'),
            const Spacer(),
            TextButton.icon(
              onPressed: _ayat < detail.ayatList.length ? () => setState(() => _ayat++) : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Berikutnya'),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ),
    );
  }
}

class _AyatHeader extends StatelessWidget {
  final Ayat ayat;

  const _AyatHeader({required this.ayat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = AppScope.of(context).study.tagsFor(ayat.surah, ayat.number);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArabicText(ayat.arabic, size: 30),
          const SizedBox(height: 8),
          LatinText(ayat.latin),
          TranslationText(ayat.translation),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: tags.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Belum ada tema untuk ayat ini.', style: theme.textTheme.bodySmall),
                      )
                    : TagWrap(tags: tags, onTap: (tag) => openKajianForTag(context, tag)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: const Text('Atur tema'),
                onPressed: () => showTagEditor(context, ayat.surah, ayat.number),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color background;

  _TabBarDelegate(this.tabBar, this.background);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: background, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar || old.background != background;
}

class _HistoryTab extends StatelessWidget {
  final Ayat ayat;
  final AyatHistory? history;

  const _HistoryTab({required this.ayat, required this.history});

  @override
  Widget build(BuildContext context) {
    final h = history;
    if (h == null) {
      return const EmptyState(
        icon: Icons.history_edu,
        message: 'Belum ada catatan sejarah atau asbabun nuzul untuk ayat ini.\n'
            'Lihat tab Tafsir, atau tulis catatan sejarah Anda sendiri.',
      );
    }
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(h.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('QS ${h.rangeLabel}'), visualDensity: VisualDensity.compact),
            if (h.period.isNotEmpty)
              Chip(label: Text(h.period), visualDensity: VisualDensity.compact),
            if (h.isUser)
              const Chip(
                avatar: Icon(Icons.edit_note, size: 18),
                label: Text('Catatan saya'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(h.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
        if (h.sources.isNotEmpty) ...[
          const Divider(height: 32),
          Text('Sumber', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(h.sources, style: theme.textTheme.bodySmall),
        ],
        if (h.isUser) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus catatan saya'),
              onPressed: () async {
                if (await confirmDelete(context, 'catatan sejarah ini')) {
                  if (!context.mounted) return;
                  await AppScope.of(context).study.deleteHistory(h);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _HadithTab extends StatelessWidget {
  final Ayat ayat;
  final List<Hadith> hadiths;

  const _HadithTab({required this.ayat, required this.hadiths});

  @override
  Widget build(BuildContext context) {
    if (hadiths.isEmpty) {
      return const EmptyState(
        icon: Icons.format_quote,
        message: 'Belum ada hadist yang dikaitkan dengan ayat ini.\n'
            'Tambahkan hadist yang menjelaskan ayat ini.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: hadiths.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => HadithCard(hadith: hadiths[i]),
    );
  }
}

class HadithCard extends StatelessWidget {
  final Hadith hadith;

  const HadithCard({super.key, required this.hadith});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = hadith;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(h.source, style: theme.textTheme.titleSmall)),
                GradeChip(h.grade),
                if (h.isUser)
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      final study = AppScope.of(context).study;
                      if (action == 'edit') {
                        Navigator.of(context).push(MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => HadithForm(surah: h.surah, ayat: h.ayat, existing: h),
                        ));
                      } else if (await confirmDelete(context, 'hadist ini')) {
                        await study.deleteHadith(h);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
            if (h.narrator.isNotEmpty)
              Text('Perawi: ${h.narrator}', style: theme.textTheme.bodySmall),
            if (h.arabic.isNotEmpty) ...[
              const SizedBox(height: 12),
              ArabicText(h.arabic, size: 24),
            ],
            const SizedBox(height: 12),
            Text(h.translation, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
            if (h.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(h.explanation)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TafsirTab extends StatelessWidget {
  final Future<Map<int, String>> future;
  final int ayat;
  final VoidCallback onRetry;

  const _TafsirTab({required this.future, required this.ayat, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorRetry(error: snapshot.error!, onRetry: onRetry);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final text = snapshot.data![ayat];
        if (text == null || text.isEmpty) {
          return const EmptyState(icon: Icons.auto_stories, message: 'Tafsir tidak tersedia.');
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Tafsir Kemenag RI', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SelectableText(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
          ],
        );
      },
    );
  }
}
