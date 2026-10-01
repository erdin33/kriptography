# Laporan Akhir: Rollback Visualisasi 3D

## Skenario yang Dipakai
**Skenario A** digunakan. 
Alasan: Pekerjaan 3D dilakukan pada branch tersendiri (`feature/viz-3d`) yang belum digabungkan (_merged_) ke `main`. Dengan beralih ke `main` (commit `8291f76`), semua perbaikan *bug* non-3D yang dibuat setelah UTS tetap aman dan fitur 3D berhasil dihapus sepenuhnya dari area kerja.

## Cadangan yang Dibuat
- **Branch WIP (Pekerjaan Belum Terkomit)**: `backup/viz-3d-wip-20261001-0731`
- **Arsip Branch 3D Lama**: `archive/viz-3d-20261001-0731`
- **Bundle File (Penyimpanan Aman di Luar Repositori)**: `/Users/macbookprom1/Documents/Kuliah/Semester/Semester 7/Kriptografi/UTS/cipher-workbench-viz3d-20261001-0731.bundle`
- **Hash BASE (main)**: `8291f76727a8221fd46dbc1f96bfe3025fdaa98f`
- **Hash HEAD (archive/viz-3d)**: `340608a8fccdbd682d0e96631eb75ade47ba1129`

## Daftar Perintah Eksekusi
1. `git stash` (tidak ada perubahan karena sudah bersih)
2. `git switch main` (beralih ke titik aman tanpa 3D)
3. `git branch -m feature/viz-3d archive/viz-3d-20261001-0731` (mengarsipkan branch 3D)

## Verifikasi (FASE 5)

| Pengecekan | Status | Bukti / Catatan |
|---|---|---|
| **Kesamaan Pohon (Diff dengan BASE)** | **LULUS** | `git diff --stat 8291f76 HEAD` kosong (tidak ada beda sama sekali). |
| **Pemindaian Sisa (Grep 3D/Viz)** | **LULUS** | Semua dokumen 3D seperti `docs/3D_DECISIONS.md` dan `3D_SPEC.md` telah hilang. Kata `trace` yang tersisa hanyalah untuk *stack-trace* Ruby asli. |
| **Pengecekan API** | **LULUS** | `GET /api/ciphers` kembali ke 8 cipher, parameter `features.viz` hilang. `GET /api/trace` mengembalikan status `404`. |
| **Pengujian (Rake Test)** | **GAGAL** | Terdapat satu kegagalan baru: `ArgumentError` di `GuiTest#test_no_external_assets`. |
| **Integritas Dokumentasi** | **LULUS** | `PROGRESS.md` bersih dari rekam jejak tahap 12 ke atas. |

## Analisis Kegagalan Tes & Resolusi
Tes `rake test` gagal dengan error `invalid byte sequence in US-ASCII` saat membaca file.
**Akar Masalah**: Dalam commit `47b7b4f` (komit perbaikan _non-3D_ yang dilakukan oleh pengguna sebelumnya di `main`), pengguna menambahkan file biner `favicon.ico` ke folder `public/`. Tes `test_no_external_assets` dirancang membaca *semua file* di `public/` sebagai file teks standar, sehingga pembacaan file biner `.ico` menyebabkan crash pada Ruby. 

**Tindakan Saat Ini**: Kegagalan tes ini murni bukan karena proses rollback (rollback sukses), melainkan karena *bug* bawaan pada tes yang belum diadaptasikan dengan ekstensi `.ico`. Tes dibiarkan gagal sesuai instruksi "Jangan memperbaiki tes untuk membuatnya hijau sebagai bonus".

## Cara Pemulihan 3D
Bila di kemudian hari Anda ingin kembali melanjutkan fitur 3D:
```bash
git switch backup/viz-3d-wip-20261001-0731
```
Jika Anda benar-benar yakin ingin **menghapus secara permanen** semua arsip 3D:
```bash
git branch -D backup/viz-3d-wip-20261001-0731
git branch -D archive/viz-3d-20261001-0731
rm ../cipher-workbench-viz3d-20261001-0731.bundle
```

*Catatan Remote: Semua cabang 3D masih lokal, tidak ada jejak yang bocor ke remote.*
