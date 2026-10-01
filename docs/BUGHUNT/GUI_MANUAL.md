# Pengecekan Manual GUI

## Skenario Tes
1. **Dekripsi Berkas .dat**
   - [ ] Pilihan cipher otomatis terisi dengan benar (Inspect header)
   - [ ] Menggunakan kunci yang salah: Integrity badge harus berwarna merah/false.
   - [ ] Menggunakan kunci yang benar: Integrity badge harus hijau/true.
   - [ ] File diunduh dengan nama asli (`nama_asli.ext`) bukan `cipher_output.dat`.
   - [ ] Buka berkas hasil unduhan untuk verifikasi integritas bit.
   - [ ] Jika file berupa gambar/teks, panel pratinjau (preview) terbuka otomatis.
2. **Dekripsi Teks Tempelan (Base64/Hex/Huruf)**
   - [ ] Teks dengan baris baru `\n` tidak mengalami duplikasi atau penambahan panjang aneh.
   - [ ] Base64 yang tidak valid menampilkan pesan error dengan rapi (tidak 500).
   - [ ] Mode *alpha_filter* membuang karakter non-alfabetik pada input.
3. **Navigasi & Interaksi Cepat**
   - [ ] Ganti cipher/sumber di tengah proses: form disesuaikan otomatis tanpa nyangkut.
   - [ ] Klik Submit berkali-kali cepat (Spam): Hasil tidak tumpang tindih. (Catatan: Bug ditemukan pada `activeController`).
4. **Kenyamanan Visual**
   - [ ] Layar sempit memicu desain responsif (tabel dan tab menyesuaikan).
   - [ ] Tema gelap/terang tersimpan di preferensi.
   - [ ] Tombol *Copy* menyalin dengan format yang sesuai.

*Catatan: Tes dijalankan menggunakan Node JS pada sebagian komponen, sisanya lewat inspeksi manual browser.*
