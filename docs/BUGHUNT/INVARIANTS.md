# Daftar Invarian Jalur Dekripsi

Berikut adalah invarian yang akan diuji sepanjang perburuan bug (BH2-BH4).

1. **I1 (Round-trip berkas byte-exact)**: Untuk setiap cipher, kunci sah, dan byte apa pun (panjang 0 sampai N): `decrypt(encrypt(b)).bytes == b`, `filename` sama persis, `integrity.valid == true`. 
   - Sumber: *PROJECT_SPEC.md (Container & API)*. 
   - Uji: File acak berbagai ekstensi dengan `rake roundtrip`.

2. **I2 (Round-trip teks)**: 
   - Domain byte: Teks dienkripsi lalu didekripsi -> sama persis dengan aslinya (UTF-8).
   - Domain huruf: Sama dengan `prepare(filter(teks))` (hilang spasi, upper case).
   - Sumber: *DECISIONS.md (D3, D11)*. 

3. **I3 (Codec container)**: `unpack(pack(x)) == x`. 
   - Setiap mutasi pada header, offset, atau panjang akan menghasilkan `InvalidContainerError` secara eksklusif (atau `CipherMismatchError` jika ID berubah). Sisa byte di akhir biner DITOLAK mentah-mentah.
   - Sumber: *DECISIONS.md (D6)*.

4. **I4 (Integritas)**: 
   - Kunci yang digunakan dekripsi **benar** -> `valid: true`. 
   - Kunci yang digunakan **salah** -> `valid: false` (bukan melempar error).
   - Jika muatan container dimutasi -> `valid: false` atau error terdefinisi (seperti padding error), namun **tidak pernah** `valid: true`.
   - Teks tempelan UI -> `checked: false`.
   - Sumber: *DECISIONS.md (D6)*.

5. **I5 (Determinisme dan kemurnian)**: 
   - Masukan yang sama **selalu** menghasilkan keluaran yang sama.
   - Tidak ada _state_ yang bocor antar-panggilan, antar-instance, atau antar-thread. Sangat krusial untuk cipher yang memanfaatkan state berlanjut (Auto-Key, Enigma M3). 
   - Konstanta (seperti array Tabula Recta) tidak termutasi (selalu direferensi immutable).

6. **I6 (Keamanan domain)**: 
   - Hasil (simbol) selalu di dalam rentang: `0..25` untuk _letters_, `0..255` untuk _bytes_.
   - Tidak ada elemen `nil` atau indeks negatif yang lolos tanpa peringatan.
   - Penggunaan tipe `pack('C*')` terhadap bilangan di luar 0..255 tidak membungkus angka secara diam-diam.

7. **I7 (Kontrak error)**: 
   - Setiap kegagalan pemrosesan _user-facing_ **wajib** merupakan subkelas dari `CipherWorkbench::Error` (sehingga terpetakan ke kode HTTP dokumentasi D9). 
   - Tidak boleh merespons `HTTP 500` karena malformasi masukan pengguna. 
   - _Stack trace_ tidak pernah bocor ke antarmuka pengguna dalam respons JSON. Bahasa pesan kesalahan harus berbahasa Indonesia.

8. **I8 (Keamanan transport)**: 
   - Respons `JSON` selalu berhasil diserialisasi tanpa kegagalan `Encoding::UndefinedConversionError`, bahkan jika `plain_bytes` adalah biner tidak valid UTF-8. 
   - `plain_bytes` wajib dikodekan sebagai Base64 yang valid di properti JSON `plain_base64`. 
   - Panjang _truncate_ (potongan GUI) selalu memiliki penanda.

9. **I9 (Skala resources)**: 
   - Peningkatan ukuran memori/waktu tumbuh linear atau rasional hingga batas upload maksimum. Tidak ada algoritma pencarian kuadratik liar (_O(N^2)_) pada dataset besar.

10. **I10 (Kesetaraan Jalur)**: 
    - Objek hasil pemrosesan internal via `Service` secara langsung identik dengan respons `API JSON` dan juga nilai yang secara visual di-_render_ di GUI (baik byte, HEX, maupun representasi teks base64-nya).

11. **I11 (Cipher-spesifik)**: 
    - **Vigenere / Auto-Key**: Auto-Key memiliki sifat rekursif umpan balik _progressive_ saat dekripsi.
    - **Affine**: Memvalidasi pencarian invers eksak modulo 26 dari nilai $a$.
    - **Playfair**: Aturan penggantian persegi panjang, pergeseran baris/kolom terbalik (_up_ dan _left_).
    - **Hill**: Reduksi `mod 26` perkalian matriks dikalikan matriks involutif (determinan dihitung akurat dengan invers).
    - **Transposisi Kolom**: Mengurutkan indeks panjang pesan tidak teratur dan menstabilkan urutan huruf sejenis (stable sort).
    - **Super Enkripsi**: Gabungan Dekripsi dari dua tahap dilakukan dengan cara kebalikan: _Transposition Decrypt_ diteruskan ke _Extended Vigenere Decrypt_.
    - **Enigma M3**: Mesin resiprokal, fungsi pemetaan maju = fungsi pemetaan mundur; reset takik di tiap _call_; tidak ada abjad yang memetakan dirinya sendiri.

12. **I12 (Nama berkas)**: 
    - Dipulihkan sama persis dengan aslinya melalui metadata. 
    - Saat pengunduhan GUI, nama file di _sanitize_ tanpa menyebabkan _path traversal vulnerability_. Mendukung nama ekstrem (Unicode, spasi, sangat panjang).

13. **I13 (Konsistensi metadata D6)**: 
    - Arti matematis dari variabel `plain_length` dan `plain_sha256` di container *selalu merefleksikan jumlah byte original*, baik saat di mode `raw`, `alpha_filter`, maupun mode ekspansi heksadesimal 4-bit `nibble16`.

14. **I14 (Format Tempelan Input)**: 
    - Input UI dalam `letters` harus menolak / mengabaikan karakter non-alpabetik.
    - Input `base64` mempertahankan _case_ besar/kecil. Kesalahan ditolak.
    - Input `hex` tidak sensitif _case_, panjang array hex ganjil otomatis ditolak dengan _error_ terdefinisi.

15. **I15 (Konsistensi GUI & Integrasi Browser)**: 
    - Perubahan cepat _dropdown_ Cipher pada tab Dekripsi harus mengosongkan _state_. 
    - Hasil lama tidak "terbawa" (usang) ke _render_ permintaan baru. 
    - _Badge integritas_ merah selalu sinkron dengan status respons server. _Blob URL_ tidak bocor memori.
