# Bug Ledger Kriptografi

| ID | Judul | Kategori | Tingkat | Komponen | Reproduksi Minimal | Tingkat Bukti | Akar Masalah | Perbaikan | Tes | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| BUG-001 | Test `test_no_external_assets` gagal membaca `favicon.ico` karena encoding US-ASCII | TIDAK TERLIHAT | S1 (Keluaran salah atau crash di suite tes) | GUI Tests | `bundle exec rake test` di mana ENV LANG tidak ada | E1 (Direproduksi pada Baseline) | - | - | - | BARU |
