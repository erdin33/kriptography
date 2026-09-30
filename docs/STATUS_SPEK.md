# Tabel Status Spesifikasi (Sesuai Soal)

| Butir/Fitur | Berhasil / Kurang / Keterangan |
|---|---|
| a. Vigenere Cipher Standard | **Berhasil**. Terbukti lulus pada enkripsi dan dekripsi berkas teks dan acak di uji 100-iterasi `properties_test.rb` serta 100% Lulus di `roundtrip 2026-09-30`. |
| b. Vigenere Cipher Auto-key | **Berhasil**. Mekanisme injeksi kunci-sambungan plainteks telah teruji komplit. Terbukti LULUS total di uji `roundtrip.rb`. |
| c. Extended Vigenere Cipher | **Berhasil**. Lulus mengelola *Full Byte Domain* (0-255). Terbukti tidak menumpuk/rusak pada *stress test* karakter tak-nampak (*invisible chars*). |
| d. Playfair Cipher | **Berhasil**. Fungsional dalam penyisipan huruf padding X jika ganda, dan substitusi matriks balikan pada dekripsi. LULUS seluruh roundtrip berkas 1 MB. |
| e. Affine Cipher | **Berhasil**. Pengamanan filter GCD = 1 pada koefisien 'a' berfungsi penuh untuk menjamin eksistensi invers. Enkripsi dan dekripsi sukses di roundtrip. |
| f. Hill Cipher | **Berhasil**. Algoritma penentuan matriks dinamis $N \times N$ dengan pengisian elemen interaktif terbukti presisi dihitung dengan `matrix_mod.rb`. |
| g. Cipher Transposisi Kolom | **Berhasil**. Tidak terdaftar pada katalog UI tersendiri (keputusan arsitektur), namun algoritma telah beroperasi mulus secara *internal* pada tahap enkripsi hibrida. |
| h. Super Enkripsi | **Berhasil**. Kombinasi `Extended Vigenere` (Byte) + `Transposisi Kolom` berjalan sukses pada format `.wav`, `.png` maupun teks, dan terbukti lolos di matriks QA roundtrip. |
| i. (Bonus) Enigma Cipher | **Berhasil**. Menggunakan model M3 presisi histori militer (Rotor I-V, Reflektor B/C). Terbukti memecahkan uji Vektor AAAAA -> BDZGO. Konfigurasi plugboard interaktif. |
| Bonus Bahasa Pemrograman | **Ruby/Sinatra (Web GUI)**. Pemenuhan antarmuka sepenuhnya tercapai, namun perlakuan bonus bahasa ini bergantung pada interpretasi konfirmasi dari Dosen Pengampu, karena naskah menitikberatkan C++/Java/Python. |

---

## Interpretasi yang Perlu Dikonfirmasi ke Dosen
1. **Butir 2 vs 8 (Abjad vs Biner)**: Naskah butir 2 membatasi ciphertext alfabet {a-z}, namun butir 8 mewajibkan semua jenis berkas sembarang (.png, .mp4) dapat dienkripsi. Mustahil mengenkripsi representasi citra acak menggunakan cipher 26 modulus tanpa mengubah format file atau kehilangannya (karena tak semua byte adalah ASCII huruf). Kami menggunakan `Nibble 16-encoding` (`A-P`) agar berkas biner apa pun bisa masuk ke algoritma alfabet. Mohon konfirmasi dari dosen apakah terobosan ini sesuai kaidah evaluasi akademik yang dituju.
2. **Butir 5 (Base64)**: Penambahan format *Base64* dari output biner dapat diekstrak bersih atau justru harus selalu membuang blok spasi. Kami menggunakan standar ketiadaan jeda blok ASCII (*strict Base64*).
3. **Konfigurasi Mesin Enigma**: Skema penilaian tidak mensyaratkan plugboard, tetapi kami tambahkan. Mohon konfirmasi kelayakan perolehan bonus penuh.
4. **Platform / Bonus Ruby**: Karena menggunakan ekosistem Web App Vanilla JS + Web Server Ruby (berbeda dari GUI Desktop Java/Qt konvensional).
