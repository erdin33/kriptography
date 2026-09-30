# Sistem Desain Kriptografi

## Prinsip Desain
- **Ketegasan Klinis**: Tanpa dekorasi berlebih (tanpa gradien, neon, bayangan rumit). Mengutamakan kejelasan, keterbacaan, dan hierarki.
- **Instrumental**: Meniru perangkat laboratorium dan instrumen metrik yang dapat diandalkan, dengan nuansa analog halus (kertas hangat, tinta gelap tajam).
- **Aksesibel**: Mendukung skema warna gelap/terang secara mulus melalui _custom properties_ dengan fokus penuh pada rasio kontras tinggi dan indikasi *focus* papan tik yang mapan.

## Token Warna (CSS Custom Properties)

| Kegunaan | `--var` | Light | Dark |
| --- | --- | --- | --- |
| Latar Halaman | `--bg` | `#F3F1EC` | `#15181B` |
| Permukaan Panel | `--surface` | `#FBFAF7` | `#1C2024` |
| Blok Data / Read-only | `--surface-sunken` | `#ECE9E1` | `#121518` |
| Teks Utama | `--ink` | `#1E2226` | `#E6E3DC` |
| Teks Meta / Bantuan | `--ink-muted` | `#5A6168` | `#9AA1A8` |
| Garis Pemisah / Lemah | `--border` | `#D6D2C7` | `#2E343A` |
| Garis Input / Fokus | `--border-strong` | `#B9B4A6` | `#454C53` |
| Aksen Utama | `--accent` | `#2F5D62` | `#6FA3A8` |
| Teks di atas Aksen | `--accent-ink` | `#FFFFFF` | `#0F1416` |
| Peringatan Kritis | `--danger` | `#A4372A` | `#E0806F` |
| Keberhasilan | `--success` | `#3C6E47` | `#7DB68A` |
| Interupsi Lemah | `--warning` | `#8A6414` | `#D4A94A` |

### Audit Kontras (WCAG AA 4.5:1 target)
Pengujian mandiri menggunakan algoritma luminansi relatif RGB standar:
- **Light `--ink` / `--bg`**: 14.18:1 (Pass)
- **Light `--ink-muted` / `--surface`**: 6.02:1 (Pass)
- **Light `--accent-ink` / `--accent`**: 7.34:1 (Pass)
- **Light `--danger` / `--surface`**: 6.37:1 (Pass)
- **Dark `--ink` / `--bg`**: 13.91:1 (Pass)
- **Dark `--ink-muted` / `--surface`**: 6.27:1 (Pass)
- **Dark `--accent-ink` / `--accent`**: 6.61:1 (Pass)
- **Dark `--danger` / `--surface`**: 5.84:1 (Pass)

Semua pasangan esensial memenuhi kualifikasi WCAG AA, memastikan perangkat nyaman di mata untuk pemakaian analisis yang panjang.

## Galeri Komponen
Berbagai rekaan statis tata letak UI (_gallery component_) tersedia di rute internal aplikasi khusus fase pengujian: `/dev/gallery` (dapat diakses jika `RACK_ENV != 'production'`). Di galeri ini tercantum bentuk primitif seperti:
1. Skema Formulir (Teks, Matrix, Tab).
2. Segmentasi dan Tombol berstatus.
3. Tabel Hasil dan Metadata.
4. Spanduk Peringatan.

*Peringatan Visual: Rute `/dev/gallery` ini hanya ditujukan untuk fase desain internal dan perbaikan presisi piksel (tidak memuat JavaScript fungsional enkripsi).*
