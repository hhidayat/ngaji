import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngaji/widgets/common.dart';

void main() {
  // Di halaman ayat, header yang tinggi bisa menyisakan ruang sangat sempit
  // untuk isi tab; pesan kosong dan error tidak boleh overflow di sana.
  testWidgets('EmptyState dan ErrorRetry tidak overflow di ruang sempit', (tester) async {
    for (final widget in [
      const EmptyState(
        icon: Icons.history_edu,
        message: 'Belum ada catatan sejarah atau asbabun nuzul untuk ayat ini.\n'
            'Lihat tab Tafsir, atau tulis catatan sejarah Anda sendiri.',
      ),
      ErrorRetry(error: 'koneksi terputus', onRetry: () {}),
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(height: 60, child: widget),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
