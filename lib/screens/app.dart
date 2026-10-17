import 'package:flutter/material.dart';
import '../main.dart';
import '../models/job.dart';
import '../services/job_store.dart';
import '../widgets/brand.dart';
import '../widgets/career_banner.dart';
import '../widgets/job_card.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final JobStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0, category = 0;
  final search = TextEditingController();
  bool remote = false, matching = false, favorites = false, newest = true;
  ApplicationStatus? status;
  JobStore get store => widget.store;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 12),
              child: Row(
                children: [
                  const Brand(),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Profil dan preferensi',
                    onPressed: () => setState(() => tab = 3),
                    style: IconButton.styleFrom(
                      backgroundColor: lavender.withValues(alpha: .8),
                      fixedSize: const Size(40, 40),
                    ),
                    icon: Text(
                      store.name.isEmpty
                          ? 'S'
                          : store.name.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: plum,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (store.storageError != null)
              MaterialBanner(
                content: Text(store.storageError!),
                actions: [
                  TextButton(
                    onPressed: store.persist,
                    child: const Text('Coba simpan'),
                  ),
                ],
              ),
            Expanded(
              child: switch (tab) {
                0 => home(),
                1 => vacancies(),
                2 => applications(),
                _ => Preferences(store: store),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar(),
    ),
  );

  Widget bottomBar() {
    const labels = ['Beranda', 'Eksplorasi', 'Lamaran', 'Profil'];
    const icons = [
      Icons.home_outlined,
      Icons.search_rounded,
      Icons.assignment_outlined,
      Icons.person_outline_rounded,
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFD).withValues(alpha: .96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: plum.withValues(alpha: .04),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
          child: Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Semantics(
                  selected: tab == i,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => tab = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 68,
                            height: 34,
                            decoration: BoxDecoration(
                              color: tab == i ? lavender : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              tab == 0 && i == 0
                                  ? Icons.home_rounded
                                  : icons[i],
                              size: 25,
                              color: tab == i ? plum : muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: tab == i ? plum : muted,
                              fontWeight: tab == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget headline(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 44,
      height: 1.01,
      letterSpacing: -2.6,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
  );

  Widget home() => RefreshIndicator(
    onRefresh: store.load,
    child: ListView(
      key: const PageStorageKey('home'),
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      children: [
        Text(
          'Halo, ${store.name.isEmpty ? 'Sahabat' : store.name} 👋',
          style: const TextStyle(fontSize: 13, color: ink),
        ),
        const SizedBox(height: 5),
        headline('Kariermu,\nlangkahmu.'),
        const SizedBox(height: 15),
        CareerBanner(onTap: () => setState(() => tab = 1)),
        const SizedBox(height: 13),
        TextField(
          key: const ValueKey('home-search'),
          controller: search,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => setState(() => tab = 1),
          decoration: InputDecoration(
            hintText: 'Posisi atau perusahaan',
            prefixIcon: const Icon(Icons.search_rounded, color: ink, size: 22),
            suffixIcon: IconButton(
              tooltip: 'Cari lowongan',
              onPressed: () => setState(() => tab = 1),
              icon: const Icon(Icons.arrow_forward, size: 19),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pilihan untukmu',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Lihat semua lowongan',
              style: IconButton.styleFrom(backgroundColor: lavender),
              onPressed: () => setState(() => tab = 1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 21),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...jobsContent(store.jobs.take(3).toList()),
        sourceNotice(),
        const SizedBox(height: 14),
        Row(
          children: [
            stat(
              '${store.saved.length}',
              'Tersimpan',
              Icons.bookmark_border,
              () => setState(() {
                tab = 2;
                favorites = true;
              }),
            ),
            const SizedBox(width: 8),
            stat(
              '${store.applications.length}',
              'Lamaran',
              Icons.assignment_outlined,
              () => setState(() {
                tab = 2;
                favorites = false;
                status = null;
              }),
            ),
            const SizedBox(width: 8),
            stat(
              '${store.applications.values.where((s) => s == ApplicationStatus.interview).length}',
              'Interview',
              Icons.forum_outlined,
              () => setState(() {
                tab = 2;
                favorites = false;
                status = ApplicationStatus.interview;
              }),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Material(
          color: lavender.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: showTips,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: plum),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bekal langkahmu',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tips CV, portofolio, dan interview',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Mendukung SDG 8 · Pekerjaan layak & pertumbuhan ekonomi',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 9),
        ),
      ],
    ),
  );

  Widget stat(String count, String label, IconData icon, VoidCallback onTap) =>
      Expanded(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(icon, color: plum, size: 19),
                  const SizedBox(height: 5),
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget sourceNotice() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      store.demoMode
          ? 'Mode demo · Lowongan ilustrasi untuk presentasi.'
          : 'Sumber: Arbeitnow · Terutama lowongan Jerman. Posisi remote dapat memiliki batasan lokasi.',
      style: const TextStyle(color: muted, fontSize: 10, height: 1.6),
    ),
  );

  List<Widget> jobsContent(List<Job> jobs, {bool compact = false}) => [
    if (store.loading)
      const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    if (store.error != null)
      Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: lavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.error!, style: const TextStyle(fontSize: 12)),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: store.loading ? null : store.load,
                  child: const Text('Coba lagi'),
                ),
                TextButton(
                  onPressed: store.loading ? null : store.useDemo,
                  child: const Text('Gunakan demo'),
                ),
              ],
            ),
          ],
        ),
      ),
    if (jobs.isEmpty && !store.loading && store.error == null)
      empty(
        'Belum ada yang cocok',
        'Coba kata kunci lain atau ubah filter pencarian.',
        Icons.search_off,
      ),
    ...jobs.map((j) => JobCard(job: j, store: store, compact: compact)),
  ];

  List<Job> get filteredJobs {
    final results = store
        .search(search.text, remote: remote, matching: matching)
        .where((j) {
          final text = '${j.title} ${j.tags.join(' ')}'.toLowerCase();
          return switch (category) {
            1 => ['design', 'desain', 'ux', 'ui/'].any(text.contains),
            2 => [
              'developer',
              'engineer',
              'software',
              'flutter',
              'data',
              'technology',
              'it ',
            ].any(text.contains),
            _ => true,
          };
        })
        .toList();
    results.sort(
      (a, b) => newest
          ? (b.createdAt ?? 0).compareTo(a.createdAt ?? 0)
          : (a.createdAt ?? 0).compareTo(b.createdAt ?? 0),
    );
    return results;
  }

  Widget vacancies() {
    final results = filteredJobs;
    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        key: const PageStorageKey('explore'),
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        children: [
          headline('Temukan\npeluangmu.'),
          const SizedBox(height: 8),
          const Text(
            'Satu langkah lebih dekat ke tujuanmu.',
            style: TextStyle(fontSize: 12, color: ink),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('explore-search'),
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari posisi atau perusahaan',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: ink,
                    ),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () => setState(search.clear),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Badge(
                isLabelVisible: remote || matching,
                child: IconButton.filledTonal(
                  tooltip: 'Filter lowongan',
                  style: IconButton.styleFrom(
                    backgroundColor: lavender,
                    foregroundColor: plum,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    fixedSize: const Size(47, 49),
                  ),
                  onPressed: showFilters,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                  child: Semantics(
                    selected: category == i,
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() => category = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: category == i ? plum : Colors.white,
                          border: Border.all(
                            color: category == i ? plum : line,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          ['Semua', 'Desain', 'Teknologi'][i],
                          style: TextStyle(
                            color: category == i ? Colors.white : ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          CareerBanner(
            compact: true,
            onTap: () => setState(() => remote = !remote),
          ),
          if (remote || matching)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Wrap(
                spacing: 7,
                children: [
                  if (remote)
                    InputChip(
                      label: const Text(
                        'Remote',
                        style: TextStyle(fontSize: 10),
                      ),
                      onDeleted: () => setState(() => remote = false),
                    ),
                  if (matching)
                    InputChip(
                      label: const Text(
                        'Sesuai preferensi',
                        style: TextStyle(fontSize: 10),
                      ),
                      onDeleted: () => setState(() => matching = false),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lowongan terbaru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.7,
                  ),
                ),
              ),
              PopupMenuButton<bool>(
                tooltip: 'Urutkan lowongan',
                initialValue: newest,
                onSelected: (v) => setState(() => newest = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: true, child: Text('Terbaru')),
                  PopupMenuItem(value: false, child: Text('Terlama')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        newest ? 'Terbaru' : 'Terlama',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.south, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...jobsContent(results, compact: true),
          const SizedBox(height: 12),
          Text(
            '${results.length} lowongan pada data dimuat',
            style: const TextStyle(color: muted, fontSize: 10),
          ),
          sourceNotice(),
          if (store.hasMore && !store.demoMode)
            OutlinedButton(
              onPressed: store.loading ? null : () => store.load(more: true),
              child: const Text('Muat lebih banyak'),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Muat ulang API',
                onPressed: store.loading ? null : store.load,
                icon: const Icon(Icons.refresh),
              ),
              Flexible(
                child: TextButton(
                  onPressed: store.loading
                      ? null
                      : store.demoMode
                      ? store.load
                      : store.useDemo,
                  child: Text(
                    store.demoMode
                        ? 'Beralih ke lowongan API'
                        : 'Coba mode demo',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> showFilters() async {
    var draftRemote = remote, draftMatching = matching;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: canvas,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peluang yang kamu cari',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kerja remote'),
                  subtitle: const Text(
                    'Tetap periksa ketentuan lokasi perusahaan.',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: draftRemote,
                  onChanged: (v) => update(() => draftRemote = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sesuai preferensi'),
                  subtitle: Text(
                    store.skills.isEmpty && store.location.isEmpty
                        ? 'Atur minat dan lokasi di halaman Profil.'
                        : '${store.skills} · ${store.location.isEmpty ? 'Semua lokasi' : store.location}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: draftMatching,
                  onChanged: (v) => update(() => draftMatching = v),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pencocokan menggunakan kata kunci pada data yang telah dimuat, bukan penilaian kelayakan kerja.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.6),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => update(() {
                        draftRemote = false;
                        draftMatching = false;
                      }),
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            remote = draftRemote;
                            matching = draftMatching;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Tampilkan lowongan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget applications() {
    final jobs = store.saved.values
        .where(
          (j) =>
              favorites ||
              (store.applications.containsKey(j.id) &&
                  (status == null || store.applications[j.id] == status)),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
      children: [
        headline('Setiap langkah\nberarti.'),
        const SizedBox(height: 10),
        const Text(
          'Simpan peluang. Catat perjalananmu.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        const SizedBox(height: 24),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Lamaran saya'),
              icon: Icon(Icons.assignment_outlined),
            ),
            ButtonSegment(
              value: true,
              label: Text('Favorit'),
              icon: Icon(Icons.bookmark_outline),
            ),
          ],
          selected: {favorites},
          onSelectionChanged: (v) => setState(() => favorites = v.first),
        ),
        const SizedBox(height: 16),
        if (!favorites)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: const Text('Semua'),
                    selected: status == null,
                    onSelected: (_) => setState(() => status = null),
                  ),
                ),
                ...ApplicationStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: status == s,
                      onSelected: (_) => setState(() => status = s),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        if (jobs.isEmpty)
          empty(
            favorites
                ? 'Simpan peluang pertamamu'
                : 'Langkahmu dimulai di sini',
            favorites
                ? 'Tekan ikon bookmark pada lowongan yang menarik.'
                : 'Buka detail lowongan lalu pilih status untuk mulai mencatat lamaran.',
            favorites ? Icons.bookmarks_outlined : Icons.work_outline,
          ),
        ...jobs.map((j) => JobCard(job: j, store: store)),
        if (!favorites)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Status diperbarui sendiri oleh kamu. Membuka tautan lamaran tidak otomatis mengirim lamaran.',
              style: TextStyle(fontSize: 11, color: muted, height: 1.6),
            ),
          ),
      ],
    );
  }

  Widget empty(String title, String text, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 14),
    child: Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: lavender,
          child: Icon(icon, size: 32, color: plum),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 12, height: 1.7),
        ),
      ],
    ),
  );

  void showTips() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .65,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        children: const [
          Text(
            'Bekal sebelum melamar',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Buat CV yang relevan'),
            subtitle: Text(
              'Tonjolkan pengalaman dan proyek yang sesuai dengan posisi. Periksa ejaan dan pastikan kontakmu aktif.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.folder_outlined),
            title: Text('Tunjukkan hasil karyamu'),
            subtitle: Text(
              'Sertakan portofolio, peranmu dalam proyek, dan hasil yang bisa dijelaskan. Proyek kuliah juga dapat digunakan.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.forum_outlined),
            title: Text('Latihan interview'),
            subtitle: Text(
              'Siapkan contoh situasi, tugas, tindakan, dan hasil. Pelajari perusahaan dan buat daftar pertanyaan.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Baca lowongan dengan teliti'),
            subtitle: Text(
              'Periksa identitas perusahaan, persyaratan, lokasi, dan ketentuan kerja melalui sumber resmi.',
            ),
          ),
        ],
      ),
    ),
  );
}

class Preferences extends StatefulWidget {
  const Preferences({super.key, required this.store});
  final JobStore store;
  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  late final name = TextEditingController(text: widget.store.name);
  late final skills = TextEditingController(text: widget.store.skills);
  late final location = TextEditingController(text: widget.store.location);
  @override
  void dispose() {
    name.dispose();
    skills.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
    children: [
      const Text(
        'Tujuanmu,\npilihanmu.',
        style: TextStyle(
          fontSize: 44,
          height: 1.01,
          letterSpacing: -2.6,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Kenali dirimu. Temukan peluang yang relevan.',
        style: TextStyle(fontSize: 12, color: muted),
      ),
      const SizedBox(height: 28),
      TextField(
        controller: name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nama panggilan',
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: skills,
        decoration: const InputDecoration(
          labelText: 'Minat & keterampilan',
          hintText: 'Flutter, Design, Marketing',
          helperText: 'Pisahkan kata kunci dengan koma.',
          prefixIcon: Icon(Icons.auto_awesome_outlined),
        ),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: location,
        decoration: const InputDecoration(
          labelText: 'Lokasi yang diminati',
          hintText: 'Contoh: Berlin',
          helperText: 'Kosongkan untuk semua lokasi.',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await widget.store.preferences(name.text, skills.text, location.text);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                widget.store.storageError ??
                    'Preferensi disimpan. Aktifkan filter di Eksplorasi.',
              ),
            ),
          );
        },
        icon: const Icon(Icons.check),
        label: const Text('Simpan preferensi'),
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lavender.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Satu langkah, banyak kemungkinan.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'LangkahKerja mendukung SDG 8 melalui akses informasi pekerjaan dan pencatatan lamaran.\n\nFavorit, preferensi, dan catatan tersimpan di perangkat ini. Tanpa akun.\n\nData Arbeitnow terutama mencakup pasar kerja Jerman. Mode demo memakai lowongan ilustrasi Indonesia. Filter preferensi mencocokkan kata kunci dan lokasi pada data yang sudah dimuat.',
              style: TextStyle(height: 1.7, fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      const Center(
        child: Text(
          'LANGKAHKERJA  /  1.0.0',
          style: TextStyle(fontSize: 9, letterSpacing: 2, color: muted),
        ),
      ),
    ],
  );
}
