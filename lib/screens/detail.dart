import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/job.dart';
import '../services/job_store.dart';
import '../widgets/job_card.dart';

class JobDetail extends StatelessWidget {
  const JobDetail({super.key, required this.job, required this.store});
  final Job job;
  final JobStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Detail lowongan'),
        actions: [
          IconButton(
            tooltip: 'Simpan favorit',
            onPressed: store.applications.containsKey(job.id)
                ? null
                : () => store.toggleSave(job),
            icon: Icon(
              store.saved.containsKey(job.id)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanyMark(job.company, size: 68),
            const SizedBox(height: 20),
            Text(
              job.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${job.company} · ${job.location}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job.remote) const Pill('Remote'),
                ...job.tags.map((t) => Pill(t)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              job.demo
                  ? 'Data simulasi untuk demonstrasi. Lowongan ini tidak menerima lamaran.'
                  : 'Sumber: Arbeitnow. Periksa ketentuan lokasi, bahasa, dan izin kerja pada lowongan asli.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const Divider(height: 32),
            Html(
              data: job.description,
              onLinkTap: (url, _, _) => openJobLink(context, url),
              style: {
                'body': Style(
                  margin: Margins.zero,
                  fontSize: FontSize(15),
                  lineHeight: const LineHeight(1.6),
                ),
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Catatan lamaran',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Status diperbarui sendiri oleh kamu, bukan oleh perusahaan.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ApplicationStatus>(
              isExpanded: true,
              key: ValueKey(store.applications[job.id]),
              initialValue: store.applications[job.id],
              decoration: const InputDecoration(
                labelText: 'Status lamaran',
                hintText: 'Pilih untuk mulai mencatat',
              ),
              items: ApplicationStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (s) {
                if (s != null) store.track(job, s);
              },
            ),
            if (store.applications.containsKey(job.id)) ...[
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('note-${job.id}'),
                initialValue: store.notes[job.id] ?? '',
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan pribadi',
                  hintText: 'Contoh: interview Jumat pukul 10.00',
                ),
                onChanged: (value) =>
                    store.track(job, store.applications[job.id]!, note: value),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus catatan lamaran?'),
                      content: const Text(
                        'Status dan catatan akan dihapus. Lowongan tetap ada di favorit.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await store.untrack(job.id);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus catatan lamaran'),
              ),
            ],
            if (store.storageError != null)
              Text(
                store.storageError!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: job.demo ? null : () => openJobLink(context, job.url),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(
              job.demo ? 'Lowongan simulasi' : 'Buka halaman lamaran',
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openJobLink(BuildContext context, String? value) async {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null ||
      !['https', 'http'].contains(uri.scheme) ||
      uri.host.isEmpty) {
    return;
  }
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) throw Exception('Unable to launch');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan belum bisa dibuka. Coba lagi nanti.'),
        ),
      );
    }
  }
}
