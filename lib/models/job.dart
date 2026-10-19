import 'package:html/parser.dart' as html;
import 'package:characters/characters.dart';

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
    this.jobTypes = const [],
    this.source = 'Arbeitnow',
    this.salary,
  });
  final String id, title, company, location, description, url;
  final bool remote, demo;
  final int? createdAt;
  final List<String> tags;
  final List<String> jobTypes;
  final String source;
  final String? salary;

  factory Job.fromJson(Map<String, dynamic> json) {
    final id = '${json['slug'] ?? ''}'.trim();
    final title = '${json['title'] ?? ''}'.trim();
    final company = '${json['company_name'] ?? ''}'.trim();
    if (id.isEmpty ||
        title.isEmpty ||
        company.isEmpty ||
        id.length > 500 ||
        title.characters.length > 500 ||
        company.characters.length > 300) {
      throw const FormatException('Data lowongan tidak lengkap');
    }
    return Job(
      id: id,
      title: title,
      company: company,
      location: json['location'] as String? ?? 'Tidak disebutkan',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      remote: json['remote'] == true,
      tags: (json['tags'] as List? ?? []).whereType<String>().take(20).toList(),
      jobTypes: (json['job_types'] as List? ?? [])
          .whereType<String>()
          .take(20)
          .toList(),
      source: '${json['source'] ?? 'Arbeitnow'}',
      salary:
          json['salary'] is String &&
              (json['salary'] as String).trim().isNotEmpty
          ? (json['salary'] as String).trim()
          : null,
      demo: json['demo'] == true,
      createdAt:
          json['created_at'] is num &&
              (json['created_at'] as num) >= 0 &&
              (json['created_at'] as num) <= 4102444800
          ? (json['created_at'] as num).toInt()
          : null,
    );
  }
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
    'job_types': jobTypes,
    'source': source,
    'salary': salary,
  };

  String get plainDescription => html.parseFragment(description).text ?? '';
  String get searchableText =>
      '$title $company $location ${tags.join(' ')} ${jobTypes.join(' ')} $plainDescription'
          .toLowerCase();
  Uri? get applicationUri => safeExternalUri(url);

  String get safeDescription {
    final fragment = html.parseFragment(description);
    for (final element in fragment.querySelectorAll(
      'script,style,iframe,object,embed,img,video,audio,form,input,svg,link,meta,base,source,track',
    )) {
      element.remove();
    }
    for (final element in fragment.querySelectorAll('*')) {
      final href = element.attributes['href'];
      element.attributes.clear();
      if (element.localName == 'a' &&
          href != null &&
          safeExternalUri(href) != null) {
        element.attributes['href'] = href;
      }
    }
    return fragment.outerHtml;
  }
}

Uri? safeExternalUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
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
