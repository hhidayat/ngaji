import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_prefs.dart';
import 'common.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SettingsSheet(),
    );

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = AppScope.of(context).prefs;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pengaturan Tampilan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Contoh tampilan', style: theme.textTheme.labelMedium),
                    const ArabicText('بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ'),
                    const LatinText('Bismillāhir-raḥmānir-raḥīm(i).'),
                    const TranslationText('Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ScaleSlider(
              label: 'Ukuran huruf Arab',
              value: prefs.arabicScale,
              range: AppPrefs.arabicScaleRange,
              onChanged: (v) => prefs.arabicScale = v,
            ),
            _ScaleSlider(
              label: 'Ukuran terjemahan',
              value: prefs.translationScale,
              range: AppPrefs.translationScaleRange,
              onChanged: (v) => prefs.translationScale = v,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tampilkan tulisan latin'),
              subtitle: const Text('Cara baca ayat dalam huruf latin'),
              value: prefs.showLatin,
              onChanged: (v) => prefs.showLatin = v,
            ),
            const SizedBox(height: 8),
            Text('Tema', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Otomatis'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Terang'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Gelap'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {prefs.themeMode},
              onSelectionChanged: (s) => prefs.themeMode = s.first,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleSlider extends StatelessWidget {
  final String label;
  final double value;
  final (double, double) range;
  final ValueChanged<double> onChanged;

  const _ScaleSlider({
    required this.label,
    required this.value,
    required this.range,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
              Text('${(value * 100).round()}%'),
            ],
          ),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Slider(
                  value: value.clamp(range.$1, range.$2),
                  min: range.$1,
                  max: range.$2,
                  divisions: ((range.$2 - range.$1) * 20).round(),
                  onChanged: onChanged,
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }
}
