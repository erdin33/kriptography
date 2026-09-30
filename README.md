# Cipher Workbench - UTS Kriptografi

Cipher Workbench adalah instrumen kriptografi komprehensif untuk pengujian dan evaluasi algoritma enkripsi klasik (domain huruf) hingga enkripsi lanjut (domain byte). Dirancang khusus sebagai pemenuhan spesifikasi UTS Mata Kuliah Kriptografi S1 Informatika.

## Fitur Tersedia
Sesuai naskah UTS:
a. **Vigenere Cipher** (Domain Huruf)
b. **Auto-Key Vigenere Cipher** (Domain Huruf)
c. **Extended Vigenere Cipher** (256 ASCII / Domain Byte)
d. **Playfair Cipher** (Domain Huruf)
e. **Affine Cipher** (Domain Huruf)
f. **Hill Cipher** (Domain Huruf, Matriks Dinamis)
g. **Cipher Transposisi Kolom** (Tersedia internal, digabung di Super Enkripsi)
h. **Super Enkripsi** (Kombinasi Extended Vigenere + Transposisi Kolom, Domain Byte)
i. **Enigma M3 Cipher** (Bonus) (Domain Huruf, simulasi presisi Wehrmacht)

## Kebutuhan Sistem
- **Ruby**: Versi yang telah teruji adalah Ruby 3.1, 3.2, dan 3.3.0.
- **Sistem Operasi**: Teruji secara intensif pada macOS dan Linux. (Sistem Windows belum diverifikasi secara langsung).
- **Gem**: Bundler.

## Instalasi
Jalankan perintah ini di terminal:
```bash
bundle install
```

## Cara Menjalankan
```bash
# Menjalankan server pada port default (4567)
bundle exec rackup -p 4567
```
Buka browser pada alamat `http://127.0.0.1:4567` untuk mengakses antarmuka pengguna.

## Pengujian (Unit & E2E)
```bash
# Membuat berkas dummy untuk tes (otomatis di fixtures/generated)
bundle exec rake fixtures

# Uji integrasi, QA API, serta kriptanalisis (Ruby)
bundle exec rake test

# Uji Round-Trip (Enkripsi -> Wadah -> Dekripsi) semua cipher
bundle exec rake roundtrip
```

## Struktur Direktori
- `app.rb`: Entrypoint aplikasi web Sinatra.
- `lib/cipher_workbench/`: Inti algoritma matematis kriptografi.
- `lib/cipher_workbench/ciphers/`: Definisi masing-masing metode cipher (Vigenere, Hill, dll).
- `public/js/`: Kumpulan kode sumber *Frontend JavaScript murni (ES Modules)*.
- `views/`: Kerangka layout ERB untuk antarmuka.
- `docs/`: Laporan-laporan progres dan referensi keputusan arsitektur.
- `fixtures/`: Area unggahan berkas nyata dan palsu untuk pengetesan.
- `test/`: Pengetesan Minitest.

## Panduan Penggunaan GUI
1. **Enkripsi Teks**: Pilih algoritma, klik mode **Teks Ketikan**, ketik kalimat Anda, dan isikan Form Kunci Kriptografi.
2. **Enkripsi Berkas**: Pilih mode **Unggah Berkas**, seret/jatuhkan file gambar, audio, atau dokumen. Isi Kunci, kemudian klik **Proses**. Unduh wadah (`.dat`) bila selesai.
3. **Dekripsi Teks**: Untuk teks, masukkan cipherteks ke panel input teks.
4. **Dekripsi Berkas**: Untuk berkas `.dat`, cukup seret berkas ke area drop zone, isikan kunci, dan klik proses. Berkas akan terunduh kembali dalam nama aslinya.
5. **Cara menambah berkas nyata untuk uji**: Letakkan berkas gambar/suara/video apa saja di folder `fixtures/manual/` dan jalankan `bundle exec rake roundtrip`.

## Variabel Lingkungan
- `PORT` (Default: 4567): Port web server.
- `MAX_UPLOAD_MB` (Default: 25): Batasan kapasitas muatan (dalam MB) yang diproses server.
- `RACK_ENV` (Default: development): Profil lingkungan eksekusi Rack.

## Keamanan dan Keterbatasan
- **Peringatan Kriptografi**: Cipher klasik seperti Playfair, Affine, dan Vigenere TIDAK AMAN untuk standar modern dan sangat rentan terhadap kriptanalisis (frekuensi, serangan ekshaustif). Cipher ini dibuat murni untuk edukasi.
- **Metadata Wadah Kriptografi (Container)**: Header container berisi nama file asli, ukuran asli, dan jenis hash SHA-256 (yang tidak dienkripsi melainkan tersimpan sebagai _plaintext byte_) yang ditujukan murni sebagai bahan verifikasi tebakan kunci pasca-dekripsi.
- **Keterbatasan Kecepatan**: Berkas > 5MB mungkin lamban pada cipher yang iteratif bit-per-bit (e.g. Hill dan Enigma).

## Lisensi
Aplikasi ini dikembangkan untuk penyelesaian UTS, hak cipta mengikuti dosen pengampu.
