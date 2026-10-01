# Catatan Pembuatan Orakel Kriptografi (Blind Procedure)

## Aturan yang Diikuti
1. Orakel ditulis secara mandiri dan *buta* (blind) tanpa melihat kode sumber di `lib/cipher_workbench/ciphers/`.
2. Semua rumus dan logika didasarkan langsung pada literatur dan spesifikasi dalam `PROJECT_SPEC.md` serta `DECISIONS.md`.
3. Validasi orakel dilakukan dengan membandingkannya terhadap test vektor *bersumber* dan dienkapsulasi dalam unit tes `test/oracles/oracle_test.rb`.

## Urutan Pengerjaan & Temuan
1. **Vigenere Oracle**
   - Rumus Dekripsi: $P = (C - K) \pmod{26}$.
   - Uji coba: `LXFOPVEFRNHR` dengan kunci `LEMON` lulus (`ATTACKATDAWN`).
2. **Auto-Key Oracle**
   - Rumus Dekripsi: $P_i = (C_i - K_i) \pmod{26}$. Jika $i \ge |K|$, maka $K_i = P_{i-|K|}$.
   - Uji coba: `QNXEPVYTWTWP` dengan kunci `QUEENLY` lulus (`ATTACKATDAWN`).
3. **Extended Vigenere Oracle**
   - Domain: 256 byte. Rumus: $P = (C - K) \pmod{256}$. Kunci diperlakukan sebagai deretan byte (bukan terbatas pada alfabet).
4. **Playfair Oracle**
   - Menggantikan 'J' dengan 'I'. Matriks $5 \times 5$ digenerasi dari kunci (karakter ganda dibuang).
   - Aturan kebalikan enkripsi:
     - Baris sama: bergeser ke kiri 1 (wrap ke 4).
     - Kolom sama: bergeser ke atas 1 (wrap ke 4).
     - Persegi empat: tetap di baris yang sama, tukar kolom.
   - Uji coba: Berhasil menghasilkan `HIDETHEGOLDINTHETREXESTUMP` dari ciphertext referensi.
5. **Affine Oracle**
   - Rumus Dekripsi: $P = a^{-1} \cdot (C - b) \pmod{26}$. Invers modular $a$ dicari melalui iterasi $1..25$ karena $a$ harus _coprime_ terhadap 26.
   - Uji coba: `IHHWVC` ($a=5, b=8$) lulus (`AFFINE`).
6. **Hill Oracle**
   - Mencari determinan, lalu mencari $det^{-1} \pmod{26}$. 
   - Menghitung matriks _adjugate_ (kofaktor matriks transpos), kemudian memetakannya dengan modulus 26 untuk mendapat Invers Matriks.
   - Uji coba: Blok 3x3 `GYBNQKURP` untuk ciphertext `POH` menghasilkan `ACT`.
7. **Columnar Transposition Oracle**
   - Strategi memutar: Hitung ukuran _long columns_ ($L = N \pmod{K}$) dan jumlah baris dasar ($R = \lfloor N / K \rfloor$). 
   - Alokasikan array berdasar ukuran tiap kolom di urutan aslinya. _Sort_ secara stabil (urut _alphabet_) indeks asal, lalu tebarkan array _ciphertext_ secara berurutan sesuai kolom yang terurut. 
   - Rekonstruksi baris demi baris.
   - Uji coba: `EVLNACDTESEAROFODEECWIREE` dengan `ZEBRAS` lulus (`WEAREDISCOVEREDFLEEATONCE`).
8. **Super Encryption Oracle**
   - Kombinasi Columnar Transposition (stage 1) diikuti oleh Extended Vigenere (stage 2). Orakel me-referensi dua orakel yang sudah ada dan memanggilnya terbalik.
9. **Enigma Oracle**
   - Rotor: `I, II, III, IV, V`. Reflektor `B, C`.
   - Jalur sinyal dua arah (*reciprocal*).
   - Logika Double Stepping: Rotor tengah berputar jika dipicu rotor paling kanan DAN berputar (beserta rotor paling kiri) jika ia sendiri mencapai *notch*.
   - Uji coba: Menggunakan `AAA` menghasilkan `BDZGO`, dan 26-AA..A memicu perilaku *stepping* rotor secara akurat. Vektor lulus secara penuh.

## Kesimpulan
Keseluruhan $8$ orakel independen berhasil diverifikasi 100% menggunakan test vektor bersumber yang tidak bergantung pada kode implementasi di lingkungan _production_.
