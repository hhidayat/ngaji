import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quran.dart';
import '../screens/ayat_screen.dart';
import 'common.dart';

/// Kartu ringkas sebuah ayat: teks Arab, terjemahan, dan penanda kajian.
/// Teks ayat dimuat dari API (atau cache) saat kartu ditampilkan.
class AyatPreviewCard extends StatefulWidget {
  final int surah;
  final int ayat;

  /// Teks di atas kartu, misalnya "Al-Baqarah · 2:255". Bila null, nama surat
  /// dimuat otomatis.
  final String? label;
  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String>? onTagTap;
  final Widget? trailing;

  const AyatPreviewCard({
    super.key,
    required this.surah,
    required this.ayat,
    this.label,
    this.tags = const [],
    this.selectedTags = const {},
    this.onTagTap,
    this.trailing,
  });

  @override
  State<AyatPreviewCard> createState() => _AyatPreviewCardState();
}

class _AyatPreviewCardState extends State<AyatPreviewCard> {
  Future<SurahDetail>? _detail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detail ??= AppScope.of(context).api.surah(widget.surah);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final study = AppScope.of(context).study;
    final hasHistory = study.historyFor(widget.surah, widget.ayat) != null;
    final hadithCount = study.hadithsFor(widget.surah, widget.ayat).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AyatScreen(surahNumber: widget.surah, ayatNumber: widget.ayat),
        )),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: FutureBuilder(
            future: _detail,
            builder: (context, snapshot) {
              final detail = snapshot.data;
              final ayat = detail != null && widget.ayat <= detail.ayatList.length
                  ? detail.ayatList[widget.ayat - 1]
                  : null;
              final label = widget.label ??
                  (detail == null
                      ? 'QS ${widget.surah}:${widget.ayat}'
                      : '${detail.surah.latinName} · ayat ${widget.ayat}');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                      ?widget.trailing,
                    ],
                  ),
                  // Jarak agar tanda waqaf di atas huruf Arab tidak menimpa label.
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ayat == null
                        ? const SizedBox(height: 24)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ArabicText(ayat.arabic, size: 24, maxLines: 2),
                              TranslationText(ayat.translation, maxLines: 3),
                            ],
                          ),
                  ),
                  if (hasHistory || hadithCount > 0) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (hasHistory)
                          const StudyIndicator(icon: Icons.history_edu, label: 'Ada kisah turunnya'),
                        if (hadithCount > 0)
                          StudyIndicator(icon: Icons.format_quote, label: '$hadithCount hadist'),
                      ],
                    ),
                  ],
                  if (widget.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TagWrap(
                      tags: widget.tags,
                      selected: widget.selectedTags,
                      onTap: widget.onTagTap ?? (_) {},
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
