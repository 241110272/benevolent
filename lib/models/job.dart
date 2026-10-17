enum ApplicationStatus {
  planned('Ingin dilamar'),
  applied('Sudah dilamar'),
  interview('Interview'),
  accepted('Diterima'),
  rejected('Ditolak');

  const ApplicationStatus(this.label);
  final String label;
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.url,
    this.remote = false,
    this.tags = const [],
    this.demo = false,
    this.createdAt,
  });
  final String id, title, company, location, description, url;
  final bool remote, demo;
  final int? createdAt;
  final List<String> tags;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['slug'] as String,
    title: json['title'] as String,
    company: json['company_name'] as String,
    location: json['location'] as String? ?? 'Tidak disebutkan',
    description: json['description'] as String? ?? '',
    url: json['url'] as String? ?? '',
    remote: json['remote'] == true,
    tags: List<String>.from(json['tags'] as List? ?? []),
    demo: json['demo'] == true,
    createdAt: (json['created_at'] as num?)?.toInt(),
  );
  Map<String, dynamic> toJson() => {
    'slug': id,
    'title': title,
    'company_name': company,
    'location': location,
    'description': description,
    'url': url,
    'remote': remote,
    'tags': tags,
    'demo': demo,
    'created_at': createdAt,
  };
}

const demoJobs = [
  Job(
    id: 'demo-design',
    title: 'Junior UI/UX Designer',
    company: 'Studio Tumbuh',
    location: 'Jakarta, Indonesia',
    remote: true,
    demo: true,
    url: '',
    tags: ['Design', 'Figma', 'Junior'],
    description:
        '<h3>Tentang pekerjaan</h3><p>Bantu tim merancang pengalaman digital yang mudah digunakan. Ini adalah lowongan simulasi untuk demo aplikasi.</p><h3>Tanggung jawab</h3><ul><li>Membuat wireframe dan prototipe di Figma.</li><li>Melakukan riset pengguna bersama tim.</li><li>Berkolaborasi dengan developer.</li></ul><h3>Persyaratan</h3><ul><li>Memiliki portofolio desain, termasuk proyek kuliah.</li><li>Memahami dasar UI dan UX.</li><li>Terbuka untuk fresh graduate.</li></ul>',
  ),
  Job(
    id: 'demo-flutter',
    title: 'Flutter Developer Intern',
    company: 'Ruang Digital',
    location: 'Bandung, Indonesia',
    demo: true,
    url: '',
    tags: ['Flutter', 'Technology', 'Internship'],
    description:
        '<h3>Tentang pekerjaan</h3><p>Lowongan simulasi magang pengembangan aplikasi mobile.</p><h3>Yang akan kamu kerjakan</h3><ul><li>Membangun tampilan Flutter yang responsif.</li><li>Menghubungkan aplikasi dengan REST API.</li></ul><h3>Persyaratan</h3><p>Memahami Dart, Git, dan dasar Flutter. Mahasiswa dipersilakan.</p>',
  ),
  Job(
    id: 'demo-marketing',
    title: 'Digital Marketing Associate',
    company: 'Kawan Usaha',
    location: 'Surabaya, Indonesia',
    remote: true,
    demo: true,
    url: '',
    tags: ['Marketing', 'Content'],
    description:
        '<h3>Tentang pekerjaan</h3><p>Lowongan simulasi untuk membantu UMKM menjangkau pelanggan melalui kampanye digital.</p><h3>Persyaratan</h3><ul><li>Terampil menyusun konten.</li><li>Memahami analitik media sosial.</li></ul>',
  ),
  Job(
    id: 'demo-data',
    title: 'Junior Data Analyst',
    company: 'Arah Data',
    location: 'Yogyakarta, Indonesia',
    demo: true,
    url: '',
    tags: ['Data', 'SQL', 'Junior'],
    description:
        '<h3>Tentang pekerjaan</h3><p>Lowongan simulasi analis data untuk lulusan baru.</p><h3>Persyaratan</h3><p>Memahami spreadsheet, SQL, dan visualisasi data.</p>',
  ),
];
