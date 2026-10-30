import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme.dart';

/// Pengenalan singkat yang tampil sekali saat aplikasi pertama dibuka.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _items = [
    (
      icon: null,
      title: 'Ahlan wa sahlan di Ngaji',
      body: "Teman belajar Al-Qur'an yang memudahkan Anda memahami setiap ayat, "
          'bukan hanya membacanya.',
    ),
    (
      icon: Icons.menu_book_rounded,
      title: "Baca Al-Qur'an dengan nyaman",
      body: 'Teks Arab, cara baca latin, terjemahan, dan tafsir Kemenag. '
          'Ukuran huruf bisa diperbesar, dan surat yang pernah dibuka bisa dibaca tanpa internet.',
    ),
    (
      icon: Icons.history_edu_rounded,
      title: 'Kenali kisah dan hadistnya',
      body: 'Ketuk sebuah ayat untuk melihat kisah turunnya ayat, hadist-hadist yang '
          'menjelaskannya, dan tafsirnya.',
    ),
    (
      icon: Icons.sell_rounded,
      title: 'Belajar per tema',
      body: 'Temukan ayat-ayat dengan tema yang sama, seperti Shalat, Puasa, atau Akhlak, '
          'lalu simpan catatan kajian Anda sendiri.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => AppScope.of(context).prefs.finishOnboarding();

  @override
  Widget build(BuildContext context) {
    final last = _index == _items.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Lewati'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _items.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _Page(item: _items[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.gold : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.tealDark,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: last
                        ? _finish
                        : () => _pages.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                    child: Text(last ? 'Mulai Belajar' : 'Lanjut'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final ({IconData? icon, String title, String body}) item;

  const _Page({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (item.icon == null)
            ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Image.asset('assets/branding/icon_192.png', width: 140, height: 140),
            )
          else
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 72, color: AppColors.gold),
            ),
          const SizedBox(height: 40),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            item.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.6),
          ),
        ],
      ),
    );
  }
}
