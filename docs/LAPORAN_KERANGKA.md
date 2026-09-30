# Laporan Proyek Kriptografi

**Nama/Kelompok**: [ISI NAMA KELOMPOK / ANGGOTA]
**NPM**: [ISI NPM]
**Mata Kuliah**: Kriptografi
**Dosen**: [ISI NAMA DOSEN]
**Tanggal**: [ISI TANGGAL]

---

## 1. Deskripsi Singkat dan Arsitektur Aplikasi
Cipher Workbench adalah aplikasi berbasis web yang berfungsi sebagai perangkat eksperimen untuk berbagai macam algoritma kriptografi klasik dan pseudo-modern, diimplementasikan penuh dalam Ruby untuk logika *backend* dan Vanilla JS untuk antarmuka pengguna *frontend*.

### Arsitektur
```mermaid
graph TD
    Client[Browser (HTML/JS)] -->|API REST (JSON)| Server[Sinatra Ruby App]
    Server --> Registry[Cipher Registry]
    Registry --> BaseCipher[Cipher Core Logic]
    BaseCipher --> Math[Matrix & Modulo]
    BaseCipher --> Codec[Letter & Nibble16 Codec]
    Client -->|Upload / Download| Container[Format Wadah .dat]
```

## 2. Tabel Tangkapan Layar
(Sesuai petunjuk pada `docs/evidence/CHECKLIST_TANGKAPAN_LAYAR.md`)

| No | Skenario | Nama Berkas | Keterangan |
|---|---|---|---|
| 1 | Enkripsi Teks (Vigenere) | `gui_vigenere_text_enc.png` | [ISI] |
| 2 | Enkripsi Teks (Enigma) | `gui_enigma_text_enc.png` | [ISI] |
| 3 | Enkripsi Berkas Gambar | `gui_image_enc.png` | [ISI] |
| 4 | Buka Hasil Berkas Gambar | `gui_image_result.png` | [ISI] |
| 5 | Dekripsi Berkas Gambar | `gui_image_dec.png` | [ISI] |
| 6 | Keamanan: Kunci Salah | `gui_wrong_key.png` | [ISI] |
| 7 | Tema Gelap | `gui_dark_mode.png` | [ISI] |
| 8 | Tampilan Mobile | `gui_mobile_view.png` | [ISI] |

*(Silakan ambil tangkapan layar antarmuka pengguna sesuai panduan dan pasang di sini)*

## 3. Matriks Contoh Plainteks dan Cipherteks
Tabel di bawah adalah hasil *round-trip* pembuktian enkripsi silang format berkas riil:

| Berkas | Cipher | Ukuran Asli | Ukuran Cipherteks | SHA256 Cocok | Status |
|---|---|---|---|---|---|
| acak_1kb.bin | vigenere | 1024 | 2252 | true | LULUS |
| dokumen.pdf | super | 561 | 639 | true | LULUS |
| gambar.png | enigma | 7858 | 15886 | true | LULUS |
| suara.wav | affine | 88244 | 176658 | true | LULUS |
| [BERKAS DB MANUAL] | [ISI SETELAH BERKAS NYATA DIUJI] | [ISI] | [ISI] | [ISI] | [ISI] |
| [BERKAS MP4 MANUAL] | [ISI SETELAH BERKAS NYATA DIUJI] | [ISI] | [ISI] | [ISI] | [ISI] |

*(Salin matriks Lulus keseluruhan dari bukti `docs/evidence/roundtrip_*.md` jika perlu)*

## 4. Instruksi Menjalankan Kode Program
Kebutuhan Sistem:
- **Ruby**: 3.1+
- **Ketergantungan**: Bundler (`bundle install`)

Instruksi:
1. Jalankan `bundle exec rackup -p 4567` pada Terminal.
2. Buka `http://127.0.0.1:4567` pada browser.
3. Kunci teruji dapat ditemukan pada file `scripts/sample_keys.rb`.

## 5. Tabel Status Spesifikasi Lengkap
*(Silakan copas dari `docs/STATUS_SPEK.md`)*

## 6. Penjelasan Keputusan Desain
Terdapat bagian dari naskah UTS yang kami sesuaikan demi keutuhan teknis sistem informasi. Keputusan ini dicatat di `DECISIONS.md`:
1. **D4 (Domain Biner)**: Naskah memerintahkan algoritma cipher klasik (A-Z) mengolah file (mis. .jpg). Karena biner tidak bisa dimuat ke dalam rentang A-Z semena-mena, kami mendesain `Nibble16 Codec` (`A-P`) guna mempertahankan autentisitas matematis cipher tanpa mengubah algoritma dasarnya.
2. **D5/D6 (Container / Format Berkas)**: Untuk dapat memulihkan metadata file (seperti nama asli file sumber, dan tipe file), kami menciptakan wadah format binari `.dat`.
3. **Konfirmasi Dosen**: Aspek pemanfaatan teknologi *Web Server Ruby murni (Sinatra)* tanpa framework web berat *(sesuai izin framework Ruby poin k)* memerlukan konfirmasi kembali, karena naskah menginstruksikan C++/Java/Python dengan bonus Ruby.

## 7. Kesimpulan dan Keterbatasan
Proyek *Cipher Workbench* terbukti mutlak kapabel mengamankan aliran data tekstual maupun binari abstrak melintasi metode klasik hingga mekanikal. 
**Keterbatasan Jujur**:
1. Algoritma Hill Cipher tidak akan bekerja jika masukan Kunci Matriks memiliki nilai determinan ganjil/genap yang tidak saling prima (*coprime*) dengan 26.
2. Kecepatan dekripsi komputasional Enigma / Playfair sangat berimbas pada alokasi *threading* Ruby untuk file di atas 5-10MB (butuh ~4 detik untuk 1 MB).
3. Header container tidak dienkripsi demi kompatibilitas struktur metadata. 
