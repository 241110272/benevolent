# Status dan gerbang rilis LangkahKerja

Versi kandidat: **1.1.0+2**. Pengembang: **Benelovent**. Kontak: **sastraxez@gmail.com**.

Kode fitur bukan bukti persetujuan Play Store. Jangan mengunggah build dengan akun/feed belum tersambung dan jangan menyatakan pengujian perangkat lulus hanya dari widget test.

## Yang disiapkan dalam kode

- Tema mobile plum–lavender, logo dan ikon aplikasi sendiri, onboarding serta Bahasa Indonesia.
- Feed Indonesia dari backend dengan cache publik, pencarian/filter, favorit, pencarian tersimpan, dan mode demo berlabel.
- Catatan lamaran manual, status, riwayat, catatan eksplisit, agenda, serta notifikasi lokal opt-in.
- Login email OTP, sesi tersimpan aman pada Android/iOS, sinkronisasi revisi, penyelesaian konflik, dan pemisahan data antar-akun.
- Ekspor JSON/CSV, impor tervalidasi, kontrol penghapusan data, checklist dan materi karier.
- Pelaporan lowongan, kebijakan privasi, kontak dukungan, penghapusan akun di aplikasi, dan halaman penghapusan publik.
- Skema SQL/RLS, Edge Function penghapusan akun, importer server, CI, dan signing release yang menolak debug key.

## Wajib diselesaikan sebelum pengajuan

1. **Backend nyata**: terapkan dan uji [BACKEND_SETUP.md](BACKEND_SETUP.md). Sesuai pilihan pemilik, proyek Supabase tidak diubah otomatis dalam pekerjaan ini.
2. **Feed berizin**: dapatkan persetujuan/key provider atau isi feed kurasi yang memiliki hak publikasi. Verifikasi bahwa hasilnya memang lowongan Indonesia dan tautan lamaran berfungsi. Jangan memakai data demo sebagai feed produksi.
3. **Email**: siapkan SMTP/domain pengirim dan uji kode akun baru/lama, resend, kedaluwarsa, pembatasan, logout, serta penghapusan.
4. **Halaman legal publik**: host `docs/legal/privacy.html` dan `docs/legal/delete-account.html`, isi konfigurasi halaman penghapusan, pastikan URL HTTPS dapat dibaca tanpa login. Isi URL pada aplikasi dan Play Console.
5. **Build Android**: toolchain pada komputer pengembangan sudah disiapkan pada 18 Oktober 2026; lihat [bukti validasi](VALIDATION.md). Pada komputer lain, pasang JDK 21 dan Android SDK (platform 35/36, Build-Tools 36.0.0, NDK 28.2.13676358, CMake 3.22.1). Tinjau lisensi SDK dan jalankan `flutter doctor`.
6. **Kunci rilis**: buat dan simpan upload keystore secara aman di luar repo. Salin `android/key.properties.example` ke `android/key.properties`, isi nilai lokal. Jangan commit kunci/password. Aktifkan Play App Signing pada konsol sesuai kebutuhan tim.
7. **Perangkat nyata/emulator**: uji cold start, offline, database lama/migrasi, keyboard, teks besar, back gesture, dua akun/dua perangkat, pengingat, izin ditolak, reboot, link eksternal, berbagi, serta ekspor/impor. Verifikasi native library mendukung page size 16 KB.
8. **Play Console**: akun pengembang, verifikasi identitas, content rating, audiens, deklarasi iklan, Data safety, URL penghapusan, akses reviewer, dan materi listing. Penuhi pengujian tertutup jika berlaku pada akun tim.

## Bundle rilis

Identitas Android yang disiapkan: `id.benelovent.langkahkerja`. Tetapkan sebelum pengajuan pertama; package name tidak bisa diganti untuk aplikasi yang sama setelah terbit.

```powershell
python scripts/check_release.py
powershell -ExecutionPolicy Bypass -File scripts/release.ps1
# Atau dengan Flutter yang disiapkan pada komputer ini:
powershell -ExecutionPolicy Bypass -File scripts/release.ps1 -Flutter C:\Users\sastr\.codex\tools\flutter\bin\flutter.bat
```

Output sukses: `build/app/outputs/bundle/release/app-release.aab`. Skrip menolak konfigurasi publik yang kosong, service-role key, atau signing yang belum lengkap. **Lolos skrip tetap tidak menggantikan uji backend/perangkat dan review kebijakan.**

Konfigurasi Gradle menargetkan API 36 dan tidak memakai debug key untuk release. Pengingat memakai jadwal inexact sehingga tidak meminta exact-alarm permission. Manifest APK yang diperiksa memuat internet, notifikasi opsional, getaran, dan menerima boot untuk menjadwalkan ulang pengingat. AndroidX juga menambahkan permission signature internal untuk melindungi receiver. Tidak ada izin lokasi, kontak, kamera, atau akses semua berkas. Android OS backup untuk data aplikasi dinonaktifkan; ekspor dan sinkronisasi dikendalikan pengguna.

## Draf Data safety — verifikasi sesuai konfigurasi produksi

Jangan memilih “tidak mengumpulkan data” jika sinkronisasi diaktifkan. Minimal tinjau email (autentikasi), nama panggilan, preferensi, pencarian tersimpan/riwayat, catatan pengguna, status/agenda, serta laporan yang dikirim ke Supabase. Koneksi backend/provider juga dapat menghasilkan metadata teknis dan log. Klasifikasi dan retensi harus disesuaikan dengan pengaturan backend yang sebenarnya, bukan ditebak dari daftar dependency.

JSON/CSV dibagikan hanya atas tindakan pengguna melalui share sheet. Deskripsi HTML dibersihkan dari gambar eksternal, skrip, iframe, dan atribut pelacak. Tautan lamaran membuka browser eksternal; tidak ada pengiriman CV/lamaran otomatis.

## Pengingat

Tanggal agenda tersinkron, tetapi izin dan jadwal notifikasi berlaku per perangkat. User mengaktifkan pengingat secara eksplisit pada detail lamaran. Browser hanya menampilkan agenda dan tidak menjanjikan notifikasi latar belakang. Pengiriman inexact dapat tertunda oleh pengaturan perangkat. Uji Android 13+ (izin notifikasi), force-stop, reboot, dan perubahan zona waktu sebelum rilis.

## Referensi kebijakan yang diperiksa 17 Oktober 2026

- [Target API Google Play](https://support.google.com/googleplay/android-developer/answer/11926878): sejak 31 Agustus 2026 aplikasi baru/pembaruan ponsel menargetkan API 36 atau lebih tinggi.
- [User Data / kebijakan privasi](https://support.google.com/googleplay/android-developer/answer/10144311).
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469).
- [Persyaratan penghapusan akun](https://support.google.com/googleplay/android-developer/answer/13327111).
- [Pengujian akun pengembang pribadi](https://support.google.com/googleplay/android-developer/answer/14151465).
- [Dukungan page size 16 KB](https://developer.android.com/guide/practices/page-sizes).
