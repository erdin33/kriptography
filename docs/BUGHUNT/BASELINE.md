# Baseline Lingkungan dan Pengujian (BH1)

## Lingkungan
- **Sistem Operasi**: Darwin Luthfi-Macbook-Pro-M1.local 23.4.0 (arm64)
- **Ruby**: ruby 2.6.10p210 (2022-04-12 revision 67958) [universal.arm64e-darwin23]
- **Bundler**: Bundler version 2.5.3
- **Encoding Ruby**: 
  - `Encoding.default_external`: `#<Encoding:US-ASCII>`
  - `Encoding.default_internal`: `nil`
- **Lokal Sistem (`$LANG` / `$LC_ALL`)**: (kosong / tidak diset)

## Repository
- **Cabang**: `bughunt/decrypt`
- **Hash HEAD**: `8291f76727a8221fd46dbc1f96bfe3025fdaa98f`

## Hasil Eksekusi `rake test`
- **Total Tes**: 93 runs
- **Total Asersi**: 15304 assertions
- **Kegagalan / Error**: 0 failures, 1 errors, 0 skips.
- **Waktu Eksekusi**: ~4.92s

### Catatan Error pada Baseline (Kandidat Bug - Tingkat E1)
1. **Error `GuiTest#test_no_external_assets`**: `ArgumentError: invalid byte sequence in US-ASCII`. 
   - Ini disebabkan tes mencoba membaca file biner (`public/favicon.ico`) sebagai file teks di lingkungan di mana `Encoding.default_external` jatuh ke `US-ASCII` (karena `$LANG`/`$LC_ALL` kosong). Error ini tidak akan langsung diperbaiki di fase BH1.

## Hasil Eksekusi `rake roundtrip`
- **Status**: Semua tes roundtrip 12 file untuk 8 cipher (termasuk `.bin`, `.wav`, `.png`, `.pdf`) berstatus **LULUS**. Waktu enkripsi/dekripsi berkas `1mb.bin` paling lama membutuhkan ~4.8s pada Enigma, lainnya di kisaran ~1-2s.

