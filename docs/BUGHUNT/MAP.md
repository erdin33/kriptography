# Peta Jalur Dekripsi

Dokumen ini memetakan seluruh titik dalam jalur dekripsi pada sistem, baik di sisi *backend* (API, Service, Codec, Container, Cipher) maupun *frontend* (UI, Event Handlers, Fetch API, Decoding/Encoding respons).

## 1. Diagram Aliran (Backend & Frontend)

```mermaid
flowchart TD
    subgraph Frontend [UI Browser]
        UI1[Pengguna Input: Teks atau File] --> UI2[Pilih Cipher & Mode Dekripsi]
        UI2 --> UI3[main.js: btnProcess onclick]
        UI3 --> UI4{Input Teks atau File?}
        UI4 -- Teks --> UI5[api.js: apiDecrypt(source='text')]
        UI4 -- File --> UI6[api.js: apiDecrypt(source='container')]
        UI5 --> UI7[FormData dikirim via fetch]
        UI6 --> UI7
    end

    subgraph Backend [Server API & Service]
        B1[app.rb /api/decrypt] --> B2[Validasi Parameter Input]
        B2 --> B3{Sumber Container?}
        B3 -- Ya --> B4[Membaca bytes tempfile upload]
        B3 -- Tidak --> B5[Validasi format teks: letters/base64/hex]
        B4 --> B6[Service.decrypt]
        B5 --> B6
        
        B6 --> B7{Tipe Sumber}
        B7 -- Container --> B8[Container.unpack: Validasi header, panjang, SHA256]
        B7 -- Text --> B9[Format decode: from_base64 / from_hex / letters filter]
        
        B8 --> B10[Codec::LetterCodec.letters_to_symbols]
        B9 --> B10
        B10 --> B11[Cipher.decrypt: Algoritma Inti]
        B11 --> B12[Ubah symbols_to_letters atau bytes pack]
        B12 --> B13[Verifikasi Integritas SHA256 & length]
        B13 --> B14[Bentuk DecryptResult]
    end

    subgraph Cipher Classes [Modul Kriptografi]
        B11 --> C1[Vigenere / AutoKey / Affine / Playfair / Hill / Extended / Columnar / Super / Enigma]
    end

    subgraph API Response [Penyusunan Hasil]
        B14 --> R1[JSON Generator app.rb]
        R1 --> R2[Tebak MIME type (jika file)]
        R2 --> R3[Bentuk respons base64 plain_bytes, truncate dll.]
    end

    subgraph Frontend Render [Render Hasil di UI]
        R3 --> F1[api.js: parse JSON]
        F1 --> F2[result_panel.js: renderResult]
        F2 --> F3[Update DOM: Badge Integritas, Tab (Letters/Base64/Hex), Tombol Download]
        F3 --> F4[download.js: decode base64 respons, bentuk Blob & URL]
    end
```

## 2. Tabel Pemetaan Komponen

| Komponen | Berkas:Fungsi | Input | Output | Error Potensial / Validasi |
|---|---|---|---|---|
| **API Rute** | `lib/cipher_workbench/api.rb : post '/api/decrypt'` | HTTP `POST` FormData (`cipher`, `params`, `source`, `text`/`file`, dll) | JSON HTTP Response (200 / 400 / 404 / 413 / 422 / 500) | `InvalidInputError`, `JSON::ParserError`, Limit payload `413` |
| **Service (Text)** | `service.rb : decrypt (source: text)` | `payload_text`, format (`letters`/`base64`/`hex`) | `DecryptResult` (integrity = false) | `InvalidInputError`, `InvalidCiphertextError` (Base64/Hex salah) |
| **Service (Container)** | `service.rb : decrypt (source: container)` | Bytes dari unggahan file | `DecryptResult` (integrity = true/false) | `InvalidContainerError`, `CipherMismatchError` |
| **Container** | `container.rb : unpack` | `binary` (String ASCII-8BIT) | `HeaderData` (cipher_id, kind, encoding, payload, dll) | Terpotong, magic salah, sisa byte, invalid UTF-8 untuk filename |
| **LetterCodec** | `codec/letter_codec.rb : letters_to_symbols` | String huruf kapital | Array Integer 0..25 | - |
| **LetterCodec** | `codec/letter_codec.rb : symbols_to_letters` | Array Integer 0..25 | String huruf | - |
| **LetterCodec** | `codec/letter_codec.rb : nibble_decode` | String huruf ASCII | Bytes asli (String ASCII-8BIT) | Panjang ganjil, padding nibble tidak sesuai |
| **Cipher** | `ciphers/<name>.rb : decrypt` | Array symbol (Integer 0..25 atau 0..255) | Array symbol (Integer) setelah didekripsi | Kesalahan spesifik cipher (kunci salah, dll) |
| **UI API Client** | `public/js/api.js : apiDecrypt` | `cipherId`, `params`, `sourceType`, dll | Resolves JSON Response API | Abort, Jaringan putus, format JSON salah, HTTP bukan 2xx |
| **UI Main** | `public/js/main.js : btnProcess` | Klik dari user | Request state dikelola | Catch error dan diteruskan ke UI Error Banner |
| **UI Result** | `public/js/result_panel.js : renderResult` | Objek JSON Result dari API | DOM diperbarui (teks, blob unduhan) | - |
| **UI Download** | `public/js/download.js : createBlobUrl` | `Uint8Array`, `mime_guess` | URL dari Object URL Blob | Memori Blob tidak direvoke jika tidak hati-hati |

## 3. Titik Berisiko (Risk Points)
1. **Konversi Encoding dan Base64**: 
   - Di `app.rb`, `payload` `from_base64` / `from_hex` dipaksakan ke UTF-8 dan dipastikan ASCII-only sebelum didekripsi (untuk domain _letters_). Ini sangat rawan gagal jika user menyelipkan padding atau newline.
   - Pembangunan respons JSON: jika `plain_bytes` tidak valid UTF-8, JSON.generate bisa gagal (`Encoding::UndefinedConversionError`). Di sini di-bypass dengan mengubah plain menjadi `text` (jika valid) dan `plain_bytes` dirubah ke base64 (dengan `Codec::Views.base64`).
2. **Pack/Unpack Container (D6)**:
   - File biner bisa memiliki byte tambahan di belakang. `Container.unpack` memiliki pemeriksaan `offset + payload_len < binary.bytesize` untuk menolak sisa byte berlebih. 
   - Panjang payload (`payload_len`) didekode sebagai `Q>` (64-bit Big-Endian). Panjang salah bisa mengakibatkan memory exhaustion.
3. **Validasi Integritas SHA-256**:
   - Integritas file dicek via SHA-256 dan _plain length_. Ada potensi bypass jika panjang diubah secara sengaja dan cipher tidak mengubah spasi byte (misalnya cipher linear seperti Affine/Hill).
4. **State antar Panggilan**:
   - AutoKey / Enigma mempertahankan _state_ enkripsi. Dekripsi harus mereset state ini (terutama Enigma _stepping_, posisi _ring_, dll).
5. **Aritmetika Modular dan Tipe Data**:
   - Dekripsi _letters_ (0..25) vs _bytes_ (0..255). Array tidak boleh lolos dari batas mod ini (`nil` atau _out of bounds_ wrapping).

---
*(Dokumen MAP.md dibuat untuk panduan Fase BH1-BH4 Kriptografi Workbench)*
