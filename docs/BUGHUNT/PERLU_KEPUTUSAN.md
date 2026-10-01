# Pertanyaan Keputusan (BUG-002: Padding Playfair & Hill)

## Latar Belakang
Pada cipher Playfair dan Hill di mode `alpha_filter` (domain huruf), padding berupa huruf `X` (dan `Q`) seringkali disisipkan agar blok matematis dapat diproses (genap untuk Playfair, kelipatan matriks untuk Hill). Berdasarkan dokumen `DECISIONS.md`, disepakati bahwa *"Sisipan/tambahan tersebut tidak dihapus saat dekripsi"*.

Namun, ada masalah dengan **Integritas (Checksum)**:
- Saat ini, berkas `.dat` menyimpan `plain_length` dan `plain_sha256` dari plainteks yang **telah di-padding**. 
- Akibatnya, saat dekripsi, hasil keluaran adalah teks ber-padding (contoh: input asli `HI`, output dekripsi `HIX`). Integritas divalidasi sebagai **TRUE/Valid**, padahal data aslinya telah berubah secara semantik.

## Opsi Perbaikan

| Opsi | Deskripsi | Kelebihan | Kekurangan |
|---|---|---|---|
| **A. Ubah Checksum ke Pra-Padding (Strict Integrity)** | Hitung panjang & SHA256 sebelum `prepare()` dipanggil. Dekripsi akan mengembalikan padding, sehingga *Integrity* akan **merah (FALSE)** karena `HIX` tidak cocok dengan `HI`. | Integritas matematis 100% terjaga. Secara benar memberitahu user bahwa hasil dekripsi mengandung padding. | User awam mungkin panik melihat *Badge* Merah padahal kunci yang dimasukkan sudah benar. |
| **B. Tetapkan Checksum ke Pasca-Padding (By Design)** | Biarkan perilaku saat ini, di mana berkas container menganggap padding sebagai bagian sah dari *plaintext*. | Tidak ada ubahan sistemik. | Berkas yang didekripsi seolah "orisinil" padahal diam-diam memuat karakter ekstra. Ujian *round-trip* akan tetap mentolerir ini. |
| **C. Coba Buang Padding (Best Effort)** | Modifikasi cipher agar otomatis membuang `X` berlebih di ujung string saat dekripsi bila mencurigakan. | User mendapat string yang persis sama. | Secara matematis mustahil 100% akurat. Bisa jadi huruf `X` di akhir teks adalah pesan asli, bukan padding. |

**Rekomendasi Engineer**: Saya merekomendasikan **Opsi A**, lalu ditambahkan *UI Note* khusus yang menjelaskan bahwa "Tanda merah mungkin muncul karena adanya padding 'X' otomatis dari cipher Playfair/Hill".

Mohon konfirmasi Anda.
