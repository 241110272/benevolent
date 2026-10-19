# LangkahKerja

**Versi kandidat 1.1.0+2** · Flutter · SDG 8 · Pengembang **Benelovent**

Repository **benevolent** — Smart Decent Wealth and Work Growth App.

Aplikasi untuk mencari lowongan Indonesia dan mengelola perjalanan melamar. UI mengikuti referensi plum–lavender, dengan font dan banner foto yang dibundel lokal.

## Jalankan

Direkomendasikan Flutter **3.47.7** (versi yang dipakai menguji proyek ini). Android membutuhkan JDK 21 dan Android SDK platform 36.

```powershell
flutter pub get
flutter run -d chrome
# Dengan backend yang sudah disiapkan:
flutter run --dart-define-from-file=config/env.json
```

Pada komputer ini, Flutter ada di `C:\Users\sastr\.codex\tools\flutter\bin\flutter.bat`. Gunakan path tersebut jika Flutter belum masuk PATH.

## Fitur

- Onboarding dan kebijakan privasi berbahasa Indonesia.
- Feed Indonesia dari backend, cache offline, refresh, pagination, pencarian, kategori, filter kota/tipe/tanggal/remote/preferensi, dan urutan tanggal.
- Favorit, riwayat pencarian, serta kombinasi pencarian tersimpan.
- Detail lowongan, sumber, gaji bila tersedia, tautan lamaran asli, berbagi, dan pelaporan masalah.
- Lamaran manual dari sumber di luar aplikasi; status, catatan pribadi, riwayat perubahan, dan agenda follow-up.
- Pengingat lokal opsional pada Android/iOS. Browser hanya menampilkan agenda.
- Login/daftar lewat kode email, sesi aman di perangkat mobile, sinkronisasi revisi, pemisahan akun, dan penyelesaian konflik.
- Ekspor cadangan JSON, pemulihan tervalidasi, ekspor CSV, penghapusan data/cache, dan penghapusan akun.
- Checklist persiapan serta materi CV, portofolio, interview, dan keamanan lowongan.
- Ikon aplikasi, konfigurasi signing rilis, CI, skema SQL/RLS, Edge Functions, halaman privasi/penghapusan publik, dan draf listing Play Store.

**Status integrasi:** sesuai permintaan pemilik, Supabase hanya disiapkan sebagai kode dan panduan; belum diterapkan ke proyek mana pun. Feed Indonesia memerlukan data kurasi berizin atau API provider yang sudah disetujui. Tanpa konfigurasi, fitur lokal dan mode demo tetap bisa dicoba; login/feed tidak menampilkan sukses palsu.

## Dokumen penting

- [Setup backend, akun, dan sumber Indonesia](docs/BACKEND_SETUP.md)
- [Gerbang rilis, signing, dan Play Console](docs/RELEASE.md)
- [APK debug dan pengujian Android](docs/ANDROID_TESTING.md)
- [Bukti dan batas validasi](docs/VALIDATION.md)
- [Draf materi Play Store](docs/store/LISTING.md)
- [Kebijakan privasi publik](docs/legal/privacy.html)
- [Halaman penghapusan akun publik](docs/legal/delete-account.html)
- [Aset foto/font dan prompt](assets/README.md)

Lowongan demo selalu berlabel dan bukan lowongan aktif. Lamaran dilakukan pada situs sumber; status diperbarui oleh pengguna sendiri. Tidak ada pengiriman CV otomatis atau klaim lowongan telah diverifikasi secara independen.

## Pengujian

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
```

Pengujian SQL lokal memakai PostgreSQL/WASM dan tidak menyentuh proyek Supabase:

```powershell
npm install --prefix .tools/backend-tests @electric-sql/pglite@0.5.10
node scripts/backend_test.mjs
```

Ini memeriksa pembatasan feed publik, isolasi data per akun, revisi konflik, kuota laporan, dan cascade penghapusan akun. Uji email OTP, perangkat Android/iOS, sinkronisasi dua perangkat, serta notifikasi native tetap harus dijalankan pada konfigurasi nyata sebelum rilis.

## Mencoba alur lokal

1. Selesaikan onboarding, buka Eksplorasi, dan pilih **Coba mode demo** atau **Gunakan demo** saat sumber belum terhubung.
2. Cari posisi, coba kategori/filter, dan simpan pencarian.
3. Buka detail, simpan favorit, pilih status, tulis catatan lalu **Simpan catatan**.
4. Tambahkan agenda. Pada Android/iOS, aktifkan notifikasi jika diinginkan.
5. Di Lamaran, pilih **Catat lowongan sendiri** untuk peluang dari luar aplikasi.
6. Buka Profil → Bekal karier, Data & privasi, atau Akun & sinkronisasi.
7. Ekspor cadangan, muat ulang aplikasi, dan periksa pemulihan data.

## Struktur

```text
lib/models/       Model lowongan, status, riwayat, pencarian tersimpan
lib/services/     SQLite/prefs, API, cloud sync, ekspor, notifikasi
lib/screens/      Beranda, eksplorasi, detail, akun, agenda, privasi, materi
lib/widgets/      Komponen tema bersama
supabase/         Migrasi RLS dan Edge Functions (belum dideploy)
docs/             Panduan rilis, backend, legal, dan listing
scripts/          Validasi rilis, ikon, legal, dan tes SQL
test/             Pengujian logika, keamanan, cloud mock, dan alur UI
```

Lisensi proyek mengikuti [GPL-3.0](LICENSE). Lisensi font Manrope ada di `assets/fonts/OFL-Manrope.txt`.
