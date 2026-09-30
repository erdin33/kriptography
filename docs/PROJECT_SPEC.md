# Spesifikasi Proyek (salinan naskah soal)

Sumber: Naskah Soal UTS Kriptografi, Program Studi Informatika, Fakultas Teknik, Universitas Siliwangi. Dosen pengampu: Ir. Randi Rizal, Ph.D. Bentuk ujian: project-based (sendiri/kelompok). Plagiarisme atau duplikasi program bernilai 0.

## Soal
Membuat program dengan antarmuka (GUI) berbasis web. Bahasa pemrograman dibebaskan (naskah menyebut JavaScript/TypeScript/PHP/Python/Golang). Program mengimplementasikan:
a) Vigenere Cipher standar (26 huruf alfabet)
b) Varian Vigenere Cipher standar (26 huruf alfabet): Auto-Key Vigenere Cipher
c) Extended Vigenere Cipher (256 karakter ASCII)
d) Playfair Cipher (26 huruf alfabet)
e) Affine Cipher (26 huruf alfabet)
f) Hill Cipher (26 huruf alfabet)
g) Super enkripsi: gabungan Extended Vigenere Cipher dan cipher transposisi (metode kolom)
h) Bonus 1: Enigma cipher
i) Bonus 2: Menggunakan bahasa Ruby

## Spesifikasi (11 butir)
1. Program dapat menerima pesan berupa file sembarang (file teks maupun biner) atau pesan yang diketikkan dari papan-ketik.
2. Program dapat mengenkripsi plainteks. Khusus untuk cipher dengan keterangan 26 huruf alfabet, program hanya mengenkripsi karakter alfabet saja. Angka, spasi, dan tanda baca dibuang dari plainteks dan cipherteks.
3. Program dapat mendekripsi cipherteks menjadi plainteks semula.
4. Program dapat menampilkan pesan (plainteks maupun cipherteks) di layar dalam kode base64.
5. Cipherteks di layar ditampilkan tanpa spasi dan semuanya huruf kecil (atau huruf kapital) dalam kode base64.
6. Program dapat menyimpan cipherteks ke dalam file (save as atau download as a binary file).
7. Kunci dimasukkan oleh pengguna. Panjang kunci bebas.
8. Untuk enkripsi pesan berupa file, program membaca setiap byte di dalam file (termasuk byte-byte header file) dan mengenkripsinya. File yang sudah terenkripsi tidak bisa dibuka oleh program aplikasinya karena header file ikut terenkripsi. Dengan mendekripsinya kembali, file tersebut dapat digunakan kembali.
9. Untuk enkripsi plainteks file dengan ekstensi sembarang, format file cipherteks bebas (misalnya .dat). Ketika didekripsi, jenis file harus disimpan dengan jenis yang sama seperti file plainteks (docx tetap docx, jpg tetap jpg, dst.). Boleh menyimpan ekstensi atau nama file plainteks di dalam file cipherteks agar pengguna tidak perlu mengingat jenis file yang dienkripsi.
10. Pustaka untuk menghitung balikan modulo, matriks balikan, dan aljabar linier diperbolehkan.
11. Boleh menggunakan framework apa pun (ReactJS, Flask, Ruby on Rails, dan lain-lain).

## Antarmuka inspirasi
Terinspirasi dari aes.online-domain-tools.com (Function diganti Cipher). Elemen: Input type (Text/File), Input text (Plaintext/Hex), Function (cipher), Mode, Key, tombol Encrypt dan Decrypt, area hasil (hex dump), tautan "Download as a binary file". Contoh teks pada gambar naskah: "Di bawah sinar bulan purnama, air laut berkilauan, berayun-ayun ombak mengalir ke pantai senda gurauan".

## Deliverable laporan (PDF)
1. Tampilan antarmuka (print screen).
2. Contoh plainteks dan cipherteks (teks, gambar, file database, audio, video) beserta penjelasannya.
3. Kode program lengkap dengan README cara menjalankan.
4. Tabel status per spek (9 baris: a sampai i) dengan kolom Berhasil / Kurang Berhasil / Keterangan.
   "Berhasil" = sesuai spek, enkripsi dan dekripsi benar, baik pesan ketikan maupun file.
   "Kurang Berhasil" = belum selesai, ada kesalahan, dekripsi salah, hanya bisa file teks, atau hanya bisa pesan ketikan. Wajib dijelaskan jujur di kolom Keterangan.

## Ketidakjelasan naskah (dicatat, belum terkonfirmasi ke dosen)
- Ruby tidak ada pada daftar bahasa utama, hanya sebagai bonus.
- Butir 2 (buang non-huruf) vs butir 8 (semua byte file dienkripsi) belum dijelaskan untuk cipher 26 huruf.
- Butir 5 menyebut huruf kecil/kapital "dalam kode base64", padahal base64 case-sensitive.
- "Panjang kunci bebas" tidak jelas untuk Affine (dua angka), Hill (matriks), dan Enigma (susunan rotor).
