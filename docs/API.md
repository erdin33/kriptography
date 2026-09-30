# Dokumentasi API REST Cipher Workbench

Semua permintaan ditujukan ke rute `/api/*` dengan respons berupa JSON berformat `UTF-8`. Endpoint dekripsi dan enkripsi menerima formulir bergaya `multipart/form-data`. API bersifat stateless tanpa menyimpan sesi, berkas sementara, maupun data logging teks terang.

## 1. Daftar Cipher (`GET /api/ciphers`)
Mengembalikan daftar algoritma cipher yang terdaftar.

**Permintaan:**
```bash
curl -X GET http://localhost:4567/api/ciphers
```

**Contoh Respons Sukses (200 OK):**
```json
{
  "ok": true,
  "ciphers": [
    {
      "id": "vigenere",
      "title": "Vigenere Cipher",
      "group": "classic26",
      "domain": "letters",
      "summary": "Cipher substitusi polialfabetik...",
      "fields": [
        {
          "name": "key",
          "type": "text",
          "label": "Kunci",
          "help": "Kata kunci (hanya A-Z)."
        }
      ]
    }
  ],
  "limits": {
    "max_upload_bytes": 26214400,
    "display_limit_bytes": 65536
  }
}
```
*Catatan: Cipher dengan grup `internal` atau atribut `hidden` tidak disertakan di sini.*

## 2. Enkripsi (`POST /api/encrypt`)
Menerima teks biasa atau berkas mentah untuk dienkripsi.

**Permintaan (Contoh Teks Vigenere):**
```bash
curl -X POST http://localhost:4567/api/encrypt \
  -F "cipher=vigenere" \
  -F 'params={"key":"LEMON"}' \
  -F "input_type=text" \
  -F "text=ATTACKATDAWN"
```

**Contoh Respons Sukses (200 OK):**
```json
{
  "ok": true,
  "cipher": "vigenere",
  "input": {
    "kind": "text",
    "filename": "",
    "bytes": 12,
    "encoding": "alpha_filter",
    "used_symbols": 12,
    "plain_base64": "QVRUQUNLQVREQVdO",
    "plain_truncated": false,
    "plain_total_bytes": 12
  },
  "output": {
    "letters": "lxfopvefrnhr",
    "base64": "bHhmb3B2ZWZybmhy",
    "base64_truncated": false,
    "hex": "6c78666f70766566726e6872",
    "hex_truncated": false,
    "total_bytes": 12
  },
  "container_b64": "Q1dCMQEB...",
  "suggested_filename": "pesan-vigenere.dat",
  "key_info": {
    "normalized_key": "LEMON"
  }
}
```

**Permintaan (Contoh Berkas Extended Vigenere):**
```bash
echo "Ini rahasia" > rahasia.txt
curl -X POST http://localhost:4567/api/encrypt \
  -F "cipher=extended_vigenere" \
  -F 'params={"key":"KUNCI"}' \
  -F "input_type=file" \
  -F "file=@rahasia.txt"
```
*(Menyimpan `container_b64` dan mendekodenya dari base64 akan menghasilkan berkas `.dat` biner).*

## 3. Dekripsi (`POST /api/decrypt`)
Mendekripsi pesan dari payload teks tempelan maupun container biner utuh.

**Permintaan (Contoh Dekripsi Berkas Container):**
```bash
curl -X POST http://localhost:4567/api/decrypt \
  -F "cipher=extended_vigenere" \
  -F 'params={"key":"KUNCI"}' \
  -F "source=container" \
  -F "file=@rahasia.txt.dat"
```

**Contoh Respons Sukses (200 OK):**
```json
{
  "ok": true,
  "cipher": "extended_vigenere",
  "kind": "file",
  "encoding": "raw",
  "filename": "rahasia.txt",
  "text": null,
  "text_valid": false,
  "plain_base64": "SW5pIHJhaGFzaWEK",
  "plain_truncated": false,
  "plain_total_bytes": 12,
  "mime_guess": "text/plain",
  "integrity": {
    "checked": true,
    "valid": true
  },
  "key_info": {
    "normalized_key_bytes": [75, 85, 78, 67, 73]
  },
  "plain_full_b64": "SW5pIHJhaGFzaWEK"
}
```

**Permintaan (Contoh Dekripsi Teks):**
```bash
curl -X POST http://localhost:4567/api/decrypt \
  -F "cipher=vigenere" \
  -F 'params={"key":"LEMON"}' \
  -F "source=text" \
  -F "text_format=letters" \
  -F "text=lxfopvefrnhr"
```

## 4. Inspeksi Container (`POST /api/inspect`)
Mengekstrak metadata non-rahasia dari awal berkas container. Berguna untuk mendeteksi cipher secara otomatis.

**Permintaan:**
```bash
curl -X POST http://localhost:4567/api/inspect \
  -F "file=@rahasia.txt.dat"
```

**Contoh Respons Sukses (200 OK):**
```json
{
  "ok": true,
  "cipher": "extended_vigenere",
  "kind": "file",
  "encoding": "raw",
  "filename": "rahasia.txt",
  "plain_length": 12,
  "payload_length": 12,
  "format_version": 1
}
```

## 5. Kode Kesalahan (Error Codes)
Aplikasi menjamin format respons di bawah ini bila terjadi kesalahan komputasi atau kegagalan penanganan parameter.

```json
{
  "ok": false,
  "error": "invalid_key",
  "message": "Kunci harus memuat minimal satu huruf",
  "field": "key"
}
```

Daftar error dan status HTTP yang berpadanan:
- `400 Bad Request`
  - `invalid_input`: Payload tak diset, file ketiadaan nilai, dll (klien mengirim borang tak beraturan).
  - `invalid_container`: Unggahan container bukan merupakan berkas `.dat` biner yang sesuai standar, rusak, terpotong, ataupun versi sihirnya beda.
  - `invalid_params`: Payload JSON kunci tidak berformat valid (misal salah petik ganda).
- `404 Not Found`
  - `unsupported_cipher`: ID Cipher tidak dikenali dalam registry yang tersedia.
- `409 Conflict`
  - `cipher_mismatch`: ID Cipher yang dimandatkan untuk dekripsi tidak sama dengan ID pada metadata container `.dat`.
- `413 Payload Too Large`
  - `payload_too_large`: Keseluruhan body HTTP melebihi ukuran maksimum (default 25 MB).
- `422 Unprocessable Entity`
  - `invalid_key`: Atribut kunci melanggar skema pembatasan (contoh: huruf tak lengkap, ukuran ring Enigma bukan bilangan bulat rentang yang benar).
  - `invalid_ciphertext`: Cipherteks untuk format Base64/Hex gagal didekode karena karakter selundupan.
- `500 Internal Server Error`
  - `internal_error`: Kerusakan parah dalam server; stack-trace tersembunyi namun dilampirkan via node *trace* opsional saat mode pengembangan.
