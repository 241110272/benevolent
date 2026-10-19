import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/cloud.dart';
import '../services/exports.dart';
import '../services/job_store.dart';
import '../services/reminders.dart';
import 'privacy.dart';

class DataPrivacyPage extends StatefulWidget {
  const DataPrivacyPage({super.key, required this.store, this.cloud});
  final JobStore store;
  final CloudController? cloud;
  @override
  State<DataPrivacyPage> createState() => _DataPrivacyPageState();
}

class _DataPrivacyPageState extends State<DataPrivacyPage> {
  bool busy = false;
  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } on FormatException catch (e) {
      message(e.message);
    } catch (_) {
      message(
        'Tindakan belum berhasil. Data tidak dihapus tanpa konfirmasi. Coba lagi.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String title, String description, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Data & privasi')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Datamu,\nkendalimu.',
          style: TextStyle(
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Cadangan memuat favorit, catatan, agenda, dan preferensi. Simpan di tempat aman karena berkas ekspor tidak dienkripsi.',
          style: TextStyle(color: muted, height: 1.7),
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Ekspor cadangan JSON'),
          subtitle: const Text('Untuk memulihkan data di perangkat lain'),
          enabled: !busy,
          onTap: () => run(
            () => shareDocument(
              context,
              widget.store.exportBackup(),
              'langkahkerja-backup.json',
              'application/json',
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.table_view_outlined),
          title: const Text('Ekspor lamaran CSV'),
          subtitle: const Text('Dapat dibuka di spreadsheet; termasuk catatan'),
          enabled: !busy,
          onTap: () => run(
            () => shareDocument(
              context,
              applicationsCsv(widget.store),
              'langkahkerja-lamaran.csv',
              'text/csv',
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('Pulihkan cadangan JSON'),
          subtitle: const Text('Mengganti data perangkat setelah konfirmasi'),
          enabled: !busy,
          onTap: () => run(() async {
            final file = await openFile(
              acceptedTypeGroups: [
                const XTypeGroup(
                  label: 'Cadangan JSON',
                  extensions: ['json'],
                  mimeTypes: ['application/json'],
                ),
              ],
            );
            if (file == null) return;
            if (await file.length() > 8 * 1024 * 1024) {
              throw const FormatException(
                'Berkas terlalu besar. Maksimal 8 MB.',
              );
            }
            final raw = await file.readAsString();
            if (!await confirm(
              'Ganti data dengan cadangan?',
              'Data saat ini akan diganti. Jika terhubung ke akun, perubahan ini akan disinkronkan. Ekspor cadangan saat ini terlebih dahulu bila diperlukan.',
              'Pulihkan',
            )) {
              return;
            }
            await widget.store.importBackup(raw);
            await ReminderService.instance.cancelAll();
            message(
              widget.store.storageError ??
                  'Data dipulihkan. Aktifkan ulang notifikasi agenda pada perangkat ini jika diperlukan.',
            );
          }),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Hapus riwayat pencarian'),
          enabled: !busy,
          onTap: () => run(() async {
            if (!await confirm(
              'Hapus riwayat pencarian?',
              'Pencarian tersimpan dan catatan lamaran tidak ikut dihapus.',
              'Hapus riwayat',
            )) {
              return;
            }
            widget.store.recentSearches.clear();
            await widget.store.persist();
            message('Riwayat pencarian dihapus.');
          }),
        ),
        ListTile(
          leading: const Icon(Icons.cached),
          title: const Text('Bersihkan cache lowongan'),
          subtitle: const Text('Favorit dan catatan lamaran tetap disimpan'),
          enabled: !busy,
          onTap: () => run(() async {
            await widget.store.clearCache();
            message('Cache lowongan dibersihkan.');
          }),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Hapus semua data pribadi'),
          subtitle: const Text(
            'Favorit, catatan, preferensi, agenda, dan checklist',
          ),
          enabled: !busy,
          onTap: () => run(() async {
            if (!await confirm(
              'Hapus semua data pribadi?',
              'Tindakan ini menghapus data lokal dan mengosongkan data akun pada sinkronisasi berikutnya. Akun email tetap ada. Ekspor cadangan terlebih dahulu bila diperlukan.',
              'Hapus data',
            )) {
              return;
            }
            await ReminderService.instance.cancelAll();
            await widget.store.clearPersonal(
              forgetAccount: widget.cloud?.user == null,
            );
            if (widget.cloud?.user != null) await widget.cloud!.sync();
            message(
              widget.store.storageError ??
                  (widget.cloud?.error != null
                      ? 'Data lokal dihapus. Penghapusan data cloud belum tersinkron; coba sinkronkan lagi.'
                      : 'Data pribadi dihapus.'),
            );
          }),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Kebijakan privasi'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Penghapusan akun beserta data server tersedia di Profil → Akun & sinkronisasi. Pada perangkat lain, salinan offline mungkin tetap ada sampai perangkat tersambung atau datanya dibersihkan.',
          style: TextStyle(fontSize: 11, color: muted, height: 1.7),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}
