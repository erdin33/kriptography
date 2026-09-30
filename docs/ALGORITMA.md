# Algoritma dan Implementasi Cipher Workbench

Dokumen ini menjelaskan rancangan teoritis masing-masing cipher beserta pemetaannya ke kode sumber.

## 1. Vigenere Cipher
- **Ide Singkat**: Cipher substitusi polialfabetik yang menggunakan deret huruf pada kata kunci untuk menentukan pergeseran (shift) masing-masing huruf pesan.
- **Rumus Matematis**: 
  - Enkripsi: $C_i = (P_i + K_{i \bmod m}) \bmod 26$
  - Dekripsi: $P_i = (C_i - K_{i \bmod m}) \bmod 26$
  - ($m$ = panjang kunci)
- **Contoh Perhitungan**:
  - Plainteks = `LEMON` (L=11, E=4, M=12, O=14, N=13)
  - Kunci = `KEY` (K=10, E=4, Y=24)
  - Enkripsi:
    - $C_0 = (11 + 10) \bmod 26 = 21 \rightarrow$ V
    - $C_1 = (4 + 4) \bmod 26 = 8 \rightarrow$ I
    - $C_2 = (12 + 24) \bmod 26 = 10 \rightarrow$ K
    - $C_3 = (14 + 10) \bmod 26 = 24 \rightarrow$ Y
    - $C_4 = (13 + 4) \bmod 26 = 17 \rightarrow$ R
- **Kelemahan/Serangan**: Rentan terhadap tes Kasiski dan Analisis Indeks Koinsidensi (IC) untuk mencari periode $m$. Jika periode ditemukan, sandi dapat diserang layaknya sekelompok *Caesar cipher*.
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/vigenere.rb`. 

## 2. Auto-Key Vigenere Cipher
- **Ide Singkat**: Variasi Vigenere yang menggunakan plainteks itu sendiri sebagai kelanjutan dari kunci awal untuk mencegah perulangan periodik kunci.
- **Rumus Matematis**: 
  - Aliran kunci (Keystream): $K = (K_0..K_{m-1}) \parallel (P_0..P_{n-m})$
  - Enkripsi: $C_i = (P_i + K_i) \bmod 26$
  - Dekripsi: $P_i = (C_i - K_i) \bmod 26$, di mana $K_i = P_{i-m}$ untuk $i \ge m$.
- **Contoh Perhitungan**:
  - Plainteks = `QUEENLY`
  - Kunci = `KEY`
  - Keystream = `KEYQUEE`
  - Enkripsi `Q(16) + K(10) = A(0)`.
- **Kelemahan/Serangan**: Tidak periodik, sehingga kebal tes Kasiski standar. Namun rentan jika sebagian isi pesan dapat ditebak (Serangan Teks Terbuka / Known Plaintext).
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/autokey.rb`.

## 3. Extended Vigenere Cipher
- **Ide Singkat**: Membawa Vigenere dari rentang alfabet (26 huruf) ke rentang spektrum byte ASCII/binary utuh (256 nilai).
- **Rumus Matematis**: 
  - Enkripsi: $C_i = (P_i + K_{i \bmod m}) \bmod 256$
  - Dekripsi: $P_i = (C_i - K_{i \bmod m}) \bmod 256$
- **Kelemahan/Serangan**: Sama seperti Vigenere klasik (karena berulang secara periodik), frekuensi byte dapat digunakan untuk analisis Kasiski/koinsidensi.
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/extended_vigenere.rb`.

## 4. Playfair Cipher
- **Ide Singkat**: Sandi substitusi digraf (pasangan dua huruf) yang memetakan huruf berdasarkan posisi persegi (matrix 5x5) dengan huruf J yang dilebur menjadi I.
- **Aturan**:
  1. Jika huruf berulang dalam satu digraf, selipkan 'X'. 
  2. Jika dalam baris sama, geser kanan 1.
  3. Jika dalam kolom sama, geser bawah 1.
  4. Berbeda baris & kolom, tukar kolom.
- **Contoh Perhitungan**:
  - Teks: `PLAYFAIR EXAMPLE`
  - Kotak 5x5 kunci `PLAYFAIR`:
    ```
    P L A Y F
    I R B C D
    E G H K M
    N O Q S T
    U V W X Z
    ```
- **Kelemahan/Serangan**: Analisis frekuensi 600 pasangan bigram, atau pencarian pembalikan silang.
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/playfair.rb`.

## 5. Affine Cipher
- **Ide Singkat**: Enkripsi perkalian dan pertambahan linier.
- **Rumus Matematis**: 
  - Enkripsi: $C_i = (a \cdot P_i + b) \bmod 26$
  - Dekripsi: $P_i = a^{-1} \cdot (C_i - b) \bmod 26$
  - Syarat: $a$ harus saling prima (*coprime*) dengan 26.
- **Contoh Perhitungan**:
  - Teks: `A`(0), a = 5, b = 8
  - $C = (5 \cdot 0 + 8) \bmod 26 = 8$ (I).
- **Kelemahan/Serangan**: Sangat lemah terhadap *Known-Plaintext Attack* karena merupakan persamaan linier 2 variabel; mengetahui 2 huruf plainteks cukup untuk mendapatkan kunci $a$ dan $b$.
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/affine.rb`.

## 6. Hill Cipher
- **Ide Singkat**: Menggunakan perkalian matriks modulo 26, mengubah blok plainteks berukuran $N$.
- **Rumus Matematis**: 
  - Enkripsi: $\mathbf{C} = (\mathbf{K} \cdot \mathbf{P}) \bmod 26$
  - Dekripsi: $\mathbf{P} = (\mathbf{K}^{-1} \cdot \mathbf{C}) \bmod 26$
- **Contoh Perhitungan**:
  - Matriks `[[3, 3], [2, 5]]` (Gybnqkurp) untuk blok 2x2.
- **Kelemahan/Serangan**: Memiliki kerentanan besar terhadap *Known-Plaintext Attack*. Jika panjang matriks ukuran m diketahui, musuh cukup butuh *m* blok plainteks.
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/hill.rb` dan utilitas di `lib/cipher_workbench/math/matrix_mod.rb`.

## 7. Transposisi Kolom
- **Ide Singkat**: Menulis pesan dari kiri-ke-kanan pada kisi (grid) ukuran kolom, kemudian membacanya dari atas-ke-bawah berdasarkan urutan abjad huruf pada kata kunci.
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/columnar_transposition.rb`.

## 8. Super Enkripsi
- **Ide Singkat**: Extended Vigenere 256 digabungkan dengan dekripsi Transposisi Kolom beruntun untuk menghancurkan relasi pola pada tabel byte. 
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/super_encryption.rb`.

## 9. Enigma (M3)
- **Ide Singkat**: Mesin mekanik rotasi poli-alfabetik yang dikembangkan Jerman pada era Perang Dunia 2 dengan sirkuit refleks bolak-balik.
- **Rumus Matematis**: 
  - $E(x) = P \cdot R_3 \cdot R_2 \cdot R_1 \cdot Ref \cdot R_1^{-1} \cdot R_2^{-1} \cdot R_3^{-1} \cdot P^{-1}(x)$ 
- **Contoh**: `AAAAA` -> `BDZGO` dengan Rotor I, II, III.
- **Kelemahan**: Letak reflektor memastikan *sebuah huruf tidak akan pernah disandikan menjadi dirinya sendiri* (No fixed points). Kelemahan fatal ini dimanfaatkan Alan Turing.
- **Pemetaan Kode**: `lib/cipher_workbench/ciphers/enigma.rb`.

## Arsitektur Khusus Berkas Biner pada Domain 26-Huruf
Untuk melindungi sifat cipher klasik yang beroperasi murni pada deret {0..25}, kami memanfaatkan *Nibble Encode*: setiap byte (0-255) dipecah atas dasar bit *high-nibble* dan *low-nibble*, lalu kedua paruh bit direpresentasikan secara alfanumerik sebagai deret `A`-`P` (16 basis).
Dengan begitu, 1 karakter biner akan membuahkan tepat 2 huruf ASCII `A-P` yang dengan mulus ditelan mesin substitusi seperti Affine/Vigenere/Hill.

## Format Kontainer (.dat)
Setiap payload dan ekstensi/metadata dikemas secara _binary-safe_:
| Posisi | Tipe | Deskripsi |
|---|---|---|
| 0..3 | UInt32 (BE) | Magic Number `0xC1F3C011` |
| 4..5 | UInt16 (BE) | Panjang String ID Cipher |
| 6..X | String | ID Cipher UTF-8 |
| ... | String | Tipe Encoding & Tipe Konten |
| ... | UInt64 (BE) | Panjang Byte Asli Plainteks |
| ... | 32-Byte | SHA-256 Hash Plainteks murni |
| Akhir | Byte Array | Payload Enkripsi |
