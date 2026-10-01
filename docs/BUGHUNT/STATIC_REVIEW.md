# STATIC REVIEW BH2

Dokumen ini berisi hasil ulasan statis per baris untuk komponen kunci backend dan frontend Cipher Workbench.

## Target Telaah (Ruby)
1. `lib/cipher_workbench/container.rb`
2. `lib/cipher_workbench/service.rb`
3. `lib/cipher_workbench/api.rb`
4. `lib/cipher_workbench/codec/*.rb`
5. `lib/cipher_workbench/ciphers/*.rb`

### Temuan Statis
**1. JSON::GeneratorError pada respon API (BUG-003)**
- **Berkas**: `lib/cipher_workbench/service.rb:154` & `lib/cipher_workbench/api.rb:155`
- **Kutipan Kode**: 
  ```ruby
  text = plain_bytes.dup.force_encoding('UTF-8')
  text_valid = text.valid_encoding?
  ...
  JSON.generate(ret)
  ```
- **Hipotesis (E0)**: Jika input bytes dari dekripsi memuat sekuens yang tidak valid dalam UTF-8, fungsi `force_encoding` tidak mengubah bytes tersebut. Namun ketika `api.rb` mencoba menyerialisasikan struktur yang memuatnya dengan `JSON.generate()`, Ruby akan melempar `JSON::GeneratorError`.
- **Invarian**: Melanggar I7 (tidak ada error 500) dan I8 (hasil selalu JSON serializable).
- **Tes**: `bug_003_json_invalid_utf8_test.rb` terbukti gagal (RED).

**2. Playfair: Padding integritas (BUG-002)**
- **Berkas**: `lib/cipher_workbench/ciphers/playfair.rb:84`
- **Kutipan Kode**:
  ```ruby
  Codec::LetterCodec.letters_to_symbols(res.join)
  ```
- **Hipotesis (E0)**: Playfair menambahkan filler `X` dan `Q` dalam `prepare()`. Pada saat dekripsi, filler ini *tidak dibuang*. Ketika beroperasi di mode domain huruf (`alpha_filter`), plain_length dan plain_sha256 dihitung dari plaintext yang TELAH DIPADDING (karena hashing terjadi setelah `prepare`). Akibatnya, `integrity.valid` mengembalikan TRUE meskipun dekripsi mengandung "sampah" padding.
- **Invarian**: Melanggar I4 (Integritas, jika user mengira file orisinil kembali tepat sama).
- **Tes**: `bug_002_playfair_integrity_test.rb` ditulis.

**3. Hill: Padding Integritas**
- **Berkas**: `lib/cipher_workbench/ciphers/hill.rb`
- **Kutipan Kode**: Sama dengan Playfair.
- **Keterangan**: Pada mode *byte* (nibble16), padding berhasil dibuang berkat filter di `nibble_decode`. Namun di mode huruf (alpha_filter), padding 'X' tertinggal dan dihitung sah oleh checksum, sehingga tidak ketahuan bahwa file asli telah berubah ukurannya.

**4. Columnar Transposition: Urutan stabil kunci (BY DESIGN)**
- **Berkas**: `columnar_transposition.rb:34`
- **Hipotesis (E0)**: Urutan kolom untuk byte kunci kembar bisa tidak stabil antara enkripsi dan dekripsi.
- **Keterangan**: Telah diverifikasi bahwa program memakai `indexed.sort_by { |b, i| [b, i] }`, yang secara implisit adalah *stable sort* karena melibatkan indeks asli. Tidak ada bug di sini (TIDAK DIREPRODUKSI).

**5. Enigma: State Leakage (BY DESIGN)**
- **Berkas**: `enigma.rb:133`
- **Kutipan Kode**: `state = @positions.dup`
- **Keterangan**: Penggandaan array state dilakukan dengan `dup` setiap kali sebelum pemrosesan enkripsi/dekripsi. Jadi tidak terjadi mutasi silang antar eksekusi di instans Enigma yang sama. (TIDAK DIREPRODUKSI).

**6. Auto-Key: Off-by-one pada plainteks (BY DESIGN)**
- **Berkas**: `autokey.rb:43`
- **Kutipan Kode**: `k = i < m ? @key_symbols[i] : plain_symbols[i - m]`
- **Keterangan**: Kode ini benar 100%. Untuk `m=5`, karakter ke-6 (indeks 5) menggunakan `plain_symbols[5-5]` yaitu indeks 0 (karakter pertama). Tidak ada pergeseran logika (TIDAK DIREPRODUKSI).

## Target Telaah (JavaScript)

### Temuan Statis
**1. Concurrency Fetch menimpa state abort (BUG-004)**
- **Berkas**: `public/js/api.js:41`
- **Kutipan Kode**:
  ```javascript
  } finally {
    activeController = null;
  }
  ```
- **Hipotesis (E0)**: Blok `finally` ini menghapus `activeController` setelah eksekusi selesai. Namun jika eksekusi tersebut telah dibatalkan oleh `activeController` baru (dari request berikutnya), yang dihapus adalah referensi dari request *terbaru*, sehingga request ketiga tidak akan bisa membatalkan request kedua. Balapan antar-request ini dapat mengakibatkan UI ditimpa hasil lama.
- **Invarian**: Melanggar I5 (Isolasi).
- **Tes**: `bug_004_js_concurrency_test.rb` (Node.js test) terbukti gagal (RED).

**2. FormData CRLF Normalization (BUG-005)**
- **Berkas**: `public/js/api.js` (`apiEncrypt` dan `apiDecrypt`)
- **Hipotesis (E0)**: Request HTTP yang memakai sintaks `FormData.append('text', ...)` secara spesifikasi HTML wajib menormalisasi karakter newline mandiri `\n` menjadi `\r\n` (CRLF). Akibatnya payload plain text dapat bertambah bytenya jika mengandung `\n`. Saat sampai ke API, server gagal mensterilkannya kembali. 
- **Invarian**: Melanggar I12 (Integritas UI tidak mengubah data secara diam-diam).
- **Tes**: `bug_005_crlf_normalization_test.rb` dibuat.

**3. URL.revokeObjectURL ditarik sewaktu Render (BUG-006)**
- **Berkas**: `public/js/result_panel.js`
- **Kutipan Kode**: `if (activeDownloadUrl) revokeBlobUrl(activeDownloadUrl);`
- **Hipotesis (E0)**: `revokeBlobUrl` dijalankan dalam methode `clear()` yang tereksekusi segera setiap kali form dikirim. Hal ini bisa saja membunuh object URL yang masih proses diunduh oleh peramban jika user cepat-cepat menekan klik. (PERLU KEPUTUSAN)
- **Invarian**: Gangguan pada fungsi GUI (I12).
