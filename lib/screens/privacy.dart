import 'package:flutter/material.dart';
import '../config.dart';
import '../main.dart';

const privacySections = <String, String>{
  'Pengelola dan kontak':
      'LangkahKerja dikelola oleh Benelovent. Hubungi sastraxez@gmail.com untuk dukungan, pertanyaan privasi, atau permintaan penghapusan akun. Diperbarui 17 Oktober 2026.',
  'Data di perangkat':
      'Nama panggilan, minat, lokasi yang diketik, favorit, catatan, riwayat status, agenda, dan checklist disimpan di perangkat. Aplikasi tidak meminta GPS, kontak, kamera, atau berkas CV. Hapus data melalui Profil → Data & privasi.',
  'Akun dan sinkronisasi':
      'Masuk menggunakan kode verifikasi yang dikirim ke email melalui Supabase. Jika menghubungkan data ke akun, data pribadi tersebut dikirim melalui HTTPS dan disimpan di backend Supabase. Data akun dibatasi melalui kontrol akses per pengguna. Aplikasi tidak menyimpan password emailmu.',
  'Layanan lowongan dan tautan':
      'Lowongan Indonesia dimuat dari backend LangkahKerja yang dapat menggunakan sumber berizin seperti Jooble. Server menerima informasi teknis koneksi, misalnya alamat IP. Deskripsi lowongan tidak memuat gambar pelacak. Saat membuka halaman lamaran, browser mengunjungi situs eksternal dengan kebijakan privasinya sendiri. Pendaftaran lamaran dilakukan pada situs tersebut.',
  'Notifikasi':
      'Pengingat follow-up bersifat lokal, opsional, dan menggunakan izin notifikasi perangkat. Isi notifikasi dibuat umum agar tidak menampilkan nama perusahaan atau catatan pribadi pada layar kunci. Waktu pengiriman dapat dipengaruhi pengaturan baterai dan sistem operasi.',
  'Cadangan dan berbagi':
      'Ekspor JSON dan CSV dapat memuat catatan pribadi. Kamu memilih lokasi atau aplikasi tujuan berbagi. Lindungi berkas ekspor karena tidak dienkripsi oleh LangkahKerja. Mengimpor cadangan mengganti data lokal setelah konfirmasi. Cadangan buatan pengguna tidak ikut terhapus saat akun dihapus.',
  'Retensi dan penghapusan':
      'Data akun disimpan sampai kamu menghapusnya. Hapus akun dari Profil → Akun & sinkronisasi → Hapus akun setelah masuk ulang dengan kode email baru. Data akun aktif dan laporan yang terkait dihapus di server; salinan cadangan infrastruktur mengikuti masa retensi penyedia. Data lokal di perangkat lain mungkin masih tersimpan sampai perangkat tersebut tersambung dan keluar/dihapus datanya. Kamu juga dapat meminta penghapusan melalui sastraxez@gmail.com atau halaman penghapusan publik yang dicantumkan pada Play Store.',
  'Pilihan pengguna':
      'Tanpa masuk, fitur penyimpanan lokal tetap dapat dipakai. Tidak ada iklan, pembayaran, analitik pemasaran, atau penjualan data pada versi ini. Aplikasi ditujukan untuk pencari kerja dewasa dan bukan layanan perekrutan perusahaan. Ketentuan penggunaan data dapat diperbarui bersamaan dengan fitur; perubahan akan disertai pembaruan kebijakan ini.',
};

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kebijakan privasi')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Privasi, dalam kendalimu.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        for (final entry in privacySections.entries) ...[
          Text(
            entry.key,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SelectableText(
            entry.value,
            style: const TextStyle(fontSize: 13, color: muted, height: 1.8),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Kontak: ${AppConfig.supportEmail}',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
