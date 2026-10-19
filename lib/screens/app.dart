import 'package:flutter/material.dart';
import '../main.dart';
import '../models/job.dart';
import '../services/job_store.dart';
import '../widgets/brand.dart';
import '../widgets/career_banner.dart';
import '../widgets/job_card.dart';
import '../models/user_data.dart';
import '../services/cloud.dart';
import 'settings.dart';
import 'career_guide.dart';
import 'agenda.dart';
import 'manual_application.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store, this.cloud});
  final JobStore store;
  final CloudController? cloud;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0, category = 0;
  final search = TextEditingController();
  final applicationSearch = TextEditingController();
  String city = '', jobType = '';
  int days = 0;
  bool remote = false, matching = false, favorites = false, newest = true;
  ApplicationStatus? status;
  JobStore get store => widget.store;
  @override
  void dispose() {
    search.dispose();
    applicationSearch.dispose();
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
                _ => Preferences(store: store, cloud: widget.cloud),
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
          maxLength: 250,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            store.rememberSearch(value);
            setState(() => tab = 1);
          },
          decoration: InputDecoration(
            counterText: '',
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
          : 'Lowongan Indonesia dari sumber yang dicantumkan pada detail. Periksa status dan persyaratan pada situs aslinya.',
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

  Widget searchTools() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 6,
        children: [
          TextButton.icon(
            onPressed: () async {
              final controller = TextEditingController(
                text: search.text.trim().isEmpty
                    ? 'Peluang ${['semua', 'desain', 'teknologi'][category]}'
                    : search.text.trim().characters.length <= 60
                    ? search.text.trim()
                    : 'Pencarian baru',
              );
              final form = GlobalKey<FormState>();
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Simpan pencarian'),
                  content: Form(
                    key: form,
                    child: TextFormField(
                      controller: controller,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Nama pencarian',
                      ),
                      validator: (v) => v?.trim().isNotEmpty == true
                          ? null
                          : 'Isi nama pencarian.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(ctx, controller.text.trim());
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              );
              if (name == null) return;
              try {
                await store.saveSearch(
                  SavedSearch(
                    name: name,
                    query: search.text,
                    remote: remote,
                    matching: matching,
                    category: category,
                    location: city,
                    jobType: jobType,
                    days: days,
                  ),
                );
              } on FormatException catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.message)));
                }
                return;
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(store.storageError ?? 'Pencarian disimpan.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.bookmark_add_outlined, size: 16),
            label: const Text(
              'Simpan pencarian',
              style: TextStyle(fontSize: 10),
            ),
          ),
          TextButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (ctx) => ListenableBuilder(
                listenable: store,
                builder: (ctx, _) => SafeArea(
                  child: SizedBox(
                    height: MediaQuery.sizeOf(ctx).height * .55,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        const Text(
                          'Pencarian tersimpan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (store.savedSearches.isEmpty)
                          const Text(
                            'Simpan kombinasi kata kunci dan filter yang sering kamu gunakan.',
                          ),
                        for (final item in store.savedSearches)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${item.query.isEmpty ? 'Semua kata kunci' : item.query}${item.location.isEmpty ? '' : ' · ${item.location}'}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: IconButton(
                              tooltip: 'Hapus pencarian ${item.name}',
                              onPressed: () => store.removeSearch(item),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                            onTap: () {
                              setState(() {
                                search.text = item.query;
                                remote = item.remote;
                                matching = item.matching;
                                category = item.category;
                                city = item.location;
                                jobType = item.jobType;
                                days = item.days;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.manage_search, size: 16),
            label: Text(
              'Tersimpan (${store.savedSearches.length})',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
      if (search.text.isEmpty && store.recentSearches.isNotEmpty)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.history, size: 16, color: muted),
              const SizedBox(width: 8),
              ...store.recentSearches
                  .take(5)
                  .map(
                    (q) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ActionChip(
                        label: Text(q, style: const TextStyle(fontSize: 10)),
                        onPressed: () => setState(() => search.text = q),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      const SizedBox(height: 8),
    ],
  );

  List<Job> get filteredJobs {
    final results = store
        .search(
          search.text,
          remote: remote,
          matching: matching,
          city: city,
          type: jobType,
          days: days,
        )
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
    results.sort((a, b) {
      if (a.createdAt == null) return b.createdAt == null ? 0 : 1;
      if (b.createdAt == null) return -1;
      return newest
          ? b.createdAt!.compareTo(a.createdAt!)
          : a.createdAt!.compareTo(b.createdAt!);
    });
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
                  maxLength: 250,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: store.rememberSearch,
                  decoration: InputDecoration(
                    counterText: '',
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
                isLabelVisible:
                    remote ||
                    matching ||
                    city.isNotEmpty ||
                    jobType.isNotEmpty ||
                    days != 0,
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
          searchTools(),
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
          if (remote ||
              matching ||
              city.isNotEmpty ||
              jobType.isNotEmpty ||
              days != 0)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Wrap(
                spacing: 7,
                children: [
                  if (city.isNotEmpty)
                    InputChip(
                      label: Text(city),
                      onDeleted: () => setState(() => city = ''),
                    ),
                  if (jobType.isNotEmpty)
                    InputChip(
                      label: Text(jobType),
                      onDeleted: () => setState(() => jobType = ''),
                    ),
                  if (days != 0)
                    InputChip(
                      label: Text('$days hari terakhir'),
                      onDeleted: () => setState(() => days = 0),
                    ),
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
    var draftType = jobType, draftDays = days;
    final cityController = TextEditingController(text: city);
    final types =
        store.jobs
            .expand((j) => j.jobTypes)
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (draftType.isNotEmpty && !types.contains(draftType)) {
      types.add(draftType);
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: canvas,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              0,
              22,
              MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * .68,
              child: Column(
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: cityController,
                            maxLength: 150,
                            decoration: const InputDecoration(
                              counterText: '',
                              labelText: 'Kota atau lokasi',
                              hintText: 'Contoh: Jakarta',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: draftType,
                            key: ValueKey('type-$draftType'),
                            decoration: const InputDecoration(
                              labelText: 'Tipe pekerjaan',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Semua tipe'),
                              ),
                              ...types.map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => update(() => draftType = v!),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            initialValue: draftDays,
                            key: ValueKey('days-$draftDays'),
                            decoration: const InputDecoration(
                              labelText: 'Tanggal ditayangkan',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Semua tanggal'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('24 jam terakhir'),
                              ),
                              DropdownMenuItem(
                                value: 7,
                                child: Text('7 hari terakhir'),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Text('30 hari terakhir'),
                              ),
                            ],
                            onChanged: (v) => update(() => draftDays = v!),
                          ),
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
                          const SizedBox(height: 12),
                          const Text(
                            'Filter bekerja pada data yang telah dimuat. Pencocokan kata kunci bukan penilaian kelayakan kerja. Filter tanggal mengecualikan lowongan tanpa tanggal sumber.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => update(() {
                          draftRemote = false;
                          draftMatching = false;
                          draftType = '';
                          draftDays = 0;
                          cityController.clear();
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
                              city = cityController.text.trim();
                              jobType = draftType;
                              days = draftDays;
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
      ),
    );
  }

  Widget applications() {
    final jobs = (favorites ? store.saved.values : store.applicationJobs.values)
        .where(
          (j) =>
              favorites ||
              (store.applications.containsKey(j.id) &&
                  (status == null || store.applications[j.id] == status)),
        )
        .where(
          (j) => '${j.title} ${j.company} ${store.notes[j.id] ?? ''}'
              .toLowerCase()
              .contains(applicationSearch.text.toLowerCase().trim()),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ManualApplication(store: store),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Catat lowongan sendiri'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AgendaPage(store: store),
                ),
              ),
              icon: const Icon(Icons.event_note_outlined, size: 18),
              label: const Text('Agenda'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: applicationSearch,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Cari posisi, perusahaan, atau catatan',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
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

  void showTips() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => CareerGuide(store: store)),
  );
}
