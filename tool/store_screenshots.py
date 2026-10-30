"""Membingkai screenshot HP menjadi gambar Play Store 1080x1920 berjudul.

Screenshot mentah (1080x2460 dari `adb exec-out screencap -p`) diletakkan di
docs/store/raw/. Hasilnya ditulis ke docs/store/. Rasio mentah 2,28:1 melebihi
batas Google Play (sisi terpanjang maks. 2x sisi terpendek), jadi screenshot
dipotong status bar & tombol navigasinya lalu ditempatkan di bawah judul.

Jalankan dari root project:  python tool/store_screenshots.py   (butuh Pillow)
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "docs/store/raw"
OUT = ROOT / "docs/store"

W, H = 1080, 1920
TEAL_TOP, TEAL_BOTTOM = (19, 137, 127), (11, 79, 74)
GOLD = (244, 193, 82)

# (file mentah, judul, subjudul) dalam urutan tampil di Play Store.
SLIDES = [
    ("01_home", "Belajar Al-Qur'an\njadi lebih mudah", "Lanjutkan bacaan & ayat pilihan setiap hari"),
    ("02_surah", "Arab, latin &\nterjemahan", "Ukuran huruf bisa diperbesar sesuai kebutuhan"),
    ("03_ayat_sejarah", "Kenali sejarah\nturunnya ayat", "Asbabun nuzul lengkap dengan sumbernya"),
    ("04_ayat_hadist", "Hadist yang\nmenjelaskan ayat", "Lengkap dengan perawi dan derajatnya"),
    ("06_tema", "Pelajari ayat\nper tema", "Tauhid, Shalat, Puasa, Akhlak, dan lainnya"),
    ("08_kitab", "7 kitab hadist\npilihan", "Bukhari, Muslim, dan kitab-kitab Sunan"),
    ("05_hadith_bab", "Arab & terjemahan\nIndonesia", "Baca per bab, bisa dikaitkan ke ayat"),
]

STATUS_BAR, NAV_BAR = 108, 144  # piksel pada screenshot 1080x2460


def font(names, size):
    for name in names:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default(size)


TITLE = font(["segoeuib.ttf", "DejaVuSans-Bold.ttf"], 84)
SUBTITLE = font(["segoeui.ttf", "DejaVuSans.ttf"], 40)


def background():
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(TEAL_TOP, TEAL_BOTTOM)))
    return img


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius=radius, fill=255)
    img.putalpha(mask)
    return img


def slide(raw_name, title, subtitle):
    img = background()
    d = ImageDraw.Draw(img)
    d.multiline_text((W // 2, 120), title, font=TITLE, fill="white", anchor="ma", align="center", spacing=12)
    d.text((W // 2, 345), subtitle, font=SUBTITLE, fill=GOLD, anchor="ma")

    shot = Image.open(RAW / f"{raw_name}.png").convert("RGB")
    shot = shot.crop((0, STATUS_BAR, shot.width, shot.height - NAV_BAR))
    width = 860
    shot = shot.resize((width, round(shot.height * width / shot.width)), Image.LANCZOS)
    shot = rounded(shot, 44)

    x, y = (W - width) // 2, 450
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x, y + 16, x + width, y + shot.height + 16), radius=44, fill=(0, 0, 0, 90))
    img.paste(shadow.filter(ImageFilter.GaussianBlur(24)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(24)))
    img.paste(shot, (x, y), shot)
    return img


if __name__ == "__main__":
    for i, (raw, title, subtitle) in enumerate(SLIDES, 1):
        out = OUT / f"screenshot_{i}.png"
        slide(raw, title, subtitle).save(out)
        print("dibuat", out.relative_to(ROOT))
