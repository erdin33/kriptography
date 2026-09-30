# Keputusan Desain (tetap; ubah hanya dengan persetujuan pengguna)

## D1. Stack
Ruby (versi terpasang, minimal 3.1), Sinatra, Puma, Minitest, rack-test. Frontend: HTML, CSS, JavaScript ES modules murni. Tanpa bundler, tanpa CDN, tanpa framework JS. Ruby dipilih untuk bonus 2.

## D2. Dua domain cipher
- `:letters` (26 simbol, 0..25 untuk A..Z): Vigenere, Auto-Key, Playfair, Affine, Hill, Enigma.
- `:bytes` (256 simbol, 0..255): Extended Vigenere, Super Enkripsi.

## D3. Teks pada cipher domain huruf (mode `alpha-filter`)
Ubah ke huruf kapital, buang semua karakter selain A..Z (angka, spasi, tanda baca, huruf non-ASCII). Cipherteks berupa huruf kapital tanpa spasi. Hasil dekripsi juga rangkaian huruf tanpa format asli (konsekuensi butir 2, bukan bug). Jika hasil filter kosong, tolak dengan pesan jelas.

## D4. File pada cipher domain huruf (mode `nibble16`)  [INTERPRETASI, belum dikonfirmasi dosen]
Setiap byte dipecah menjadi dua nibble (4 bit; nibble tinggi dulu), dipetakan ke alfabet 16 huruf `ABCDEFGHIKLMNOPQ` (indeks 0..15; huruf J sengaja dilewati agar aman untuk Playfair). Rangkaian huruf ini yang dienkripsi. Saat dekripsi: hasil dekripsi difilter ke huruf yang ada pada alfabet 16 huruf (membuang filler seperti X dari Playfair/Hill), didekode ke byte, lalu dipotong ke panjang byte asli. Ukuran cipherteks 2 kali ukuran file. Semua byte file termasuk header tetap ikut terenkripsi (butir 8).

## D5. Cipher domain byte (mode `raw`)
Berkas: byte apa adanya. Teks ketikan: byte UTF-8. Dekripsi teks: interpretasikan hasil sebagai UTF-8; bila bukan UTF-8 valid, tampilkan hanya base64/hex dan beri peringatan.

## D6. Format container (.dat), versi 1, semua bilangan big-endian
| Offset | Ukuran | Isi |
|---|---|---|
| 0 | 4 | magic ASCII `CWB1` |
| 4 | 1 | versi format = 1 |
| 5 | 1 | panjang id cipher (L) |
| 6 | L | id cipher (ASCII), mis. `vigenere` |
| 6+L | 1 | jenis muatan: 1=teks, 2=berkas |
| 7+L | 1 | pengodean: 0=raw, 1=alpha-filter, 2=nibble16 |
| 8+L | 2 | panjang nama berkas (N), 0 untuk teks |
| 10+L | N | nama berkas asli (UTF-8) |
| 10+L+N | 8 | panjang plainteks domain (raw: jumlah byte; alpha-filter: jumlah huruf setelah `prepare`; nibble16: jumlah byte berkas asli) |
| 18+L+N | 32 | SHA-256 plainteks domain (raw: byte; alpha-filter: huruf ASCII setelah `prepare`; nibble16: byte berkas asli) |
| 50+L+N | 8 | panjang muatan cipherteks (P) |
| 58+L+N | P | cipherteks (raw: byte; lainnya: huruf kapital ASCII) |
Parser harus ketat: tolak magic salah, versi tidak dikenal, data terpotong, atau sisa byte. Metadata TIDAK dienkripsi (dicatat sebagai keterbatasan di dokumentasi; SHA-256 memberi bahan verifikasi tebakan kunci).

## D7. Tampilan di layar
- Tampilan Huruf (hanya domain huruf): tanpa spasi/baris baru; pilihan huruf kecil (default) atau kapital.
- Tampilan Base64: RFC 4648 alfabet standar dengan padding, tanpa spasi/baris baru, huruf besar-kecil dipertahankan. DILARANG mengubah case string base64.
- Tampilan Hex: huruf kecil, byte dipisah spasi diperbolehkan hanya di tampilan hex.
- Plainteks juga ditampilkan dalam base64 (butir 4).
- Batas tampilan 64 KiB pertama; bila terpotong, beri label jelas "menampilkan N dari M byte". Unduhan selalu lengkap.

## D8. Server stateless
Tanpa database, tanpa penyimpanan berkas pengguna, tanpa log isi/kunci. Batas unggah default 25 MiB, dapat diatur lewat ENV `MAX_UPLOAD_MB`.

## D9. Kontrak error
Respons JSON `{ "ok": false, "error": { "code": "...", "message": "...", "field": "..." } }` dengan status 400/413/422/500. Kode: `invalid_params`, `invalid_key`, `invalid_input`, `invalid_container`, `cipher_mismatch`, `invalid_ciphertext`, `payload_too_large`, `unsupported_cipher`, `internal_error`.

## D10. Tanpa pustaka kripto
Logika cipher ditulis sendiri. Boleh pustaka umum (butir 10 naskah), tetapi diusahakan tidak diperlukan (invers modulo dan matriks ditulis sendiri).

## D11. Kontrak antarmuka cipher (Ruby)
Kelas turunan `CipherWorkbench::Ciphers::Base` dengan: `self.id`, `self.title`, `self.group` (`:classic26`, `:ascii256`, `:super`, `:bonus`), `self.domain` (`:letters` atau `:bytes`), `self.summary` (satu paragraf Indonesia), `self.fields` (skema kolom kunci untuk UI), `#initialize(params)` yang memvalidasi kunci dan melempar `InvalidKeyError`, `#prepare(symbols)` (default identitas; Playfair/Hill menerapkan normalisasi/padding), `#encrypt(symbols)` (memanggil `prepare` lebih dulu), `#decrypt(symbols)`, `#describe_key` (Hash kunci ternormalisasi dan artefak turunan untuk ditampilkan UI). `symbols` adalah Array<Integer> pada domain cipher. Kontrak: `decrypt(encrypt(x)) == prepare(x)`.

## D12. Super enkripsi
Enkripsi: Extended Vigenere (kunci 1) lalu transposisi kolom (kunci 2). Dekripsi: kebalikannya. Transposisi kolom tak beraturan (irregular), tanpa padding: tulis byte per baris selebar jumlah kolom (panjang kunci), baca kolom menurut urutan kunci (byte terkecil dulu; seri diurut menurut posisi). Sehingga panjang keluaran = panjang masukan.

## D13. Enigma
Model M3: rotor I sampai V, reflektor B dan C, ring setting, posisi awal, plugboard (maksimal 10 pasang), termasuk double-stepping. Data konstanta diberikan pada prompt Tahap 6.

## D14. UI
Bahasa Indonesia. Tampilan tenang, sederhana, dan profesional (bukan tampilan generik "AI"). Detail pada Tahap 8.

## D15. Asumsi Tambahan
- Untuk Affine Cipher (Tahap 3), parameter `a` dan `b` dinormalisasi secara matematis (modulo 26) sebelum divalidasi. Hal ini menyebabkan nilai negatif seperti `b = -3` akan dianggap sah dan setara dengan `23`, serta nilai `a = 27` akan dianggap sah dan setara dengan `1`.
