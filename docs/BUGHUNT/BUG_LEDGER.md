# Bug Ledger Kriptografi

| ID | Judul | Kategori | Tingkat | Komponen | Reproduksi Minimal | Tingkat Bukti | Akar Masalah | Perbaikan | Tes | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| BUG-001 | Test `test_no_external_assets` gagal membaca `favicon.ico` karena encoding US-ASCII | TIDAK TERLIHAT | S1 (Keluaran salah atau crash di suite tes) | GUI Tests | `bundle exec rake test` di mana ENV LANG tidak ada | E1 (Direproduksi pada Baseline) | - | - | - | DIREPRODUKSI |
| BUG-002 | Padding 'X' atau 'Q' tertinggal pada Plainteks Mode alpha_filter di Playfair/Hill | TERLIHAT | S2 (Data rusak) | Cipher Playfair & Hill | Enkripsi Teks ganjil/ganda, lalu cek `integrity.valid` pada response dekripsi | E1 (Direproduksi) | - | - | `bug_002_playfair_integrity_test.rb` | DIREPRODUKSI |
| BUG-003 | Dekripsi menghasilkan invalid UTF-8 memicu 500 JSON::GeneratorError | TIDAK TERLIHAT | S3 (Crash server) | API / Service | Dekripsi Extended Vigenere yg memicu byte invalid UTF-8 | E1 (Direproduksi) | - | - | `bug_003_json_invalid_utf8_test.rb` | DIREPRODUKSI |
| BUG-004 | Concurrency: Request baru dibatalkan AbortController karena diset NULL oleh request lama | GUI | S2 (UI glitch/timpa menimpa) | JS `api.js` | Request lambat dibatalkan request baru, lalu finally block lama jalan | E1 (Direproduksi) | - | - | `bug_004_js_concurrency_test.rb` | DIREPRODUKSI |
| BUG-005 | FormData merubah baris baru `\n` menjadi CRLF `\r\n` | TERLIHAT | S2 (Data rusak) | JS / API | Enkripsi payload teks `A\nB` dari UI | E1 (Direproduksi) | - | - | `bug_005_crlf_normalization_test.rb` | DIREPRODUKSI |
