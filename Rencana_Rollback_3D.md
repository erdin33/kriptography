# Rencana Rollback 3D

| Keterangan | Detil |
| --- | --- |
| **Skenario** | **Skenario A** (Cabang 3D `feature/viz-3d` terpisah dan belum digabung ke `main`) |
| **BASE Commit** | `8291f76` (Commit `main` di mana `feature/viz-3d` bermula). Kita tidak menggunakan `v1.0.0-uts` secara langsung agar tidak kehilangan *bug fix* (Non-3D) yang telah di-commit ke `main` paska UTS. |
| **Commit 3D (Dibatalkan/Diarsipkan)** | `340608a` dan `28f539c` (Tahap 12 & 14) serta komit *WIP* pada branch `backup/viz-3d-wip-20261001-0731` (memuat Tahap 13, 15, 16, 17 yang belum terkomit di branch aslinya). |
| **Commit Non-3D (Dipertahankan)** | `8291f76`, `991c5a5`, `a9e1ca6`, `47b7b4f`, `370846e` (semua *bug fix* tetap aman di `main`). |
| **Berkas TIDAK DIKENAL** | Tidak ada. Semua berkas tak terlacak sudah dicadangkan secara sempurna. |
| **Perbaikan Perilaku di luar 3D** | Tidak ada. |
| **Status Remote** | Belum ada cabang 3D yang di-*push* ke remote (Aman). |
| **Perintah Destruktif** | Tidak ada. Pekerjaan 3D diarsipkan. |
| **Perintah Eksekusi** | `git switch main` lalu `git branch -m feature/viz-3d archive/viz-3d-20261001-0731` |
| **Cara Memulihkan 3D** | `git switch backup/viz-3d-wip-20261001-0731` (untuk melanjutkan pekerjaan 3D terbaru). |
