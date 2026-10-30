# Panduan Rilis Ngaji ke Google Play

## 1. Sebelum rilis pertama (sekali saja)

- [ ] **Verifikasi rujukan hadist & sejarah** di `assets/data/kajian.json` oleh ustadz / dengan kitab aslinya (nomor hadist, perawi, derajat).
- [ ] **Backup upload key** ke tempat aman (password manager + penyimpanan cloud pribadi):
  - `C:\Users\hafif\keystores\ngaji-upload-keystore.jks`
  - `android\key.properties` (berisi password)

  Jangan bagikan keduanya ke publik. Jika hilang, kunci upload bisa di-reset lewat Play Console (karena memakai Play App Signing), tetapi prosesnya butuh beberapa hari.
- [ ] **Hosting kebijakan privasi**: ganti `[EMAIL_KONTAK]` di `docs/privacy-policy.html`, lalu push project ke repo GitHub `hhidayat/ngaji` dan aktifkan GitHub Pages (Settings → Pages → Branch `main`, folder `/docs`). URL-nya akan menjadi
  `https://hhidayat.github.io/ngaji/privacy-policy.html` (URL ini juga ditampilkan di dialog *Tentang* aplikasi, lihat `lib/widgets/about.dart`).
- [ ] Buat akun Google Play Console (biaya pendaftaran sekali bayar USD 25).

## 2. Build

```bash
flutter test
flutter build appbundle --release
```

Hasil: `build/app/outputs/bundle/release/app-release.aab`. File inilah yang diunggah.

Untuk setiap update, naikkan versi di `pubspec.yaml`. Angka setelah `+` (versionCode) **wajib** selalu naik. Versi saat ini:

```yaml
version: 1.0.1+2   # update berikutnya: 1.0.2+3, dst.
```

## 3. Isian Play Console

### Detail aplikasi
| Kolom | Isi |
|---|---|
| Nama aplikasi | Ngaji: Al-Qur'an, Hadist & Sejarah |
| Kategori | Pendidikan (alternatif: Buku & Referensi) |
| Ikon | `assets/branding/playstore_512.png` |
| Gambar fitur | `assets/branding/feature_graphic.png` |
| Screenshot ponsel | `docs/store/screenshot_1.png` … `screenshot_7.png` (1080×1920, unggah sesuai urutan nomor) |

Screenshot mentah ada di `docs/store/raw/`. Untuk mengganti teks judul atau urutan, ubah `tool/store_screenshots.py` lalu jalankan `python tool/store_screenshots.py`. Untuk mengambil screenshot baru dari HP: `adb exec-out screencap -p > docs/store/raw/NAMA.png`.

**Deskripsi singkat** (maks. 80 karakter):

> Al-Qur'an dengan sejarah ayat, hadist penjelas, dan tag pembahasan.

**Deskripsi lengkap:**

> Ngaji membantu Anda memahami Al-Qur'an lebih dalam, ayat demi ayat.
>
> 📖 AL-QUR'AN LENGKAP
> • 114 surat dengan teks Arab, transliterasi latin, dan terjemahan bahasa Indonesia
> • Tafsir Kemenag RI untuk setiap ayat
> • Surat yang pernah dibuka bisa dibaca tanpa internet
>
> 🕰️ SEJARAH AYAT
> Kenali peristiwa di balik turunnya ayat (asbabun nuzul): kapan, di mana, dan dalam situasi apa ayat tersebut diturunkan, lengkap dengan sumber rujukannya.
>
> 📚 KUMPULAN HADIST
> Baca 7 kitab hadist (Shahih Al-Bukhari, Shahih Muslim, Sunan Abu Dawud, Jami' At-Tirmidzi, Sunan An-Nasa'i, Sunan Ibnu Majah, dan Al-Muwaththa') per bab, lengkap dengan teks Arab dan terjemahan Indonesia. Hadist dari kitab dapat langsung dikaitkan ke ayat yang dijelaskannya.
>
> 📜 HADIST PENJELAS
> Setiap ayat dapat memiliki banyak hadist yang menjelaskannya, lengkap dengan teks Arab, terjemahan, perawi, sumber kitab, dan derajat hadist.
>
> 🏷️ TAG PEMBAHASAN
> Ayat diberi tag sesuai topiknya, seperti Tauhid, Shalat, Puasa, Akhlak, atau Sirah Nabi. Ketuk sebuah tag untuk mempelajari semua ayat dengan tema yang sama, beserta sejarah dan hadistnya.
>
> ✍️ CATATAN KAJIAN PRIBADI
> Tulis sejarah, tambahkan hadist, dan kelola tag Anda sendiri dari kajian bersama guru atau dari bacaan kitab.
>
> 🔖 PENANDA AYAT
> Simpan ayat-ayat yang ingin Anda pelajari kembali.
>
> Tanpa iklan, tanpa akun, dan tanpa mengumpulkan data pribadi.

### Konten aplikasi (App content)
| Bagian | Jawaban |
|---|---|
| Kebijakan privasi | `https://hhidayat.github.io/ngaji/privacy-policy.html` |
| Akses aplikasi | Semua fitur tersedia tanpa login |
| Iklan | Tidak mengandung iklan |
| Rating konten | Isi kuesioner IARC: kategori *Referensi/Pendidikan*, jawab "Tidak" untuk kekerasan, seksual, judi, dll. Hasilnya biasanya *Semua Umur / 3+* |
| Target audiens | Pilih kelompok usia dengan jujur. Jika memilih di bawah 13 tahun, aplikasi masuk Program Keluarga dengan syarat tambahan; memilih **13+** paling sederhana untuk rilis pertama |
| Aplikasi berita / pemerintah / keuangan / kesehatan | Bukan |

### Keamanan data (Data safety)
| Pertanyaan | Jawaban |
|---|---|
| Apakah aplikasi mengumpulkan atau membagikan data pengguna? | **Tidak** |
| Alasan | Catatan, tag, dan penanda hanya disimpan di perangkat; permintaan ke equran.id dan jsDelivr hanya mengambil teks Al-Qur'an dan hadist, tanpa mengirim data pengguna |

## 4. Jalur rilis

Akun developer **pribadi** yang baru dibuat wajib menjalankan **pengujian tertutup (closed testing) dengan minimal 12 penguji selama 14 hari berturut-turut** sebelum boleh rilis ke Produksi. Urutannya:

1. Pengujian internal: unggah `.aab`, coba di HP sendiri.
2. Pengujian tertutup: undang ≥12 penguji (email Google mereka), tunggu 14 hari.
3. Ajukan akses Produksi, lalu rilis.

## 5. Mengganti ikon atau gambar fitur

Ubah `tool/generate_icon.py`, lalu jalankan `python tool/generate_icon.py` (butuh `pip install pillow`).

## 6. Memperbarui konten kajian tanpa rilis aplikasi

Sejarah, hadist penjelas, dan tema diambil aplikasi dari `assets/data/kajian.json` di repo GitHub `hhidayat/ngaji` setiap kali dibuka. Panduan lengkap untuk penyunting: [UPDATE_KONTEN.md](UPDATE_KONTEN.md).

Syarat: repo `hhidayat/ngaji` harus **publik** dan branch utamanya bernama `main` (alamatnya diatur di `lib/data/kajian_content.dart`).
