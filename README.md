# LangkahKerja

Aplikasi Flutter untuk proyek UTS Mobile Front End, bertema **SDG 8: Decent Work and Economic Growth**.

## Menjalankan

Flutter stable (Dart >= 3.8) diperlukan. Dari folder proyek:

```powershell
flutter pub get
flutter run
```

Untuk preview melalui browser:

```powershell
flutter run -d chrome
```

SDK yang disiapkan pada komputer ini ada di `C:\Users\sastr\.codex\tools\flutter`. Jika Flutter belum ada di PATH, gunakan:

```powershell
& C:\Users\sastr\.codex\tools\flutter\bin\flutter.bat run -d chrome
```

Untuk Android, pasang Android SDK lewat Android Studio, jalankan emulator atau sambungkan perangkat dengan USB debugging, kemudian periksa `flutter doctor` dan `flutter devices`. Build iOS memerlukan macOS dan Xcode.

## Fitur

- Beranda: ringkasan favorit, jumlah catatan lamaran, interview, dan tips karier.
- Eksplorasi: REST API, pencarian, kategori Desain/Teknologi, filter remote, preferensi kata kunci/lokasi, urutan terbaru/terlama, refresh dan pagination.
- Detail: deskripsi HTML, favorit, tautan lamaran asli, status dan catatan pribadi.
- Lamaran Saya: filter status dan tab favorit.
- Profil: nama panggilan, kata kunci minat/keterampilan, dan lokasi.
- Penyimpanan lokal: favorit beserta salinan lowongannya, status, catatan, dan preferensi.
- Mode demo: empat lowongan simulasi berlabel, dapat dipakai tanpa koneksi.

## Sumber data dan batasan

Endpoint: [Arbeitnow Job Board API](https://www.arbeitnow.com/api/job-board-api). API ini terutama berisi lowongan Jerman. Remote tidak selalu berarti dapat bekerja dari negara mana pun. Data gaji tidak diasumsikan tersedia. Tidak ada klaim lowongan Indonesia dari API ini.

Mode demo dapat diaktifkan di bagian bawah halaman Eksplorasi atau saat API gagal. Data demo Indonesia adalah fiktif dan tombol melamar dinonaktifkan. Kembali ke API melalui tombol beralih atau refresh.

UI mengikuti referensi plum–lavender: logo tangga, tipografi Manrope, banner foto lokal, kartu lowongan ringkas, serta navigasi Beranda / Eksplorasi / Lamaran / Profil. Pada browser desktop, aplikasi ditampilkan dalam panel selebar 430 px; pada ponsel aplikasi mengisi layar. Foto dan font dibundel dalam `assets/`; prompt foto dan lisensi font dijelaskan di [dokumentasi aset](assets/README.md).

Pencarian dan filter dijalankan pada halaman data yang sudah dimuat. Gunakan **Muat lebih banyak** untuk memperluas hasil. Filter preferensi mencari salah satu kata kunci (dipisahkan koma) pada judul, perusahaan, lokasi, tag, atau deskripsi, ditambah lokasi jika diisi. Ini bukan prediksi peluang diterima.

Melamar membuka situs sumber melalui browser. Pengguna mengisi formulir di situs tersebut dan mencatat status sendiri di aplikasi. Tidak ada akun, backend perusahaan, pengiriman CV, atau pembaruan status otomatis. Data lokal tidak tersinkron antarperangkat dan dapat hilang saat data aplikasi dihapus.

## Struktur

```text
lib/main.dart                 Tema dan inisialisasi
lib/models/job.dart           Model lowongan, status, dan data simulasi
lib/services/job_store.dart   API, state, filter, penyimpanan lokal
lib/screens/app.dart          Beranda, lowongan, lamaran, preferensi
lib/screens/detail.dart       Detail lowongan dan pencatatan
lib/widgets/job_card.dart     Kartu lowongan dan komponen bersama
test/                        Pengujian penyimpanan, filter, dan alur UI
```

## Pemeriksaan

```powershell
flutter analyze
flutter test
flutter build web
```

## Alur demo presentasi

1. Buka Eksplorasi, pilih **Coba mode demo** di bagian bawah daftar.
2. Cari `Design`, buka detail, dan simpan favorit.
3. Pilih status **Interview**, lalu tambahkan catatan.
4. Buka Lamaran untuk melihat hasilnya dan filter berdasarkan status.
5. Isi keterampilan `Figma` serta lokasi `Jakarta` di Profil, simpan, kemudian buka tombol filter di Eksplorasi dan aktifkan **Sesuai preferensi**.
6. Muat ulang aplikasi untuk membuktikan penyimpanan lokal.
