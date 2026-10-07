# Cipher Workbench - UTS Kriptografi

Cipher Workbench merupakan aplikasi sederhana berbasis Ruby dan Sinatra yang digunakan untuk mencoba beberapa algoritma kriptografi. Aplikasi ini dibuat untuk memenuhi tugas UTS Mata Kuliah Kriptografi pada Program Studi Informatika.

Algoritma yang tersedia mencakup cipher klasik berbasis alfabet dan cipher yang bekerja pada data berbasis byte. Aplikasi juga mendukung proses enkripsi dan dekripsi teks maupun berkas.

## Fitur

Algoritma yang tersedia:

* **Vigenere Cipher** — domain alfabet 26
* **Auto-Key Vigenere Cipher** — domain alfabet 26
* **Extended Vigenere Cipher** — domain byte 0–255
* **Playfair Cipher** — domain alfabet 26
* **Affine Cipher** — domain alfabet 26
* **Hill Cipher** — domain alfabet 26 dengan ukuran matriks yang dapat disesuaikan
* **Cipher Transposisi Kolom** — digunakan sebagai bagian dari Super Enkripsi
* **Super Enkripsi** — kombinasi Extended Vigenere dan Transposisi Kolom
* **Enigma M3 Cipher** — fitur tambahan untuk simulasi Enigma

Aplikasi dapat digunakan untuk memproses teks maupun berkas, tergantung pada jenis cipher yang dipilih.

## Kebutuhan Sistem

Sebelum menjalankan aplikasi, pastikan perangkat sudah memiliki:

* Ruby 3.1, 3.2, atau 3.3
* Bundler
* Sistem operasi Linux atau macOS

Windows belum banyak diuji dalam pengembangan aplikasi ini.

## Instalasi

Clone repository terlebih dahulu, kemudian masuk ke direktori proyek.

```bash
bundle install
```

Perintah tersebut digunakan untuk memasang dependency yang dibutuhkan oleh aplikasi.

## Menjalankan Aplikasi

Jalankan server Sinatra dengan perintah:

```bash
bundle exec rackup -p 4567
```

Setelah server berjalan, buka browser dan akses:

```text
http://127.0.0.1:4567
```

## Pengujian

Beberapa perintah telah disediakan untuk membantu proses pengujian aplikasi.

Membuat berkas yang digunakan untuk pengujian:

```bash
bundle exec rake fixtures
```

Menjalankan pengujian:

```bash
bundle exec rake test
```

Menjalankan pengujian enkripsi dan dekripsi secara berulang untuk setiap cipher:

```bash
bundle exec rake roundtrip
```

Pengujian *round-trip* digunakan untuk memastikan data yang telah dienkripsi dapat dikembalikan ke bentuk semula setelah proses dekripsi.

## Struktur Direktori

```text
.
├── app.rb
├── lib/
│   └── cipher_workbench/
│       └── ciphers/
├── public/
│   └── js/
├── views/
├── docs/
├── fixtures/
└── test/
```

Keterangan beberapa direktori utama:

* `app.rb` — file utama untuk menjalankan aplikasi Sinatra.
* `lib/cipher_workbench/` — bagian utama yang berisi logika aplikasi dan algoritma kriptografi.
* `lib/cipher_workbench/ciphers/` — implementasi dari masing-masing algoritma cipher.
* `public/js/` — kode JavaScript yang digunakan pada antarmuka web.
* `views/` — file tampilan menggunakan ERB.
* `docs/` — dokumentasi dan catatan pengembangan.
* `fixtures/` — berkas yang digunakan untuk kebutuhan pengujian.
* `test/` — kumpulan pengujian menggunakan Minitest.

## Cara Menggunakan

### 1. Enkripsi Teks

Pilih algoritma yang ingin digunakan, kemudian pilih mode **Teks Ketikan**. Masukkan teks dan kunci yang diperlukan, lalu jalankan proses enkripsi.

### 2. Enkripsi Berkas

Pilih mode **Unggah Berkas**, kemudian pilih atau seret berkas ke area yang tersedia. Masukkan kunci dan jalankan proses.

Hasil enkripsi berkas dapat disimpan dalam bentuk wadah `.dat`.

### 3. Dekripsi Teks

Masukkan cipherteks pada bagian input teks. Pilih algoritma yang sesuai dan masukkan kunci yang digunakan saat proses enkripsi.

### 4. Dekripsi Berkas

Unggah berkas `.dat` hasil enkripsi, kemudian masukkan kunci yang sesuai. Setelah proses berhasil, berkas akan dikembalikan ke bentuk aslinya.

### 5. Menambahkan Berkas untuk Pengujian

Untuk melakukan pengujian menggunakan berkas sendiri, letakkan berkas pada:

```text
fixtures/manual/
```

Kemudian jalankan:

```bash
bundle exec rake roundtrip
```

## Variabel Lingkungan

Aplikasi menyediakan beberapa variabel lingkungan yang dapat diubah sesuai kebutuhan:

| Variabel        |       Default | Keterangan                                 |
| --------------- | ------------: | ------------------------------------------ |
| `PORT`          |        `4567` | Port yang digunakan server                 |
| `MAX_UPLOAD_MB` |          `25` | Ukuran maksimum berkas yang dapat diunggah |
| `RACK_ENV`      | `development` | Lingkungan eksekusi Rack                   |

Contoh:

```bash
PORT=3000 bundle exec rackup
```

## Keamanan dan Keterbatasan

Aplikasi ini dibuat untuk keperluan pembelajaran sehingga algoritma yang tersedia tidak semuanya ditujukan untuk penggunaan keamanan pada sistem nyata.

* **Cipher klasik** seperti Vigenere, Playfair, dan Affine memiliki kelemahan terhadap berbagai metode kriptanalisis. Algoritma tersebut digunakan untuk memahami konsep dasar kriptografi.
* **Metadata berkas** pada wadah `.dat` digunakan untuk membantu proses pengembalian berkas setelah dekripsi.
* **HMAC-SHA256** digunakan untuk membantu memeriksa integritas data pada wadah hasil enkripsi.
* Proses pada beberapa algoritma dapat menjadi lebih lambat ketika ukuran berkas semakin besar, terutama pada algoritma yang melakukan operasi secara berulang.

## Lisensi

Proyek ini dibuat untuk memenuhi tugas UTS Mata Kuliah Kriptografi. Penggunaan dan pengembangan lebih lanjut disesuaikan dengan kebutuhan perkuliahan.



module CipherWorkbench
  module Ciphers
    class ExtendedVigenere < Base
      def self.id; 'extended_vigenere'; end
      def self.title; 'Extended Vigenere Cipher'; end
      def self.group; :ascii256; end
      def self.domain; :bytes; end
      def self.summary; 'Varian Vigenere yang beroperasi pada tingkat byte (256 nilai), bukan hanya huruf. Karena dapat mengenkripsi karakter apa pun termasuk data biner murni, cipher ini cocok digunakan untuk mengenkripsi berkas.'; end

      def self.fields
        [
          {
            name: 'key',
            type: 'text',
            label: 'Kunci',
            help: 'Kunci teks bebas, akan diubah menjadi representasi byte UTF-8.'
          }
        ]
      end

      def validate_key!
        key_str = @params[:key] || @params['key'] || ""
        @key_bytes = key_str.dup.force_encoding('UTF-8').bytes
        
        if @key_bytes.empty?
          raise InvalidKeyError.new("Kunci tidak boleh kosong", field: 'key')
        end
      end

      def encrypt(symbols)
        m = @key_bytes.length
        symbols.map.with_index do |p, i|
          (p + @key_bytes[i % m]) % 256
        end
      end

      def decrypt(symbols)
        m = @key_bytes.length
        symbols.map.with_index do |c, i|
          (c - @key_bytes[i % m]) % 256
        end
      end

      def describe_key
        {
          key_bytes_hex: Codec::Views.hex(@key_bytes.pack('C*')),
          length: @key_bytes.length
        }
      end
    end
  end
end
