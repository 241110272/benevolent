# Mencoba LangkahKerja pada Android

Build debug dapat dipakai untuk menguji fitur lokal tanpa backend produksi. Login, sinkronisasi, laporan, dan feed Indonesia tetap memerlukan setup backend. APK debug tidak digunakan untuk publikasi Play Store.

## Membuat APK uji

Setelah JDK dan Android SDK siap, jalankan dari folder proyek:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/android_debug.ps1
```

Skrip memeriksa dependensi, analisis kode, tes, lalu membuat `build/app/outputs/flutter-apk/app-debug.apk`. Tidak membuat upload keystore, mengaktifkan backend, atau memasang APK secara otomatis ke ponsel.

## Memasang dan mencoba

Pindahkan APK ke ponsel uji dan buka berkasnya. Izinkan pemasangan dari aplikasi pengirim hanya bila memang diperlukan untuk perangkat uji milikmu. Alternatif bagi pengembang: sambungkan perangkat dengan USB debugging yang sudah diizinkan, periksa `flutter devices`, lalu jalankan `flutter run -d <device-id>`.

Ekspor cadangan sebelum menghapus atau mengganti APK uji, karena data lokal dapat ikut terhapus ketika aplikasi dihapus.

Catat versi Android, model perangkat, waktu uji, hasil, dan langkah masalah yang ditemukan. Lakukan pemeriksaan berikut pada perangkat nyata:

| Alur | Hasil yang diperiksa |
|---|---|
| Onboarding → buka ulang | Onboarding selesai tetap tersimpan |
| Demo → cari/filter/favorit | Hasil sesuai filter; data simulasi berlabel |
| Lamaran manual → catatan/status → tutup/buka | Semua catatan tetap ada |
| Agenda → aktifkan notifikasi | OS meminta izin hanya setelah tindakan pengguna |
| Tolak izin notifikasi | Agenda tetap tersimpan; aplikasi memberi penjelasan |
| Ketuk notifikasi saat aplikasi aktif/tertutup | Catatan terkait terbuka; jadwal lama tidak membuka catatan yang sudah berubah |
| Ubah/hapus agenda → reboot | Notifikasi lama dibatalkan; jadwal yang masih berlaku dipulihkan oleh plugin |
| Berbagi JSON/CSV → impor JSON | Berkas dapat dipakai; impor salah ditolak tanpa merusak data |
| Mode pesawat | Catatan lokal tetap dapat dibaca dan diubah |
| Keyboard, teks besar, layar kecil, tombol kembali | Kontrol terbaca dan dapat digunakan tanpa overflow |

Untuk tes notifikasi, pilih waktu beberapa menit ke depan dan biarkan aplikasi berjalan di latar belakang. Jadwal inexact dapat tertunda oleh OS. Force-stop dapat menahan pengiriman; jangan menganggap pengingat terjamin tepat detik.

Pengujian dua akun/perangkat dan penghapusan akun dilakukan setelah [setup backend](BACKEND_SETUP.md), menggunakan data uji terpisah. Ikuti [gerbang rilis](RELEASE.md) sebelum membuat AAB.

## Pemeriksaan statis APK

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check_android_apk.ps1
```

Skrip memeriksa tanda tangan, ZIP alignment 16 KB, segmen ELF/RELRO pustaka 64 bit, identitas/versi Android, serta SHA-256. APK tidak dimodifikasi; salinan pustaka untuk pemeriksaan berada di `.tools/apk-inspection`. SDK default adalah `$env:USERPROFILE/.codex/tools/android-sdk`, NDK 28.2.13676358, dan Build-Tools 36.0.0. Gunakan parameter `-Sdk`, `-NdkVersion`, `-BuildTools`, atau `-Apk` jika lokasinya berbeda.

Pemeriksaan ini mengikuti [panduan Android untuk page size 16 KB](https://developer.android.com/guide/practices/page-sizes). Hasil statis yang lulus tetap perlu dilengkapi pengujian pada perangkat/emulator 16 KB.
