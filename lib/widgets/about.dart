import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_scope.dart';

const privacyPolicyUrl = 'https://hhidayat.github.io/ngaji/privacy-policy.html';

Future<void> showAppAbout(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  final theme = Theme.of(context);
  final contentVersion = AppScope.of(context).study.contentVersion;
  showAboutDialog(
    context: context,
    applicationName: 'Ngaji',
    applicationVersion: 'Versi ${info.version} · konten kajian v$contentVersion',
    applicationIcon: Image.asset('assets/branding/icon_192.png', width: 48, height: 48),
    children: [
      const Text(
        "Membaca Al-Qur'an sambil memperdalam sejarah turunnya ayat, "
        'hadist-hadist yang menjelaskannya, dan tema pembahasan.',
      ),
      const SizedBox(height: 16),
      Text('Sumber data', style: theme.textTheme.titleSmall),
      const Text(
        "• Teks Al-Qur'an, terjemahan dan Tafsir Kemenag RI melalui API equran.id\n"
        '• Kumpulan hadist (Arab & Indonesia) dari proyek terbuka hadith-api '
        '(fawazahmed0) melalui jsDelivr\n'
        '• Sejarah ayat dan hadist bawaan dihimpun dari kitab-kitab hadist dan tafsir '
        'yang disebutkan pada masing-masing kajian',
      ),
      const SizedBox(height: 16),
      Text('Catatan', style: theme.textTheme.titleSmall),
      const Text(
        'Kajian dalam aplikasi ini adalah ringkasan untuk membantu belajar. Untuk '
        'pendalaman dan fatwa, rujuklah kitab aslinya dan bimbingan guru/ustadz. '
        'Catatan yang Anda tulis sendiri hanya tersimpan di perangkat ini.',
      ),
      const SizedBox(height: 16),
      Text('Kebijakan privasi', style: theme.textTheme.titleSmall),
      const SelectableText(privacyPolicyUrl),
    ],
  );
}
