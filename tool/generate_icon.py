"""Membuat logo aplikasi Ngaji dari satu definisi bentuk.

Keluaran:
  - assets/branding/logo.svg                      sumber logo (vektor)
  - assets/branding/playstore_512.png             ikon untuk Google Play Console
  - assets/branding/icon_192.png                  ikon di dialog "Tentang" & layar pengenalan
  - assets/branding/feature_graphic.png           gambar fitur 1024x500 Google Play
  - android/.../drawable/ic_launcher_foreground.xml   adaptive icon (Android 8+)
  - android/.../drawable/ic_launcher_monochrome.xml   themed icon (Android 13+)
  - android/.../mipmap-*/ic_launcher.png              ikon untuk Android lama

Jalankan dari root project:  python tool/generate_icon.py   (butuh Pillow)

Semua koordinat memakai kanvas adaptive icon 108x108; isi penting berada
di dalam lingkaran aman berjari-jari 33 di tengah (54, 54).
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"

BG = "#0F766E"      # sama dengan seedColor tema aplikasi
GOLD = "#F4C152"
PAGE = "#FFFFFF"
LINE = "#9FD4CB"


def quad(p0, c, p1, steps=24):
    """Titik-titik kurva Bezier kuadratik dari p0 ke p1."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t ** 2 * p1[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t ** 2 * p1[1]
        pts.append((x, y))
    return pts


def mirror(points):
    return [(108 - x, y) for x, y in points]


def thick_line(a, b, width):
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy)
    nx, ny = -dy / length * width / 2, dx / length * width / 2
    return [(a[0] + nx, a[1] + ny), (b[0] + nx, b[1] + ny),
            (b[0] - nx, b[1] - ny), (a[0] - nx, a[1] - ny)]


def circle(cx, cy, r, steps=48):
    return [(cx + r * math.cos(2 * math.pi * i / steps),
             cy + r * math.sin(2 * math.pi * i / steps)) for i in range(steps)]


# --- Bentuk logo -----------------------------------------------------------

# Bintang rub el hizb: gabungan dua persegi, 16 titik bergantian luar/dalam.
STAR_C, STAR_R = (54, 34), 12.5
star = []
for i in range(16):
    r = STAR_R if i % 2 == 0 else STAR_R * math.cos(math.pi / 4) / math.cos(math.pi / 8)
    a = -math.pi / 2 + i * math.pi / 8
    star.append((STAR_C[0] + r * math.cos(a), STAR_C[1] + r * math.sin(a)))
star_hole = circle(*STAR_C, 3.2)

# Rehal (penyangga mushaf) berbentuk X; bagian atasnya tertutup halaman.
CROSS = (54, 79)
rehal = [
    thick_line((46.5, 85.5), (CROSS[0] + 7.5 * 2.6, CROSS[1] - 6.5 * 2.6), 3.6),
    thick_line((61.5, 85.5), (CROSS[0] - 7.5 * 2.6, CROSS[1] - 6.5 * 2.6), 3.6),
]

# Halaman kiri mushaf terbuka; halaman kanan adalah cerminannya.
SPINE_X = 52.6
left_top = quad((SPINE_X, 56), (44, 48), (30, 51))
left_bottom = quad((30, 70), (44, 67), (SPINE_X, 75))
left_page = left_top + left_bottom
right_page = mirror(left_page)

# Baris tulisan di halaman: salinan kurva bawah yang digeser ke atas.
lines = []
for shift in (5, 9, 13):
    curve = quad((30, 70 - shift), (44, 67 - shift), (SPINE_X, 75 - shift))
    segment = curve[4:-3]
    lines += [segment, mirror(segment)]
LINE_W = 1.3

# (subpath-subpath, warna); subpath kedua bintang adalah lubang (even-odd).
FILLS = [
    ([star, star_hole], GOLD),
    ([rehal[0]], GOLD),
    ([rehal[1]], GOLD),
    ([left_page], PAGE),
    ([right_page], PAGE),
]


# --- Keluaran vektor ---------------------------------------------------------

def path_data(subpaths):
    return " ".join(
        "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in sp) + " Z" for sp in subpaths)


def polyline_data(points):
    return "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in points)


def write_svg():
    parts = [f'<rect width="108" height="108" fill="{BG}"/>']
    for subpaths, color in FILLS:
        parts.append(f'<path d="{path_data(subpaths)}" fill="{color}" fill-rule="evenodd"/>')
    for ln in lines:
        parts.append(f'<path d="{polyline_data(ln)}" fill="none" stroke="{LINE}" '
                     f'stroke-width="{LINE_W}" stroke-linecap="round"/>')
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" '
           'width="1080" height="1080">\n  ' + "\n  ".join(parts) + "\n</svg>\n")
    out = ROOT / "assets/branding/logo.svg"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(svg, encoding="utf-8")


def vector_drawable(monochrome):
    paths = []
    for subpaths, color in FILLS:
        fill = "#FFFFFFFF" if monochrome else color
        paths.append(f'    <path android:fillColor="{fill}" android:fillType="evenOdd"\n'
                     f'        android:pathData="{path_data(subpaths)}" />')
    if not monochrome:
        for ln in lines:
            paths.append(f'    <path android:strokeColor="{LINE}" android:strokeWidth="{LINE_W}"\n'
                         f'        android:strokeLineCap="round"\n'
                         f'        android:pathData="{polyline_data(ln)}" />')
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<!-- Dibuat oleh tool/generate_icon.py, jangan diedit manual. -->\n'
            '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    android:width="108dp" android:height="108dp"\n'
            '    android:viewportWidth="108" android:viewportHeight="108">\n'
            + "\n".join(paths) + "\n</vector>\n")


def write_android_vectors():
    drawable = RES / "drawable"
    (drawable / "ic_launcher_foreground.xml").write_text(vector_drawable(False), encoding="utf-8")
    (drawable / "ic_launcher_monochrome.xml").write_text(vector_drawable(True), encoding="utf-8")
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <color name="ic_launcher_background">{BG}</color>\n</resources>\n',
        encoding="utf-8")
    adaptive = ('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background" />\n'
                '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
                '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
                '</adaptive-icon>\n')
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(adaptive, encoding="utf-8")


# --- Keluaran PNG ------------------------------------------------------------

def render(size, crop, corner_ratio):
    """Merender area [crop, 108 - crop] kanvas ke PNG berukuran size x size."""
    ss = 8  # supersampling untuk tepi yang halus
    big = size * ss
    scale = big / (108 - 2 * crop)

    def tx(points):
        return [((x - crop) * scale, (y - crop) * scale) for x, y in points]

    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, big - 1, big - 1), radius=int(big * corner_ratio), fill=BG)
    for subpaths, color in FILLS:
        d.polygon(tx(subpaths[0]), fill=color)
        for hole in subpaths[1:]:
            d.polygon(tx(hole), fill=BG)
    for ln in lines:
        pts = tx(ln)
        w = round(LINE_W * scale)
        d.line(pts, fill=LINE, width=w, joint="curve")
        for p in (pts[0], pts[-1]):
            d.ellipse((p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2), fill=LINE)
    return img.resize((size, size), Image.LANCZOS)


def write_pngs():
    for folder, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        render(size, crop=18, corner_ratio=0.2).save(RES / f"mipmap-{folder}/ic_launcher.png")
    # Google Play menerapkan masker sudutnya sendiri, jadi ikon dibuat persegi penuh.
    render(512, crop=14, corner_ratio=0).save(ROOT / "assets/branding/playstore_512.png")
    # Ikon kecil untuk dialog "Tentang" di dalam aplikasi.
    render(192, crop=18, corner_ratio=0.22).save(ROOT / "assets/branding/icon_192.png")


def _font(names, size):
    for name in names:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default(size)


def write_feature_graphic():
    """Gambar fitur Google Play (1024x500): logo di kiri, nama dan tagline di kanan."""
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), BG)
    logo = render(340, crop=14, corner_ratio=0)
    img.paste(logo, (90, (h - 340) // 2), logo)
    d = ImageDraw.Draw(img)
    title = _font(["segoeuib.ttf", "DejaVuSans-Bold.ttf", "Arial Bold.ttf"], 108)
    body = _font(["segoeui.ttf", "DejaVuSans.ttf", "Arial.ttf"], 34)
    d.text((480, 120), "Ngaji", font=title, fill="#FFFFFF")
    d.text((484, 268), "Al-Qur'an · Sejarah Ayat · Hadist", font=body, fill=GOLD)
    d.text((484, 318), "Belajar mendalam, ayat demi ayat", font=body, fill=LINE)
    img.save(ROOT / "assets/branding/feature_graphic.png")


if __name__ == "__main__":
    write_svg()
    write_android_vectors()
    write_pngs()
    write_feature_graphic()
    print("Ikon berhasil dibuat.")
