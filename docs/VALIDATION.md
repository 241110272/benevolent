# Pemeriksaan kandidat 1.1.0+2

Pemeriksaan terbaru: **18 Oktober 2026**, checkout lokal Windows. Pengembang: Benelovent.

## Hasil yang sudah diverifikasi

- `flutter pub get --offline`: dependensi terselesaikan dari cache lokal.
- `dart format lib test`: 29 berkas sudah diformat.
- `flutter analyze --no-pub`: tidak ada masalah.
- `flutter test --no-pub`: seluruh **24 pengujian lulus**. Mencakup onboarding, layar 320 piksel, teks 2×, lamaran manual, favorit/status/catatan, cadangan, Unicode/emoji pada batas input, pencarian panjang, cache offline, konflik dan pergantian akun, penutupan route pribadi, payload pengingat, sanitasi HTML, URL HTTPS, serta CSV.
- `flutter build apk --debug --no-pub`: berhasil. Build akhir setelah perubahan terbaru selesai dalam 78,6 detik; pemasangan toolchain/build pertama membutuhkan waktu lebih lama.
- `flutter build web --no-pub --no-wasm-dry-run`: berhasil, 49,4 detik. Font Material dan Cupertino tersedia.
- `scripts/check_android_apk.ps1`: tanda tangan APK v2 valid; ZIP alignment 16 KB lulus; segmen ELF/RELRO pada **7 pustaka 64 bit** lulus. Pemeriksaan RELRO mencakup segmen LOAD terpisah dan padding.
- Manifest APK diperiksa memakai `aapt`: label, activity, versi, SDK, ABI, dan permission sesuai hasil di bawah.

## APK uji

Lokasi: `build/app/outputs/flutter-apk/app-debug.apk`.

| Properti | Nilai |
|---|---|
| Identitas aplikasi | `id.benelovent.langkahkerja` |
| Versi | `1.1.0`, versionCode `2` |
| Minimum Android | API 24 / Android 7.0 |
| Target / compile SDK | 36 / 36 |
| ABI | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Ukuran | 171.656.240 byte, sekitar 163,7 MiB |
| Jenis | Debug, untuk pengujian |

SHA-256:

```text
57313a9cc17469fcc2be63b8f09e139d75ab5ff8e0f5ebd30b20f0c7c7c5516f
```

Permission hasil merge: internet, notifikasi, boot, getaran, serta permission signature internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` dari AndroidX. Tidak ditemukan permission lokasi, kontak, kamera, atau akses semua berkas.

## Toolchain yang tersedia

Flutter **3.47.7**, Dart **3.13.5**, Azul OpenJDK **21.0.12.1**, Gradle **9.3.1**, Android platform **35/36**, Build-Tools **36.0.0**, NDK **28.2.13676358**, dan CMake **3.22.1**. `flutter doctor -v` menandai toolchain Android serta lisensinya lengkap. Flutter dikonfigurasi menggunakan SDK/JDK dalam `$env:USERPROFILE/.codex/tools`.

Build Android masih mengeluarkan peringatan kompatibilitas XML SDK serta deprecation DSL/Kotlin pada plugin. Build berhasil pada versi Gradle/AGP yang dipatok; migrasi plugin perlu ditinjau sebelum beralih ke AGP/Gradle 10.

## Backend dan batas bukti

Pengujian SQL terakhir pada **17 Oktober 2026**: lima kelompok pemeriksaan PostgreSQL lokal lulus untuk feed publik, revisi/konflik, isolasi akun, pembatasan laporan, dan cascade penghapusan. Menggunakan PGlite lokal dengan fixture auth, tanpa mengubah proyek Supabase.

Pengujian klien sinkronisasi menggunakan HTTP tiruan; pengujian navigasi menggunakan controller akun tiruan. Ini belum membuktikan pengiriman OTP, konfigurasi Supabase, Edge Functions, ataupun sinkronisasi dua perangkat nyata.

**Belum diuji di ponsel/emulator**, sesuai pilihan pemilik untuk menyiapkan APK dan panduan dulu. Startup Android, SQLite/secure storage native, izin, pengiriman dan ketukan notifikasi OS, reboot, berbagi berkas, serta perangkat dengan page size 16 KB masih perlu diuji. Pemeriksaan statis bukan pengujian runtime.

Backend produksi, feed Indonesia berizin, SMTP, URL legal publik, signing rilis, AAB, dan persetujuan Play Store belum diselesaikan. Pemeriksa rilis menolak konfigurasi/keystore yang kosong sebagaimana dirancang. Backend tetap berupa kode dan panduan; tidak ada deployment Supabase atau push GitHub dalam pekerjaan ini.

Lanjutkan dengan [panduan uji Android](ANDROID_TESTING.md), [setup backend](BACKEND_SETUP.md), dan [gerbang rilis](RELEASE.md).
