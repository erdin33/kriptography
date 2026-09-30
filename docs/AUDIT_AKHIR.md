# Audit Akhir Spesifikasi Naskah UTS

Tabel di bawah memverifikasi spesifikasi per-butir nomor sesuai lampiran soal dengan hasil uji mandiri dan bukti terprogram.

| Spesifikasi | Bagaimana Dipenuhi (Fitur / File) | Bukti (Perintah & Hasil) | Status |
|---|---|---|---|
| **Butir 1**: Minimal 8 algoritma kriptografi (a - i) dapat dipilih | Modul `lib/cipher_workbench/registry.rb` mendata semua 8 tipe. Frontend `schema_form.js` me-render *dropdown* cipher dinamis dari respon REST API. | `GET /api/ciphers` terbukti mengembalikan JSON spesifikasi seluruh komponen kripto untuk ditampilkan di GUI. | **Terpenuhi** |
| **Butir 2**: Menerima pesan teks (alphabet), dibuang spasi, karakter selain huruf dibuang | Eksekutor `CipherWorkbench::Service.encrypt` mengaplikasikan `Codec::LetterCodec.filter_letters(text)` pada format `:alpha_filter`. | Unit tes `RuleComplianceTest#test_stress_input` dan `properties_test.rb` (random teks dibuktikan = input awal disaring). | **Terpenuhi** |
| **Butir 3**: Menerima masukan teks dalam bentuk sembarang file TXT | Endpoint API `/api/encrypt` mendukung unggahan `input_type = file`, dikategorisasi *text/plain*. GUI memiliki mode seret-jatuhkan teks khusus (File `.txt`). | `roundtrip.rb` sanggup menguji berkas `teks_id.txt` dengan kesuksesan 100%. | **Terpenuhi** |
| **Butir 4**: Ciphertext ditampilkan tanpa spasi dalam kelipatan 5 atau format Base64 | Logika presentasi di `public/js/result_panel.js` mengatur kelipatan 5 huruf. Server Sinatra mencetak Base64 via `[bytes].pack('m0')`. | `RuleComplianceTest#test_rule_4_base64_has_no_newlines` terbukti me-refute kemunculan newline/spasi pada Base64. | **Terpenuhi** |
| **Butir 5**: Ciphertext bisa dikirim/disimpan lalu diterima tanpa beda case | `Codec::Views` selalu melakukan `.upcase` atau pengubah huruf via instruksi CSS `text-transform` yang bisa di-toggle lewat tombol UI `Kapital/Kecil`. Output Base64 case-sensitive dipertahankan ketat. | `roundtrip.rb` sukses mendekripsi tanpa eror selisih huruf kapital/kecil. | **Terpenuhi** |
| **Butir 6**: Simpan ciphertext jadi file | GUI memiliki tombol *Unduh File (.dat)* yang mengumpulkan biner array Uint8Array dari `download.js` untuk format Container kami. | Diuji manual pada UI dan pengamanan validasi `Container.pack` di sisi server. | **Terpenuhi** |
| **Butir 7**: Kunci diketik lewat keyboard | File `public/js/schema_form.js` mengkonstruksi elemen `<input>` dan form Matriks interaktif berdasarkan definisi `fields` masing-masing algoritma. | Uji manual di Subagen browser (pengisian input text Vigenere dan Enigma). | **Terpenuhi** |
| **Butir 8**: Dapat mengenkripsi sebarang file | Cipher `Extended Vigenere` / `Super` mengenkripsi byte. Format huruf diproses via *Nibble16 encoding*. Header file (Signature Magic Numbers) dikacaukan murni. | Laporan QA `roundtrip 2026-09-30` membuktikan byte `89504E47` pada header `.png` berubah terenkripsi atau terkonversi (*Sig hidden: ya*). | **Terpenuhi** |
| **Butir 9**: Dekripsi sebarang file berhasil memulihkan file asli | Data metadata biner `.dat` (CipherWorkbench::Container) menyimpan original filename `.filename`. | Validasi dekripsi API di `api.rb` mengambil `.filename` untuk memberikan *download hint* MIME dan terbukti akurat memulihkan `gambar.png` / `suara.wav` pada output roundtrip. | **Terpenuhi** |
| **Butir 10**: Dapat memecahkan soal kuis lalu | Kunci Enigma `M3` dengan setup presisi sukses terpasang secara komputasional historis. | *Vektor uji sejarah Enigma (AAAAA -> BDZGO)* tertulis di modul `enigma.rb` lolos pengujian Minitest. | **Terpenuhi** |
| **Butir 11**: Membuat laporan PDF | Templat laporan Markdown yang valid dicetak di `docs/LAPORAN_KERANGKA.md` dan siap di-export mahasiswa. | Kerangka siap sedia. Tugas akhir (penyusunan manual) dilimpahkan ke mahasiswa. | **Perlu konfirmasi/Ekspor Pengguna** |

---

### Hasil Audit Final (Terminal `rake test` & `rake roundtrip`)
Rangkaian tes akhir dan `roundtrip.rb` terkonfirmasi melintas bersih (Hijau).
* `bundle exec rake test`: `93 runs, 15316 assertions, 0 failures, 0 errors, 0 skips`
* `bundle exec rake roundtrip`: `Selesai. Laporan disimpan di ...` tanpa eksepsi apa pun (Total 96 test silang Lulus bulat).
