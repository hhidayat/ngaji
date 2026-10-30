import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quran.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/settings_sheet.dart';
import 'ayat_screen.dart';
import 'kajian_tab.dart';

class SurahScreen extends StatefulWidget {
  final Surah surah;

  const SurahScreen({super.key, required this.surah});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  Future<SurahDetail>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null) {
      final scope = AppScope.of(context);
      _future = scope.api.surah(widget.surah.number);
      // Membuka surat lain memindahkan posisi "terakhir dibaca" ke awal surat itu.
      if (scope.prefs.lastRead?.$1 != widget.surah.number) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => scope.prefs.setLastRead(widget.surah.number, 1),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    return Scaffold(
      appBar: AppBar(
        title: Text(surah.latinName),
        actions: [
          IconButton(
            tooltip: 'Pengaturan tampilan',
            icon: const Icon(Icons.text_fields),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetry(
              error: snapshot.error!,
              onRetry: () => setState(() => _future = AppScope.of(context).api.surah(surah.number)),
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final ayatList = snapshot.data!.ayatList;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: ayatList.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => i == 0
                ? _SurahHeader(surah: surah)
                : _AyatCard(surah: surah, ayat: ayatList[i - 1]),
          );
        },
      ),
    );
  }
}

class _SurahHeader extends StatefulWidget {
  final Surah surah;

  const _SurahHeader({required this.surah});

  @override
  State<_SurahHeader> createState() => _SurahHeaderState();
}

class _SurahHeaderState extends State<_SurahHeader> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.surah;
    final makkiyah = s.revelationPlace.toLowerCase().contains('mek');
    const onHero = Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ArabicText(s.name, size: 36, scalable: false, color: AppColors.gold, textAlign: TextAlign.center),
          Text(s.latinName, style: theme.textTheme.headlineSmall?.copyWith(color: onHero, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '${s.meaning} · ${s.ayatCount} ayat · ${makkiyah ? 'Makkiyah (turun di Mekah)' : 'Madaniyah (turun di Madinah)'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.85)),
          ),
          if (s.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Text(
                s.description,
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.9), height: 1.5),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(_expanded ? 'Ringkas' : 'Tentang surat ini'),
            ),
          ] else
            const SizedBox(height: 8),
          if (s.number != 1 && s.number != 9)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ArabicText(
                'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                size: 26,
                color: onHero,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _AyatCard extends StatelessWidget {
  final Surah surah;
  final Ayat ayat;

  const _AyatCard({required this.surah, required this.ayat});

  void _open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AyatScreen(surahNumber: ayat.surah, ayatNumber: ayat.number),
      ));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final study = AppScope.of(context).study;
    final history = study.historyFor(ayat.surah, ayat.number);
    final hadithCount = study.hadithsFor(ayat.surah, ayat.number).length;
    final tags = study.tagsFor(ayat.surah, ayat.number);
    final bookmarked = study.isBookmarked(ayat.key);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NumberBadge(ayat.number),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Salin ayat',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () => copyAyat(context, ayat, surah.latinName),
                  ),
                  IconButton(
                    tooltip: bookmarked ? 'Hapus penanda' : 'Tandai ayat',
                    icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_outline),
                    color: bookmarked ? theme.colorScheme.secondary : null,
                    onPressed: () => study.toggleBookmark(ayat.key),
                  ),
                ],
              ),
              ArabicText(ayat.arabic),
              const SizedBox(height: 8),
              LatinText(ayat.latin),
              TranslationText(ayat.translation),
              if (history != null || hadithCount > 0 || tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (history != null)
                      const StudyIndicator(icon: Icons.history_edu, label: 'Ada kisah turunnya'),
                    if (hadithCount > 0)
                      StudyIndicator(icon: Icons.format_quote, label: '$hadithCount hadist'),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  TagWrap(tags: tags, onTap: (tag) => openKajianForTag(context, tag)),
                ],
              ],
              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _open(context),
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text('Pelajari ayat ini'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
