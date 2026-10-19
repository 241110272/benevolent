import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/cloud.dart';
import '../services/job_store.dart';
import '../services/reminders.dart';
import 'privacy.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.store,
    this.cloud,
    this.locked = false,
  });
  final JobStore store;
  final CloudController? cloud;
  final bool locked;
  Future<bool> _confirm(
    BuildContext context,
    String title,
    String text,
    String action,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(text),
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([store, ?cloud]),
    builder: (context, _) {
      final service = cloud;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Akun & sinkronisasi'),
          automaticallyImplyLeading: !locked,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: lavender,
              child: Icon(Icons.cloud_outlined, size: 35, color: plum),
            ),
            const SizedBox(height: 24),
            Text(
              locked ? 'Data akunmu terlindungi.' : 'Lanjut di perangkat lain.',
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Favorit, catatan lamaran, dan preferensi dapat disinkronkan dengan akun emailmu. Catatan tersimpan lokal saat offline.',
              style: TextStyle(color: muted, height: 1.7),
            ),
            const SizedBox(height: 22),
            if (service?.configured != true)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Layanan akun belum tersedia pada versi ini. Fitur lokal tetap bisa digunakan. Sinkronisasi akan tersedia setelah layanan diaktifkan.',
                  ),
                ),
              )
            else if (service!.user == null) ...[
              if (locked)
                const Text(
                  'Masuk kembali dengan akun yang sama untuk membuka data tersimpan. Atau hapus data dari perangkat ini untuk memulai tanpa akun.',
                  style: TextStyle(height: 1.7),
                ),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => EmailLogin(cloud: service),
                  ),
                ),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Masuk / daftar dengan email'),
              ),
              if (locked)
                TextButton(
                  onPressed: () async {
                    if (await _confirm(
                      context,
                      'Hapus data perangkat?',
                      'Perubahan yang belum tersinkron akan hilang dari perangkat ini. Data server tetap ada.',
                      'Hapus lokal',
                    )) {
                      await ReminderService.instance.cancelAll();
                      await store.clearPersonal();
                    }
                  },
                  child: const Text('Hapus data lokal dan lanjut tanpa akun'),
                ),
            ] else ...[
              Text(
                service.user!.email ?? 'Akun email',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (service.needsChoice || service.conflict) ...[
                const Text(
                  'Pilih versi data yang ingin digunakan. Data tidak digabung otomatis agar catatan tidak tertimpa tanpa kamu ketahui.',
                  style: TextStyle(height: 1.7),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: service.busy
                      ? null
                      : () async {
                          if (await _confirm(
                            context,
                            'Gunakan data akun?',
                            'Data perangkat akan diganti dengan data akun. Ekspor cadangan terlebih dahulu jika ada catatan yang perlu disimpan.',
                            'Gunakan akun',
                          )) {
                            await service.useCloud();
                          }
                        },
                  child: const Text('Gunakan data akun'),
                ),
                OutlinedButton(
                  onPressed: service.busy
                      ? null
                      : () async {
                          if (await _confirm(
                            context,
                            'Unggah versi perangkat?',
                            'Isi akun akan diganti dengan data perangkat ini. Perangkat lain akan menerima versi ini pada sinkronisasi berikutnya.',
                            'Unggah perangkat',
                          )) {
                            await service.useDevice();
                          }
                        },
                  child: const Text('Gunakan data perangkat ini'),
                ),
              ] else ...[
                Text(
                  store.cloudDirty
                      ? 'Ada perubahan yang belum tersinkron.'
                      : 'Data perangkat sudah tersimpan.',
                  style: const TextStyle(color: muted),
                ),
                if (store.lastCloudSync != null)
                  Text(
                    'Sinkronisasi terakhir: ${MaterialLocalizations.of(context).formatMediumDate(store.lastCloudSync!.toLocal())}',
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: service.busy ? null : service.sync,
                  icon: const Icon(Icons.sync),
                  label: Text(
                    service.busy ? 'Menyinkronkan...' : 'Sinkronkan sekarang',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: service.busy
                    ? null
                    : () async {
                        if (await _confirm(
                          context,
                          'Keluar dari akun?',
                          '${store.cloudDirty ? 'Ada perubahan yang belum tersinkron. Ekspor cadangan sebelum keluar. ' : ''}Data pribadi lokal akan dihapus dari perangkat ini. Data akun tetap tersimpan di server.',
                          'Keluar',
                        )) {
                          await ReminderService.instance.cancelAll();
                          await service.signOut();
                        }
                      },
                child: const Text('Keluar dan bersihkan perangkat'),
              ),
              const Divider(height: 36),
              const Text(
                'Penghapusan akun',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                'Untuk keamanan, masuk ulang dengan kode email baru sebelum menghapus. Akun dan data server akan dihapus permanen; berkas ekspor yang kamu buat tetap ada.',
                style: TextStyle(fontSize: 12, height: 1.7, color: muted),
              ),
              TextButton(
                onPressed: service.busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EmailLogin(cloud: service),
                        ),
                      ),
                child: const Text('Masuk ulang untuk verifikasi'),
              ),
              OutlinedButton.icon(
                onPressed: service.busy
                    ? null
                    : () async {
                        final input = TextEditingController();
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus akun permanen?'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Ketik HAPUS untuk mengonfirmasi. Ekspor cadangan sebelum melanjutkan jika diperlukan.',
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: input,
                                  decoration: const InputDecoration(
                                    labelText: 'Konfirmasi',
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (input.text.trim() == 'HAPUS') {
                                    Navigator.pop(ctx, true);
                                  }
                                },
                                child: const Text('Hapus akun'),
                              ),
                            ],
                          ),
                        );
                        if (yes == true) {
                          try {
                            await service.deleteAccount();
                            await ReminderService.instance.cancelAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Akun dan data server berhasil dihapus.',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Belum bisa menghapus akun. Masuk ulang dengan kode email baru lalu coba lagi.',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Hapus akun'),
              ),
            ],
            if (service?.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  service!.error!,
                  style: const TextStyle(color: Color(0xFF9E3F46)),
                ),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
              ),
              child: const Text('Kebijakan privasi'),
            ),
          ],
        ),
      );
    },
  );
}

class EmailLogin extends StatefulWidget {
  const EmailLogin({super.key, required this.cloud});
  final CloudController cloud;
  @override
  State<EmailLogin> createState() => _EmailLoginState();
}

class _EmailLoginState extends State<EmailLogin> {
  final email = TextEditingController(), code = TextEditingController();
  bool sent = false, busy = false;
  String? error;
  int cooldown = 0;
  Timer? timer;
  @override
  void dispose() {
    email.dispose();
    code.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> submit({bool resend = false}) async {
    final address = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      setState(() => error = 'Masukkan email yang valid.');
      return;
    }
    if (sent && !resend && !RegExp(r'^\d{6,8}$').hasMatch(code.text.trim())) {
      setState(() => error = 'Masukkan kode angka dari email.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (sent && !resend) {
        await widget.cloud.verifyCode(address, code.text);
        if (mounted) Navigator.pop(context);
      } else {
        await widget.cloud.sendCode(address);
        if (!mounted) return;
        setState(() {
          sent = true;
          cooldown = 60;
        });
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted || cooldown <= 1) {
            t.cancel();
            if (mounted) setState(() => cooldown = 0);
          } else {
            setState(() => cooldown--);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = sent
              ? 'Kode tidak valid, kedaluwarsa, atau koneksi terganggu. Coba lagi atau kirim ulang setelah jeda.'
              : 'Kode belum dapat dikirim. Periksa email dan koneksi, lalu tunggu sebentar sebelum mencoba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Masuk dengan email')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Satu akun,\nlangkah berlanjut.',
          style: TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          sent
              ? 'Masukkan kode yang dikirim ke ${email.text.trim()}. Periksa folder spam jika belum terlihat.'
              : 'Kami mengirim kode verifikasi ke emailmu. Email baru akan membuat akun setelah kode diverifikasi. Tidak perlu membuat password.',
          style: const TextStyle(color: muted, height: 1.7),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: email,
          readOnly: sent,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        if (sent) ...[
          const SizedBox(height: 18),
          TextField(
            controller: code,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Kode verifikasi'),
          ),
        ],
        const SizedBox(height: 18),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              error!,
              style: const TextStyle(color: Color(0xFF9E3F46)),
            ),
          ),
        FilledButton(
          onPressed: busy ? null : () => submit(),
          child: Text(
            busy
                ? 'Memproses...'
                : sent
                ? 'Verifikasi dan masuk'
                : 'Kirim kode email',
          ),
        ),
        if (sent) ...[
          TextButton(
            onPressed: busy || cooldown > 0 ? null : () => submit(resend: true),
            child: Text(
              cooldown > 0
                  ? 'Kirim ulang dalam $cooldown detik'
                  : 'Kirim ulang kode',
            ),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    sent = false;
                    code.clear();
                    error = null;
                  }),
            child: const Text('Gunakan email lain'),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          'Data perangkat tidak otomatis diunggah saat masuk pertama kali. Kamu memilih data yang ingin dipakai di halaman Akun & sinkronisasi.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.7),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
          ),
          child: const Text('Baca kebijakan privasi'),
        ),
      ],
    ),
  );
}
