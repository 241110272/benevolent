import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/job.dart';
import '../services/app_scope.dart';
import '../services/exports.dart';
import '../services/job_store.dart';
import '../services/reminders.dart';
import '../widgets/job_card.dart';
import 'account.dart';
import 'agenda.dart';

class JobDetail extends StatefulWidget {
  const JobDetail({super.key, required this.job, required this.store});
  final Job job;
  final JobStore store;
  @override
  State<JobDetail> createState() => _JobDetailState();
}

class _JobDetailState extends State<JobDetail> {
  late final note = TextEditingController(
    text: widget.store.notes[widget.job.id] ?? '',
  );
  Job get job => widget.job;
  JobStore get store => widget.store;
  bool saving = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> reminder() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          store.followUps[job.id]?.isAfter(now) == true &&
              store.followUps[job.id]!.isBefore(
                now.add(const Duration(days: 730)),
              )
          ? store.followUps[job.id]!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (selectedDate == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;
    final at = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      time.hour,
      time.minute,
    );
    if (!at.isAfter(DateTime.now())) {
      message('Pilih waktu yang belum lewat.');
      return;
    }
    await store.setFollowUp(job.id, at);
    if (store.storageError != null) {
      message(store.storageError!);
      return;
    }
    if (!ReminderService.instance.supported) {
      message(
        'Agenda disimpan. Notifikasi lokal tersedia pada aplikasi Android/iOS.',
      );
      return;
    }
    if (!mounted) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan notifikasi agenda?'),
        content: const Text(
          'Izinkan LangkahKerja mengingatkanmu pada perangkat ini. Pengingat dapat tertunda oleh pengaturan baterai atau sistem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Simpan agenda saja'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
    try {
      await ReminderService.instance.cancel(job.id);
      if (enable == true) {
        final enabled = await ReminderService.instance.schedule(
          job.id,
          job.title,
          at,
        );
        message(
          enabled
              ? 'Agenda dan notifikasi dijadwalkan di perangkat ini.'
              : 'Agenda disimpan. Izin notifikasi belum diberikan.',
        );
      } else {
        message('Agenda disimpan tanpa notifikasi.');
      }
    } catch (_) {
      message('Agenda disimpan, tetapi notifikasi belum dapat dijadwalkan.');
    }
  }

  Future<void> report() async {
    final cloud = AppScope.cloudOf(context);
    if (cloud?.user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AccountPage(store: store, cloud: cloud),
        ),
      );
      return;
    }
    var reason = 'scam', sending = false;
    String? error;
    final detail = TextEditingController();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Laporkan lowongan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Laporan dikirim ke tim Benelovent untuk ditinjau. Jangan masukkan data sensitif.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'scam',
                      child: Text('Dugaan penipuan'),
                    ),
                    DropdownMenuItem(
                      value: 'closed',
                      child: Text('Lowongan sudah tutup'),
                    ),
                    DropdownMenuItem(
                      value: 'inaccurate',
                      child: Text('Informasi tidak sesuai'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: sending ? null : (v) => update(() => reason = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detail,
                  maxLength: 1500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (opsional)',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(color: Color(0xFF9E3F46)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      update(() {
                        sending = true;
                        error = null;
                      });
                      try {
                        await cloud!.client!
                            .from('job_reports')
                            .insert({
                              'job_id': job.id,
                              'reason': reason,
                              'detail': detail.text.trim(),
                            })
                            .timeout(const Duration(seconds: 20));
                        if (ctx.mounted) Navigator.pop(ctx);
                        message('Laporan berhasil dikirim untuk ditinjau.');
                      } catch (_) {
                        if (ctx.mounted) {
                          update(() {
                            sending = false;
                            error =
                                'Laporan belum terkirim atau laporan serupa sudah pernah dikirim. Coba lagi bila koneksi sudah pulih.';
                          });
                        }
                      }
                    },
              child: Text(sending ? 'Mengirim...' : 'Kirim laporan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Detail lowongan'),
        actions: [
          IconButton(
            tooltip: 'Bagikan lowongan',
            onPressed: job.demo || job.applicationUri == null
                ? null
                : () async {
                    try {
                      await shareJob(context, job.title, job.company, job.url);
                    } catch (_) {
                      message('Belum bisa membuka menu berbagi.');
                    }
                  },
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Simpan favorit',
            onPressed: () => store.toggleSave(job),
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
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 8),
            Text('${job.company} · ${job.location}'),
            if (job.salary != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Gaji dari sumber: ${job.salary}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: plum,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job.remote) const Pill('Remote'),
                ...job.jobTypes.take(3).map((t) => Pill(t, warm: true)),
                ...job.tags.take(5).map((t) => Pill(t)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              job.demo
                  ? 'Data simulasi untuk demonstrasi. Bukan lowongan aktif.'
                  : 'Sumber: ${job.source}. Periksa status dan ketentuan pekerjaan pada situs aslinya.',
              style: const TextStyle(color: muted, fontSize: 12, height: 1.7),
            ),
            if (job.createdAt != null)
              Text(
                'Tanggal sumber: ${MaterialLocalizations.of(context).formatMediumDate(DateTime.fromMillisecondsSinceEpoch(job.createdAt! * 1000).toLocal())}',
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            const Divider(height: 32),
            if (job.description.trim().isEmpty)
              const Text(
                'Deskripsi belum tersedia. Baca informasi lengkap pada situs sumber.',
              )
            else
              Html(
                data: job.safeDescription,
                onLinkTap: (url, _, _) => openJobLink(context, url),
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    fontSize: FontSize(14),
                    lineHeight: const LineHeight(1.7),
                  ),
                },
              ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lavender.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Jaga keamanan saat melamar. Periksa identitas perusahaan melalui kanal resmi. Jangan kirim OTP, password, atau detail rekening kepada perekrut.',
                style: TextStyle(fontSize: 12, height: 1.7, color: muted),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Catatan lamaran',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Status diperbarui sendiri oleh kamu, bukan oleh perusahaan.',
              style: TextStyle(fontSize: 12, color: muted),
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
              onChanged: (s) async {
                if (s == null) return;
                await store.track(job, s);
                if ([
                  ApplicationStatus.accepted,
                  ApplicationStatus.rejected,
                ].contains(s)) {
                  try {
                    await ReminderService.instance.cancel(job.id);
                  } catch (_) {
                    message(
                      'Status disimpan, tetapi notifikasi belum bisa dibatalkan.',
                    );
                  }
                  await store.setFollowUp(job.id, null);
                }
              },
            ),
            if (store.applications.containsKey(job.id)) ...[
              const SizedBox(height: 18),
              TextField(
                controller: note,
                maxLength: 10000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan pribadi',
                  hintText:
                      'Contoh: dokumen yang perlu disiapkan, hasil interview...',
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          await store.track(
                            job,
                            store.applications[job.id]!,
                            note: note.text,
                          );
                          if (!mounted) return;
                          setState(() => saving = false);
                          message(
                            store.storageError ?? 'Catatan berhasil disimpan.',
                          );
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan catatan'),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Agenda & follow-up',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 10),
              if (store.followUps[job.id] case final at?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    formatDateTime(context, at),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: reminder,
                icon: const Icon(Icons.event_note_outlined),
                label: Text(
                  store.followUps.containsKey(job.id)
                      ? 'Ubah agenda / aktifkan notifikasi'
                      : 'Atur agenda follow-up',
                ),
              ),
              if (store.followUps.containsKey(job.id))
                TextButton(
                  onPressed: () async {
                    try {
                      await ReminderService.instance.cancel(job.id);
                      await store.setFollowUp(job.id, null);
                      message('Agenda dihapus.');
                    } catch (_) {
                      message('Belum bisa membatalkan pengingat. Coba lagi.');
                    }
                  },
                  child: const Text('Hapus agenda'),
                ),
              const SizedBox(height: 20),
              const Text(
                'Riwayat status',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              for (final entry in store.timeline[job.id] ?? [])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: plum,
                    size: 21,
                  ),
                  title: Text(
                    entry.status.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    formatDateTime(context, entry.at),
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus catatan lamaran?'),
                      content: const Text(
                        'Status, riwayat, agenda, dan catatan akan dihapus. Favorit tidak ikut dihapus.',
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
                  if (yes == true) {
                    try {
                      await ReminderService.instance.cancel(job.id);
                      await store.untrack(job.id);
                      note.clear();
                    } catch (_) {
                      message(
                        'Belum bisa membatalkan pengingat. Catatan belum dihapus.',
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus catatan lamaran'),
              ),
            ],
            if (!job.demo && !job.id.startsWith('manual-'))
              TextButton.icon(
                onPressed: report,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Laporkan lowongan bermasalah'),
              ),
            if (store.storageError != null)
              Text(
                store.storageError!,
                style: const TextStyle(color: Color(0xFF9E3F46)),
              ),
            const SizedBox(height: 28),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (job.applicationUri != null && !job.demo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Dibuka di browser: ${job.applicationUri!.host}',
                    style: const TextStyle(color: muted, fontSize: 10),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: job.demo || job.applicationUri == null
                      ? null
                      : () async {
                          final opened = await openJobLink(context, job.url);
                          if (opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Selesai melamar di situs sumber? Catat statusnya sendiri.',
                                ),
                                action: SnackBarAction(
                                  label: 'Catat lamaran',
                                  onPressed: () => store.track(
                                    job,
                                    ApplicationStatus.applied,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    job.demo
                        ? 'Lowongan simulasi'
                        : job.applicationUri == null
                        ? 'Tautan belum tersedia'
                        : 'Buka halaman lamaran',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool> openJobLink(BuildContext context, String? value) async {
  final uri = safeExternalUri(value ?? '');
  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan HTTPS tidak valid atau belum tersedia.'),
        ),
      );
    }
    return false;
  }
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Unable to launch');
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan belum bisa dibuka. Coba lagi nanti.'),
        ),
      );
    }
    return false;
  }
}
