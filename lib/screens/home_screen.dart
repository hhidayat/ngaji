import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quran.dart';
import '../theme.dart';
import '../widgets/about.dart';
import '../widgets/ayat_preview.dart';
import '../widgets/common.dart';
import '../widgets/settings_sheet.dart';
import 'ayat_screen.dart';
import 'hadith_library.dart';
import 'kajian_tab.dart';
import 'surah_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [QuranHomeTab(), HadithLibraryTab(), KajianTab(), BookmarksTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: "Al-Qur'an"),
          NavigationDestination(icon: Icon(Icons.format_quote_outlined), selectedIcon: Icon(Icons.format_quote), label: 'Hadist'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Kajian'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Penanda'),
        ],
      ),
    );
  }
}

/// Beranda: sapaan, lanjutkan membaca, ayat pilihan, tema, dan daftar surat.
class QuranHomeTab extends StatefulWidget {
  const QuranHomeTab({super.key});

  @override
  State<QuranHomeTab> createState() => _QuranHomeTabState();
}

class _QuranHomeTabState extends State<QuranHomeTab> {
  Future<List<Surah>>? _future;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).api.surahs();
  }

  bool _matches(Surah s) {
    if (_query.isEmpty) return true;
    final normalized = _query.replaceAll(RegExp(r"[-' ]"), '');
    return '${s.number}' == _query ||
        s.latinName.toLowerCase().replaceAll(RegExp(r"[-' ]"), '').contains(normalized) ||
        s.meaning.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final study = AppScope.of(context).study;
    final studied = study.studiedAyat;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final featured = studied.isEmpty ? null : studied[dayOfYear % studied.length];
    final tags = study.allTags.take(8).toList();

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        final surahs = snapshot.data;
        final filtered = surahs?.where(_matches).toList() ?? const <Surah>[];
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HomeHero(surahs: surahs)),
            if (_query.isEmpty && featured != null) ...[
              const SliverToBoxAdapter(child: SectionHeader('Ayat pilihan hari ini')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: AyatPreviewCard(
                    key: ValueKey(featured),
                    surah: featured.$1,
                    ayat: featured.$2,
                  ),
                ),
              ),
            ],
            if (_query.isEmpty && tags.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  'Jelajahi tema',
                  actionLabel: 'Lihat semua',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KajianTab()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tags.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ActionChip(
                      avatar: const Icon(Icons.sell_outlined, size: 16),
                      label: Text('${tags[i].$1} (${tags[i].$2})'),
                      onPressed: () => openKajianForTag(context, tags[i].$1),
                    ),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SectionHeader('Daftar surat')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchBar(
                  hintText: 'Cari surat: nama, arti, atau nomor',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
            ),
            if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorRetry(
                  error: snapshot.error!,
                  onRetry: () => setState(() => _future = AppScope.of(context).api.surahs()),
                ),
              )
            else if (surahs == null)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: EmptyState(icon: Icons.search_off, message: 'Surat tidak ditemukan.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _SurahTile(surah: filtered[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomeHero extends StatelessWidget {
  final List<Surah>? surahs;

  const _HomeHero({required this.surahs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastRead = AppScope.of(context).prefs.lastRead;
    final lastSurah = lastRead == null
        ? null
        : surahs?.where((s) => s.number == lastRead.$1).firstOrNull;
    final fatihah = surahs?.firstOrNull;

    VoidCallback? onContinue;
    if (lastRead != null) {
      onContinue = () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AyatScreen(surahNumber: lastRead.$1, ayatNumber: lastRead.$2),
          ));
    } else if (fatihah != null) {
      onContinue = () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SurahScreen(surah: fatihah),
          ));
    }

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Assalamu'alaikum",
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Pengaturan tampilan',
                  color: Colors.white,
                  icon: const Icon(Icons.text_fields),
                  onPressed: () => showSettingsSheet(context),
                ),
                IconButton(
                  tooltip: 'Tentang aplikasi',
                  color: Colors.white,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showAppAbout(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                "Mari membaca dan memahami Al-Qur'an hari ini.",
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories, color: AppColors.gold, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastRead == null ? 'Belum ada bacaan' : 'Terakhir dibaca',
                          style: theme.textTheme.labelMedium?.copyWith(color: AppColors.gold),
                        ),
                        Text(
                          lastRead == null
                              ? 'Mulai dari Al-Fatihah'
                              : '${lastSurah?.latinName ?? 'Surat ${lastRead.$1}'} · Ayat ${lastRead.$2}',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.tealDark,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: onContinue,
                    child: Text(lastRead == null ? 'Mulai' : 'Lanjutkan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;

  const _SurahTile({required this.surah});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = surah;
    final makkiyah = s.revelationPlace.toLowerCase().contains('mek');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: NumberBadge(s.number, size: 44),
      title: Text(s.latinName, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${s.meaning} · ${s.ayatCount} ayat · ${makkiyah ? 'Makkiyah' : 'Madaniyah'}'),
      trailing: ArabicText(s.name, size: 22, scalable: false, color: theme.colorScheme.primary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SurahScreen(surah: s)),
      ),
    );
  }
}

class BookmarksTab extends StatelessWidget {
  const BookmarksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final study = AppScope.of(context).study;
    final bookmarks = study.bookmarks;
    return Scaffold(
      appBar: AppBar(title: const Text('Penanda Ayat')),
      body: bookmarks.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_outline,
              message: 'Belum ada ayat yang ditandai.\n'
                  'Ketuk ikon penanda di samping ayat untuk menyimpannya di sini.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookmarks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final (surah, ayat) = bookmarks[i];
                return AyatPreviewCard(
                  key: ValueKey('$surah:$ayat'),
                  surah: surah,
                  ayat: ayat,
                  trailing: IconButton(
                    tooltip: 'Hapus penanda',
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    onPressed: () => study.toggleBookmark(ayatKey(surah, ayat)),
                  ),
                );
              },
            ),
    );
  }
}
