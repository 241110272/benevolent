import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../main.dart';
import '../services/cloud.dart';
import '../services/job_store.dart';
import 'account.dart';
import 'agenda.dart';
import 'career_guide.dart';
import 'data_privacy.dart';
import 'privacy.dart';

class Preferences extends StatefulWidget {
  const Preferences({super.key, required this.store, this.cloud});
  final JobStore store;
  final CloudController? cloud;
  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.store.name);
  late final skills = TextEditingController(text: widget.store.skills);
  late final location = TextEditingController(text: widget.store.location);
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    skills.dispose();
    location.dispose();
    super.dispose();
  }

  void open(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
    children: [
      const Text(
        'Tujuanmu,\npilihanmu.',
        style: TextStyle(
          fontSize: 42,
          height: 1.05,
          letterSpacing: -2,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Kenali dirimu. Temukan peluang yang relevan.',
        style: TextStyle(fontSize: 12, color: muted),
      ),
      const SizedBox(height: 24),
      Card(
        color: lavender.withValues(alpha: .5),
        child: ListTile(
          leading: const Icon(Icons.cloud_outlined),
          title: const Text(
            'Akun & sinkronisasi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          subtitle: Text(
            widget.cloud?.user?.email ??
                'Masuk untuk melanjutkan di perangkat lain',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              open(AccountPage(store: widget.store, cloud: widget.cloud)),
        ),
      ),
      const SizedBox(height: 22),
      Form(
        key: form,
        child: Column(
          children: [
            TextFormField(
              controller: name,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama panggilan',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: skills,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Minat & keterampilan',
                hintText: 'Flutter, Design, Marketing',
                helperText: 'Pisahkan kata kunci dengan koma.',
                prefixIcon: Icon(Icons.auto_awesome_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: location,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Lokasi yang diminati',
                hintText: 'Contoh: Jakarta, Medan, Bandung',
                helperText: 'Kosongkan untuk semua lokasi.',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: saving
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                setState(() => saving = true);
                await widget.store.preferences(
                  name.text,
                  skills.text,
                  location.text,
                );
                if (!context.mounted) return;
                setState(() => saving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.store.storageError ??
                          'Preferensi disimpan. Aktifkan filter di Eksplorasi.',
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.check),
        label: Text(saving ? 'Menyimpan...' : 'Simpan preferensi'),
      ),
      const SizedBox(height: 24),
      ListTile(
        leading: const Icon(Icons.event_note_outlined),
        title: const Text('Agenda lamaran'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => open(AgendaPage(store: widget.store)),
      ),
      ListTile(
        leading: const Icon(Icons.school_outlined),
        title: const Text('Bekal karier & checklist'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => open(CareerGuide(store: widget.store)),
      ),
      ListTile(
        leading: const Icon(Icons.folder_copy_outlined),
        title: const Text('Data & privasi'),
        subtitle: const Text(
          'Cadangan, ekspor, pemulihan, dan hapus data',
          style: TextStyle(fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            open(DataPrivacyPage(store: widget.store, cloud: widget.cloud)),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Kebijakan privasi'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => open(const PrivacyPage()),
      ),
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Bantuan & hubungi pengembang'),
        subtitle: const Text(
          AppConfig.supportEmail,
          style: TextStyle(fontSize: 11),
        ),
        onTap: () async {
          final uri = Uri(
            scheme: 'mailto',
            path: AppConfig.supportEmail,
            queryParameters: {'subject': 'Bantuan LangkahKerja'},
          );
          try {
            if (!await launchUrl(uri)) throw StateError('No email app');
          } catch (_) {
            if (context.mounted) {
              showDialog<void>(
                context: context,
                builder: (ctx) => const AlertDialog(
                  title: Text('Hubungi Benelovent'),
                  content: SelectableText(
                    'Kirim pertanyaan ke ${AppConfig.supportEmail}. Jangan sertakan password, OTP, atau informasi rekening.',
                  ),
                ),
              );
            }
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Tentang LangkahKerja'),
        onTap: () => showAboutDialog(
          context: context,
          applicationName: 'LangkahKerja',
          applicationVersion: '1.1.0',
          applicationLegalese: '© 2026 Benelovent · GPL-3.0',
          children: const [
            SizedBox(height: 16),
            Text(
              'Mendukung SDG 8 melalui akses informasi pekerjaan dan pencatatan lamaran. LangkahKerja bukan perusahaan perekrutan dan tidak mengirim CV secara otomatis.\n\nKontak: ${AppConfig.supportEmail}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'BENELOVENT · LANGKAHKERJA 1.1.0',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1.5),
      ),
    ],
  );
}
