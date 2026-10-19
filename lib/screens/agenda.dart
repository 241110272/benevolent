import 'package:flutter/material.dart';
import '../main.dart';
import '../services/job_store.dart';
import '../widgets/job_card.dart';
import 'detail.dart';

String formatDateTime(BuildContext context, DateTime value) {
  final date = value.toLocal();
  final local = MaterialLocalizations.of(context);
  return '${local.formatMediumDate(date)} · ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true)}';
}

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key, required this.store});
  final JobStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final agenda = store.followUps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      return Scaffold(
        appBar: AppBar(title: const Text('Agenda lamaran')),
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Jangan lewatkan\nlangkah penting.',
              style: TextStyle(
                fontSize: 31,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (agenda.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Text(
                  'Belum ada agenda. Buka detail lowongan yang sudah kamu catat, lalu atur follow-up atau interview.',
                  style: TextStyle(color: muted, height: 1.8),
                ),
              ),
            for (final entry in agenda)
              if (store.applicationJobs[entry.key] case final job?)
                Card(
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CompanyMark(job.company, size: 44),
                    title: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${formatDateTime(context, entry.value)}${entry.value.isBefore(DateTime.now()) ? '\nSudah lewat — perbarui jika diperlukan.' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: entry.value.isBefore(DateTime.now())
                              ? const Color(0xFF9E3F46)
                              : muted,
                        ),
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => JobDetail(job: job, store: store),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 18),
            const Text(
              'Agenda tersinkron sebagai tanggal dan waktu. Izin serta jadwal notifikasi perlu diaktifkan pada tiap perangkat. Pengiriman dapat tertunda oleh sistem operasi.',
              style: TextStyle(fontSize: 11, color: muted, height: 1.7),
            ),
          ],
        ),
      );
    },
  );
}
