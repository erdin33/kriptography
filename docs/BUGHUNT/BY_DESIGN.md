# Perilaku "Bug" yang Disengaja (BY DESIGN)

Daftar perilaku berikut sering kali dapat keliru dianggap sebagai bug oleh QA atau Pengguna, padahal secara spesifik telah dirancang dan disetujui (By Design). Jangan mengubah hal ini menjadi bug tanpa persetujuan ulang atau modifikasi spesifikasi.

1. **Format teks (spasi, tanda baca, _casing_) hilang setelah proses Enkripsi-Dekripsi untuk domain 26 huruf.**
   - **Tampak seperti**: Kehilangan data (data loss) pada teks biasa.
   - **Rujukan**: `PROJECT_SPEC.md` butir 2, dan `DECISIONS.md` (D3). 
   - **Alasan**: Semua plaintext disaring menjadi abjad kapital berurutan A-Z tanpa tanda baca agar sesuai dengan batasan historis kriptografi klasik.

2. **Karakter Filler "X" atau "Q" terlihat di output Playfair/Hill.**
   - **Tampak seperti**: Dekripsi tidak mengembalikan pesan asli yang bersih, malah terdapat X ekstra.
   - **Rujukan**: `DECISIONS.md` (D4, D15).
   - **Alasan**: Playfair menyisipkan filler untuk digraf kembar, dan Hill membutuhkan pad/filler hingga panjang teks dapat dibagi habis oleh dimensi matriks. UI mode `alpha_filter` memunculkan filler ini karena teks secara harfiah telah diubah saat enkripsi.

3. **Dekripsi dengan Kunci yang Salah mengembalikan HTTP 200 OK (bukan error).**
   - **Tampak seperti**: Server gagal mendeteksi pembobolan kunci dengan error spesifik.
   - **Rujukan**: `DECISIONS.md` (D6) & `service.rb`.
   - **Alasan**: Dalam model _container_ D6, `integrity.valid = false` dikembalikan dalam respon HTTP 200. Dekripsi tetap dijalankan dan menghasilkan "sampah" (garbled text) agar pengguna/analis dapat menginspeksi hasil yang salah.

4. **Metadata dalam file _.dat_ (Header Container) tidak terenkripsi.**
   - **Tampak seperti**: Kebocoran informasi karena nama file dan ukuran file terlihat _plaintext_ jika _.dat_ dibuka di _hex editor_.
   - **Rujukan**: `DECISIONS.md` (D6).
   - **Alasan**: Enkripsi hanya berlaku untuk payload data kriptografi. Container adalah format transportasi pembungkus, bukan wadah enkripsi berlapis (seperti PGP).

5. **Nama File asli (filename) tidak tercakup dalam validasi hash SHA-256.**
   - **Tampak seperti**: Integritas data lemah karena attacker bisa mengganti nama file.
   - **Rujukan**: `DECISIONS.md` (D6).
   - **Alasan**: Batasan SHA-256 yang diterapkan hanya untuk menguji kesuksesan pembongkaran cipher terhadap payload.

6. **Tampilan Teks Plaintext di UI terpotong (_truncated_) pada batas 64 KiB.**
   - **Tampak seperti**: Dekripsi file besar atau teks besar gagal memuat sisa hasil.
   - **Rujukan**: `DECISIONS.md` (D7).
   - **Alasan**: 64 KiB adalah batas *tampilan* di GUI untuk mencegah DOM _freeze_. Seluruh isi didekripsi dengan utuh (tersedia via tombol unduh asli/biner atau blob url).

7. **Nilai Pengganda Kunci Affine (_a_) di Modulo-kan 26 jika Melebihi Batas.**
   - **Tampak seperti**: Validasi input lemah, $a=29$ diterima padahal hanya 12 kunci coprime yang diizinkan.
   - **Rujukan**: `DECISIONS.md` (D15).
   - **Alasan**: Sistem secara otomatis akan melakukkan penyesuaian matematika ekuivalen ($a=29 \equiv 3 \pmod{26}$) selama FPB-nya valid.

8. **Teks Base64 Dekripsi tidak pernah merubah kasus teks (_casing_).**
   - **Tampak seperti**: Ketidakseragaman _case conversion_.
   - **Rujukan**: `DECISIONS.md` (D7).
   - **Alasan**: Transformasi hanya terjadi di domain teks abjad 26 huruf (menjadi Uppercase). Untuk Base64 (domain byte), representasi absolut byte tidak boleh diubah kasusnya karena akan merusak biner.

9. **Kunci Mesin Enigma Dianggap sebagai Pengaturan Mesin (Ring & Posisi Awal).**
   - **Tampak seperti**: String Kunci Vigenere yang dimasukkan tidak bekerja seperti kata sandi biasa.
   - **Rujukan**: Desain Enigma di `DECISIONS.md` dan `enigma.rb`.
   - **Alasan**: Kunci harus memuat takik ring mesin.
