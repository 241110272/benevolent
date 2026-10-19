import 'package:flutter/material.dart';
import '../main.dart';
import '../services/job_store.dart';
import '../widgets/brand.dart';
import 'privacy.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.store});
  final JobStore store;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int step = 0;
  bool saving = false;
  static const titles = [
    'Kariermu,\nlangkahmu.',
    'Peluang yang\nlebih relevan.',
    'Catat langkah.\nJaga progres.',
  ];
  static const descriptions = [
    'Temukan lowongan Indonesia dan atur proses melamar dalam satu tempat. Status lamaran kamu perbarui sendiri.',
    'Cari berdasarkan posisi, kota, tipe kerja, dan minat. Baca ketentuan lowongan lalu melamar di situs sumber.',
    'Simpan favorit, riwayat, dan agenda. Tanpa akun, data tetap di perangkat. Masuk lewat email untuk menyinkronkan data dengan akunmu.',
  ];
  Future<void> finish() async {
    setState(() => saving = true);
    await widget.store.completeOnboarding();
    if (!mounted) return;
    if (widget.store.storageError != null) {
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.store.storageError!)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Brand(),
                const Spacer(),
                if (step < 2)
                  TextButton(
                    onPressed: saving ? null : () => setState(() => step = 2),
                    child: const Text('Lewati'),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 38),
                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: lavender,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        [
                          Icons.stairs_rounded,
                          Icons.travel_explore,
                          Icons.assignment_turned_in_outlined,
                        ][step],
                        size: 85,
                        color: plum,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      titles[step],
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1.05,
                        letterSpacing: -2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      descriptions[step],
                      style: const TextStyle(
                        color: muted,
                        height: 1.8,
                        fontSize: 14,
                      ),
                    ),
                    if (step == 2) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Saat memuat lowongan atau masuk akun, aplikasi terhubung ke layanan internet. Notifikasi hanya diaktifkan saat kamu mengaturnya.',
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                          height: 1.6,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacyPage(),
                          ),
                        ),
                        child: const Text('Baca kebijakan privasi'),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Row(
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: step == i ? 28 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: step == i ? plum : lavender,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : step == 2
                    ? finish
                    : () => setState(() => step++),
                child: Text(
                  saving
                      ? 'Menyiapkan...'
                      : step == 2
                      ? 'Mulai melangkah'
                      : 'Lanjut',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
