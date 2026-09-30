# Aturan Agen (berlaku untuk semua tahap)

## 1. Anti-halusinasi (WAJIB)
1. Jangan pernah menulis "tes lulus", "berhasil", atau "sudah diverifikasi" tanpa menjalankan perintahnya dan menampilkan keluaran nyata.
2. Jangan mengarang nama gem, method, opsi CLI, atau versi. Periksa dengan `gem list`, `bundle exec ruby -e '...'`, `ri`, atau dokumentasi lokal. Jika tidak dapat diperiksa, katakan tidak tahu.
3. Konstanta kriptografi (kabel rotor Enigma, vektor uji) hanya boleh berasal dari prompt tahap yang bersangkutan. Jika tampak salah, jangan mengubahnya diam-diam: analisis, tunjukkan bukti, dan laporkan kepada pengguna.
4. Jika ragu atau ada kekosongan spesifikasi, catat sebagai "ASUMSI" di `docs/DECISIONS.md` bagian Asumsi Tambahan dan laporkan. Jangan memutuskan secara diam-diam.
5. Jangan memalsukan tangkapan layar, log, atau hasil uji. Jika sesuatu tidak dapat dijalankan (misalnya tidak ada browser), tulis "TIDAK DIVERIFIKASI" beserta alasannya.
6. Jika perintah gagal, tampilkan pesan error aslinya, temukan akar masalah, lalu perbaiki. Dilarang menghapus atau melemahkan tes agar lolos.
7. Jangan menambah fitur di luar spesifikasi tanpa mencatatnya dan meminta persetujuan.

## 2. Kualitas kode
1. Ruby idiomatik, modul berada di bawah namespace `CipherWorkbench`. Satu tanggung jawab per berkas.
2. Setiap cipher diimplementasikan dari nol (aritmetika modular sendiri). Dilarang memakai gem kriptografi untuk logika cipher.
3. Tanpa dependensi runtime yang tidak perlu. Gunakan `[str].pack('m0')` dan `unpack1('m0')` untuk base64 (gem `base64` tidak lagi default di Ruby terbaru). `digest`, `json`, `securerandom`, `zlib` adalah pustaka standar.
4. Nama identifier dalam bahasa Inggris. Komentar dan pesan UI dalam bahasa Indonesia, singkat, menjelaskan "mengapa" (bukan mengulang kode).
5. Tidak ada emoji di kode, UI, atau dokumen.
6. Semua input pengguna divalidasi di server. Pesan error dalam bahasa Indonesia, jelas dan dapat ditindaklanjuti.

## 3. Keamanan dan privasi
1. Kunci dan isi pesan/berkas TIDAK BOLEH ditulis ke log, ke disk, atau ke stdout. Server stateless.
2. Tanpa CDN, tanpa font eksternal, tanpa telemetri, tanpa panggilan jaringan saat runtime. Aplikasi harus berjalan offline.
3. Di frontend, render teks dari pengguna/server dengan `textContent`, bukan `innerHTML`, untuk mencegah XSS.
4. Server hanya mengikat ke `127.0.0.1` secara default.

## 4. Proses
1. Kerjakan HANYA tahap yang diminta. Jangan mengerjakan tahap berikutnya.
2. Awali setiap tahap dengan membaca tiga berkas di `docs/`, lalu tulis rencana singkat (maksimal 15 baris) sebelum mengubah berkas.
3. Akhiri setiap tahap dengan: jalankan seluruh tes, commit git dengan pesan berformat `stage-N: ringkasan`, dan perbarui `docs/PROGRESS.md` (buat bila belum ada).
4. Perubahan pada berkas tahap sebelumnya diperbolehkan hanya bila perlu, dan harus dilaporkan beserta alasannya.

## 5. Definisi selesai (berlaku umum)
Semua tes lulus dengan keluaran nyata ditampilkan; tidak ada peringatan yang diabaikan tanpa penjelasan; berkas baru tercantum dalam laporan; tidak ada TODO tersisa yang tidak dilaporkan.

## 6. Format laporan akhir tahap
1. Ringkasan (maksimal 5 kalimat).
2. Berkas dibuat/diubah (pohon direktori singkat).
3. Perintah yang dijalankan beserta ringkasan keluaran NYATA (salin baris kunci, mis. jumlah tes dan status).
4. Pemeriksaan kriteria selesai: tabel [kriteria | LULUS/GAGAL/TIDAK DIVERIFIKASI | bukti].
5. Asumsi dan masalah terbuka.
6. Langkah berikutnya yang disarankan (satu kalimat).
