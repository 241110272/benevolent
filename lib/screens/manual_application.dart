import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/job_store.dart';

class ManualApplication extends StatefulWidget {
  const ManualApplication({super.key, required this.store});
  final JobStore store;
  @override
  State<ManualApplication> createState() => _ManualApplicationState();
}

class _ManualApplicationState extends State<ManualApplication> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      company = TextEditingController(),
      location = TextEditingController(),
      url = TextEditingController(),
      note = TextEditingController();
  ApplicationStatus status = ApplicationStatus.planned;
  bool busy = false;
  @override
  void dispose() {
    for (final c in [title, company, location, url, note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Catat lowongan sendiri')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Menemukan peluang di luar aplikasi? Simpan catatannya di sini. Catatan pribadi tidak dipublikasikan ke pencari kerja lain.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const ValueKey('manual-title'),
            controller: title,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Posisi'),
            validator: (v) =>
                v?.trim().isNotEmpty == true ? null : 'Isi nama posisi.',
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('manual-company'),
            controller: company,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Perusahaan'),
            validator: (v) =>
                v?.trim().isNotEmpty == true ? null : 'Isi nama perusahaan.',
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('manual-location'),
            controller: location,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Lokasi (opsional)'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('manual-url'),
            controller: url,
            maxLength: 2000,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Tautan sumber (opsional)',
              hintText: 'https://...',
            ),
            validator: (v) => v!.trim().isEmpty || safeExternalUri(v) != null
                ? null
                : 'Gunakan tautan HTTPS yang valid.',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ApplicationStatus>(
            initialValue: status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Status awal'),
            items: ApplicationStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => status = v!,
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('manual-note'),
            controller: note,
            maxLength: 10000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Catatan pribadi (opsional)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    setState(() => busy = true);
                    final job = Job(
                      id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
                      title: title.text.trim(),
                      company: company.text.trim(),
                      location: location.text.trim().isEmpty
                          ? 'Belum dicatat'
                          : location.text.trim(),
                      description:
                          '<p>${const HtmlEscape().convert('Catatan pribadi dari sumber yang kamu tambahkan sendiri. Baca deskripsi lengkap pada tautan sumber bila tersedia.')}</p>',
                      url: url.text.trim(),
                      source: 'Catatan pribadi',
                    );
                    await widget.store.track(
                      job,
                      status,
                      note: note.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (widget.store.storageError != null) {
                      setState(() => busy = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.store.storageError!)),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
            child: Text(busy ? 'Menyimpan...' : 'Simpan catatan lamaran'),
          ),
        ],
      ),
    ),
  );
}
