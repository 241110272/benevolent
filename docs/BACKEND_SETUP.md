# Backend LangkahKerja — Supabase

Kode sudah disiapkan. **Belum diterapkan pada proyek Supabase mana pun**, sesuai permintaan pemilik. Jangan memakai proyek lain tanpa memastikan tujuannya.

## 1. Buat proyek dan konfigurasi aplikasi

1. Buat proyek Supabase milik tim Benelovent. Pilih region dan paket sesuai kebutuhan; tinjau biaya sebelum membuat sumber daya berbayar.
2. Salin `config/env.example.json` menjadi `config/env.json`.
3. Isi `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` dari panel Connect/API Keys. Gunakan publishable key atau legacy **anon** key. **Jangan masukkan service-role key ke aplikasi.**
4. Setelah halaman legal dihosting, isi `PRIVACY_URL` dan `DELETION_URL` dengan URL HTTPS publik yang sebenarnya.
5. Jalankan:

```powershell
flutter run --dart-define-from-file=config/env.json
```

Tanpa konfigurasi, aplikasi tetap memiliki fitur lokal dan mode demo berlabel. Login dan feed Indonesia tidak berpura-pura aktif.

## 2. Pasang skema dan kebijakan akses

Dengan Supabase CLI resmi yang sudah login ke akun tim:

```powershell
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy delete-account --no-verify-jwt
supabase functions deploy import-jobs --no-verify-jwt
```

Alternatif: jalankan isi `supabase/migrations/202610170001_initial.sql` di SQL Editor proyek, kemudian deploy dua Edge Function melalui CLI/dashboard. Jalankan migrasi satu kali; jangan menyalin berulang ke database yang sudah memiliki tabel bernama sama.

Tabel dan batas akses:

| Tabel | Akses aplikasi |
| --- | --- |
| `jobs` | Publik hanya dapat membaca lowongan Indonesia yang diterbitkan dan belum kedaluwarsa |
| `user_state` | Pengguna terautentikasi hanya dapat membaca datanya sendiri |
| `job_reports` | Pengguna dapat mengirim dan melihat laporannya sendiri; maksimal 20/24 jam |

Perubahan `user_state` hanya melalui RPC `sync_user_state`, yang memeriksa UID server dan nomor revisi. Perubahan bersamaan menghasilkan konflik, kemudian pengguna memilih versi akun/perangkat secara eksplisit. Tidak ada penimpaan otomatis berdasarkan jam perangkat.

`delete-account` memverifikasi bearer token melalui Auth dan mewajibkan sign-in nyata dalam 10 menit terakhir. Penghapusan pengguna memicu cascade untuk data akun dan laporan. `verify_jwt=false` hanya mematikan verifier gateway; fungsi tetap melakukan verifikasi sendiri. `import-jobs` hanya menerima token admin rahasia melalui header dan bukan endpoint yang dipanggil aplikasi.

## 3. Email OTP

Aktifkan Email provider dan konfirmasi email. Gunakan kode OTP, bukan ketergantungan pada deep link:

1. Di template email **Confirm signup** dan **Magic Link**, tampilkan `{{ .Token }}` sebagai kode masuk.
2. Atur OTP 6 digit, kedaluwarsa 10 menit. Lakukan uji akun baru dan akun lama.
3. Pasang SMTP/domain pengirim yang dimiliki tim. Pengirim email bawaan biasanya memiliki pembatasan untuk pengembangan; uji pengiriman ke penerima di luar tim sebelum produksi.
4. Konfigurasikan batas pengiriman yang sesuai kemampuan layanan dan pantau penyalahgunaan. Jangan menonaktifkan pembatasan Auth.
5. Jika mengaktifkan CAPTCHA di Auth, lengkapi integrasi widget/token pada klien terlebih dahulu; build saat ini belum memiliki widget CAPTCHA.

Token sesi Android/iOS memakai `flutter_secure_storage`. Preview browser menyimpan sesi melalui penyimpanan browser. Password email tidak disimpan aplikasi.

## 4. Feed Indonesia

Tidak ada scraping Glints/JobStreet/Karirhub. Aplikasi membaca tabel `jobs` milik backend; tabel awal kosong. Pilihan mengisinya:

### A. Kurasi lowongan yang boleh diterbitkan

Masukkan melalui SQL Editor/admin server dengan `country='ID'`, `published=true`, `expires_at` valid, dan `payload` mengikuti contoh berikut. Jangan menyimpan data demo sebagai lowongan produksi.

```json
{
  "slug": "source-unique-id",
  "title": "Nama posisi",
  "company_name": "Nama perusahaan",
  "location": "Jakarta, Indonesia",
  "description": "<p>Deskripsi yang boleh diterbitkan.</p>",
  "url": "https://situs-sumber.example/lowongan",
  "remote": false,
  "tags": ["Technology"],
  "job_types": ["Full-time"],
  "source": "Nama sumber",
  "demo": false,
  "created_at": 1792198800
}
```

`jobs.id` harus sama dengan `payload.slug`. Tanggal `created_at` adalah Unix timestamp dari sumber, bukan tanggal yang dibuat untuk membuat iklan lama terlihat baru. Jika tidak tersedia, gunakan `null`.

### B. Importer Jooble yang sudah disiapkan

[Dokumentasi API Jooble](https://help.jooble.org/en/support/solutions/articles/60001448238) menjelaskan akses berbasis API key. Daftar key melalui provider dan pastikan izin penggunaan, cakupan Indonesia, ketentuan atribusi, serta penyimpanan/deskripsi sebelum mengaktifkan. Adanya endpoint API tidak otomatis berarti semua bentuk redistribusi disetujui.

Simpan `JOOBLE_API_KEY`, `JOB_IMPORT_TOKEN` (acak minimal 32 karakter), dan `JOOBLE_LICENSE_CONFIRMED=true` sebagai **Edge Function secrets** melalui dashboard atau secret file lokal. Jangan menyimpannya di Git atau `config/env.json`.

Importer memanggil endpoint resmi Jooble dengan lokasi `Indonesia`, maksimal tiga halaman per eksekusi. Data dideduplikasi menggunakan ID sumber dan otomatis berhenti ditayangkan setelah 14 hari dari tanggal sumber. Hasil lokal, kelengkapan tanggal, ketentuan lokasi, dan jumlah lowongan harus diperiksa menggunakan key tim sebelum dinyatakan siap produksi.

Jalankan admin-only `POST /functions/v1/import-jobs` dengan header `x-import-token`. Jadwalkan pengambilan ulang sesuai batas provider **setelah** hak penggunaan dan kuota diverifikasi. Jangan memasukkan token ini ke aplikasi. Lowongan tutup harus di-unpublish oleh kurator meskipun TTL belum habis.

## 5. Moderasi dan operasional

- Pantau `job_reports` di dashboard dan tindak lanjuti dugaan penipuan/lowongan tutup. Menekan tombol lapor tidak berarti iklan sudah otomatis diturunkan.
- Unpublish lowongan bermasalah melalui akses admin server. Klien tidak memiliki hak menulis feed.
- Tetapkan siapa yang memantau `sastraxez@gmail.com`, menangani permintaan penghapusan akun, dan memulihkan layanan.
- Tinjau retensi log dan backup Supabase; cocokkan dengan kebijakan privasi publik.
- Jangan mencatat OTP, access token, catatan pribadi, atau isi berkas ekspor ke log.
- Siapkan backup database, pemantauan kesalahan server/kuota, dan prosedur pemulihan.

## 6. Uji dua akun sebelum rilis

1. Buat akun A dan B lewat OTP. A menyimpan catatan; B tidak boleh bisa membacanya.
2. Masuk akun A di dua perangkat; sinkronkan perubahan. Simulasikan dua perubahan offline dan pastikan konflik ditampilkan, bukan ditimpa diam-diam.
3. Putus koneksi, catat lamaran, tutup/buka aplikasi, sambungkan ulang. Data lokal harus tetap ada.
4. Keluar dari A lalu masuk B; tidak boleh ada data A yang terlihat atau terunggah ke B.
5. Kirim laporan duplikat/berlebih; backend harus menolaknya tanpa mengirim sukses palsu.
6. Hapus akun A setelah verifikasi ulang; pastikan pengguna Auth, `user_state`, dan laporannya terhapus. Uji juga halaman penghapusan publik.

Referensi: [Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [email OTP](https://supabase.com/docs/guides/auth/auth-email-passwordless).
