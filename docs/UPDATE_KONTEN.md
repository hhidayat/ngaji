# Cara Memperbarui Konten Kajian

Sejarah ayat, hadist penjelas, dan tema bawaan aplikasi ada di satu file:
**`assets/data/kajian.json`** di repo GitHub `hhidayat/ngaji`.

Setiap kali pengguna membuka aplikasi, aplikasi mengunduh file ini dari GitHub.
Jadi **cukup edit file tersebut di GitHub**, tanpa build atau rilis aplikasi baru.

> Teks Al-Qur'an, terjemahan, tafsir, dan kitab hadist di menu *Hadist* berasal
> dari sumber lain (equran.id dan hadith-api) dan tidak diubah lewat file ini.

## Alur singkat

1. Buka `https://github.com/hhidayat/ngaji/blob/main/assets/data/kajian.json`
2. Klik ikon pensil (**Edit this file**). Bisa dari browser HP.
3. Ubah isinya (lihat contoh di bawah), lalu **naikkan `"version"`**, mis. `1` → `2`.
4. Klik **Commit changes**.
5. Tunggu centang hijau ✅ di tab **Actions** (± 2 menit). Jika muncul ❌, buka
   detailnya: pesan error menyebut baris yang salah. Perbaiki dan commit lagi.
6. Selesai. Pengguna mendapat konten baru saat **membuka aplikasi berikutnya**
   (GitHub bisa menyimpan cache hingga ± 5 menit).

Versi konten yang sedang dipakai aplikasi terlihat di **ⓘ Tentang aplikasi**
("konten kajian vN").

**Aman dari salah ketik:** bila file tidak valid, aplikasi mengabaikannya dan tetap
memakai konten terakhir yang benar, jadi tidak akan crash. Namun pembaruan
baru sampai ke pengguna setelah file diperbaiki.

## Struktur file

```json
{
  "schema": 1,
  "version": 2,
  "tags": { ... },
  "histories": [ ... ],
  "hadiths": [ ... ]
}
```

- `schema`: **jangan diubah** (format file; hanya diubah oleh pengembang).
- `version`: naikkan setiap kali ada perubahan.

### Menambah tema ayat (`tags`)

Kunci = `"surat:ayat"`, isi = daftar tema.

```json
"tags": {
  "2:255": ["Tauhid", "Asmaul Husna", "Keutamaan", "Dzikir"],
  "2:153": ["Sabar", "Shalat"]
}
```

Gunakan penulisan tema yang sama persis dengan yang sudah ada (mis. `"Tauhid"`,
bukan `"tauhid"`) agar terkumpul dalam satu tema.

### Menambah sejarah ayat (`histories`)

Satu sejarah boleh berlaku untuk rentang ayat (`from`–`to`). Untuk satu ayat,
isi `from` dan `to` dengan nomor yang sama.

```json
{
  "surah": 2, "from": 153, "to": 153,
  "title": "Judul singkat peristiwa",
  "period": "Madaniyah · Tahun ke-2 Hijriyah",
  "content": "Kisah lengkapnya.\n\nGunakan \\n\\n untuk paragraf baru.",
  "sources": "Shahih Al-Bukhari no. ...; Tafsir Ibnu Katsir"
}
```

`title` dan `content` wajib diisi; `period` dan `sources` boleh kosong.

### Menambah hadist penjelas (`hadiths`)

```json
{
  "id": "seed-2-153-a",
  "surah": 2, "ayat": 153,
  "arabic": "teks Arab (boleh kosong)",
  "translation": "Terjemahan hadist.",
  "narrator": "Nama sahabat perawi",
  "source": "HR. Al-Bukhari no. 1234",
  "grade": "shahih",
  "explanation": "Kaitan hadist dengan ayat (boleh kosong)."
}
```

- `id` harus **unik**. Pola yang dipakai: `seed-<surat>-<ayat>-<huruf>`, mis.
  hadist kedua untuk 2:153 → `seed-2-153-b`.
- `grade`: salah satu dari `shahih`, `hasan`, `dhaif`, `unknown`.
- `translation` dan `source` wajib diisi.
- Untuk Shahih Muslim, gunakan penomoran Fuad Abdul Baqi (sama dengan yang
  ditampilkan di menu *Hadist* aplikasi).

## Kesalahan yang sering terjadi

| Gejala di Actions | Penyebab |
|---|---|
| `JSON tidak valid` | Koma kurang/lebih (mis. koma setelah elemen terakhir), tanda kutip tidak ditutup. Tanda kutip di dalam teks harus ditulis `\"`. |
| `id hadist "..." dipakai lebih dari sekali` | Dua hadist memakai `id` yang sama. |
| `Kunci tema "..." harus berformat surat:ayat` | Menulis `"2-255"` atau `"QS 2:255"`; yang benar `"2:255"`. |
| `... wajib diisi` | Ada isian wajib yang kosong. |

Tip: sebelum commit, tempel isi file ke <https://jsonlint.com> untuk mengecek format JSON.

## Bagaimana dengan rilis aplikasi berikutnya?

File yang sama ikut dibundel ke aplikasi saat build, sehingga pengguna baru
langsung mendapat konten terbaru walaupun pertama kali dibuka tanpa internet.
Tidak perlu langkah tambahan.
