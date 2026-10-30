import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_scope.dart';
import '../models/quran.dart';
import '../models/study.dart';

/// Teks Arab berfont Amiri. Ukurannya mengikuti pengaturan pengguna kecuali
/// [scalable] false (misalnya nama surat di daftar).
class ArabicText extends StatelessWidget {
  final String text;
  final double size;
  final bool scalable;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;

  const ArabicText(
    this.text, {
    super.key,
    this.size = 28,
    this.scalable = true,
    this.color,
    this.textAlign = TextAlign.right,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final scale = scalable ? AppScope.maybeOf(context)?.prefs.arabicScale ?? 1 : 1;
    return Text(
      text,
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: GoogleFonts.amiri(
        fontSize: size * scale,
        height: 2,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Transliterasi latin; disembunyikan bila pengguna mematikannya.
class LatinText extends StatelessWidget {
  final String text;

  const LatinText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.maybeOf(context)?.prefs;
    if (prefs != null && !prefs.showLatin) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.primary,
          fontSize: 14 * (prefs?.translationScale ?? 1),
        ),
      ),
    );
  }
}

/// Terjemahan ayat dengan ukuran yang mengikuti pengaturan pengguna.
class TranslationText extends StatelessWidget {
  final String text;
  final int? maxLines;

  const TranslationText(this.text, {super.key, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final scale = AppScope.maybeOf(context)?.prefs.translationScale ?? 1;
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16 * scale, height: 1.55),
    );
  }
}

/// Nomor ayat/surat di dalam bingkai bintang delapan (rub el hizb),
/// senada dengan logo aplikasi.
class NumberBadge extends StatelessWidget {
  final int number;
  final double size;

  const NumberBadge(this.number, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final digits = '$number'.length;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StarPainter(fill: scheme.primaryContainer, stroke: scheme.primary),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: size * (digits >= 3 ? 0.27 : 0.32),
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color fill;
  final Color stroke;

  _StarPainter({required this.fill, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2 - 1;
    final inner = outer * math.cos(math.pi / 4) / math.cos(math.pi / 8);
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 8;
      final p = c + Offset(r * math.cos(a), r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.fill != fill || old.stroke != stroke;
}

/// Judul bagian dengan tautan aksi opsional di kanan.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class GradeChip extends StatelessWidget {
  final HadithGrade grade;

  const GradeChip(this.grade, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (grade) {
      HadithGrade.shahih => (scheme.primaryContainer, scheme.onPrimaryContainer),
      HadithGrade.hasan => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      HadithGrade.dhaif => (scheme.errorContainer, scheme.onErrorContainer),
      HadithGrade.unknown => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(grade.label, style: TextStyle(fontSize: 12, color: fg)),
    );
  }
}

/// Penanda kecil di kartu ayat yang menunjukkan ada sejarah / hadist.
class StudyIndicator extends StatelessWidget {
  final IconData icon;
  final String label;

  const StudyIndicator({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onTertiaryContainer)),
        ],
      ),
    );
  }
}

/// Menempatkan [child] di tengah bila ruangnya cukup, dan membuatnya bisa
/// di-scroll bila tidak, misalnya di bawah header ayat yang tinggi.
class ScrollableCenter extends StatelessWidget {
  final Widget child;

  const ScrollableCenter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorRetry({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ScrollableCenter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Tidak dapat memuat data. Periksa koneksi internet. '
              'Surat yang pernah dibuka tetap tersedia offline.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ScrollableCenter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Deretan tag pembahasan ayat. Tag yang ada di [selected] disorot.
class TagWrap extends StatelessWidget {
  final List<String> tags;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  const TagWrap({super.key, required this.tags, this.selected = const {}, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          ActionChip(
            avatar: Icon(Icons.sell_outlined, size: 14, color: scheme.secondary),
            label: Text(tag),
            labelStyle: const TextStyle(fontSize: 12),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: selected.contains(tag) ? scheme.secondaryContainer : null,
            onPressed: () => onTap(tag),
          ),
      ],
    );
  }
}

/// Menyalin ayat (Arab, terjemahan, dan rujukan) agar mudah dibagikan.
void copyAyat(BuildContext context, Ayat ayat, String surahName) {
  Clipboard.setData(ClipboardData(
    text: '${ayat.arabic}\n\n"${ayat.translation}"\n\n(QS $surahName: ${ayat.number})',
  ));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Ayat disalin. Tempel di WhatsApp atau aplikasi lain.')),
  );
}

/// 7563 -> "7.563" (pemisah ribuan gaya Indonesia).
String formatThousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
