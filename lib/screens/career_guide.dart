import 'package:flutter/material.dart';
import '../main.dart';
import '../services/job_store.dart';

const careerChecklist = {
  'cv': 'Perbarui CV dan periksa kontak',
  'portfolio': 'Siapkan portofolio atau contoh proyek',
  'company': 'Pelajari perusahaan dan persyaratannya',
  'interview': 'Latihan menjawab pertanyaan interview',
  'documents': 'Periksa dokumen sebelum mengirim',
  'followup': 'Catat lamaran dan jadwal follow-up',
};
const careerArticles = {
  'CV yang mudah dibaca':
      'Sesuaikan CV dengan posisi yang dituju. Gunakan struktur yang jelas: ringkasan singkat, pengalaman/proyek, pendidikan, dan keterampilan yang relevan.\n\nCeritakan kontribusimu melalui contoh konkret: tugas yang dikerjakan, peran dalam tim, dan hasil. Mahasiswa dapat menampilkan proyek kuliah, organisasi, atau pekerjaan sukarela.\n\nPeriksa ejaan dan kontak. Hindari memasukkan nomor identitas, informasi rekening, atau data sensitif yang tidak diperlukan pada tahap awal lamaran.',
  'Portofolio yang bercerita':
      'Pilih beberapa karya terbaik yang relevan. Untuk setiap karya, jelaskan masalah, proses, peranmu, dan hasilnya.\n\nSertakan tautan yang bisa dibuka tanpa meminta akses. Jika proyek dibuat bersama tim, jelaskan bagian yang kamu kerjakan.\n\nJangan membagikan dokumen internal perusahaan atau data pengguna tanpa izin. Gunakan data contoh saat mendemonstrasikan hasil.',
  'Persiapan interview':
      'Baca informasi perusahaan dan posisi sebelum interview. Siapkan cerita tentang pengalaman menggunakan struktur situasi, tugas, tindakan, dan hasil.\n\nLatih perkenalan singkat. Jujurlah mengenai pengalaman yang belum dimiliki dan jelaskan cara kamu belajar.\n\nSiapkan pertanyaan tentang tanggung jawab, tim, proses seleksi, dan ketentuan kerja. Catat jadwal, zona waktu, serta tautan/lokasi interview.',
  'Membaca lowongan dengan aman':
      'Periksa identitas perusahaan melalui kanal resmi. Baca lokasi, bentuk kerja, persyaratan, dan tautan lamaran. Posisi remote tetap bisa membatasi negara atau zona waktu.\n\nJangan mengirim OTP, password, PIN, atau detail rekening untuk proses seleksi. Waspadai permintaan transfer uang yang tidak dapat diverifikasi.\n\nJika informasi tidak sesuai, buka lowongan asli untuk memastikan statusnya dan gunakan fitur Laporkan. LangkahKerja tidak menjamin bahwa setiap lowongan telah diverifikasi secara independen.',
};

class CareerGuide extends StatelessWidget {
  const CareerGuide({super.key, required this.store});
  final JobStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Bekal karier')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Siap untuk\nlangkah berikutnya.',
            style: TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '${store.completedChecklist.intersection(careerChecklist.keys.toSet()).length} dari ${careerChecklist.length} persiapan selesai',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value:
                store.completedChecklist
                    .intersection(careerChecklist.keys.toSet())
                    .length /
                careerChecklist.length,
            backgroundColor: lavender,
          ),
          const SizedBox(height: 16),
          for (final item in careerChecklist.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: store.completedChecklist.contains(item.key),
              onChanged: (_) => store.toggleChecklist(item.key),
              title: Text(item.value, style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(height: 26),
          const Text(
            'Materi singkat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final entry in careerArticles.entries)
            Card(
              color: Colors.white,
              child: ListTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.arrow_forward, size: 19),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Materi karier')),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SelectableText(
                              entry.value,
                              style: const TextStyle(height: 1.9, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
