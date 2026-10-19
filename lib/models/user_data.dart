import 'job.dart';

class StatusChange {
  const StatusChange(this.status, this.at);
  final ApplicationStatus status;
  final DateTime at;
  Map<String, dynamic> toJson() => {
    'status': status.name,
    'at': at.toUtc().toIso8601String(),
  };
  static StatusChange? parse(dynamic value) {
    if (value is! Map) return null;
    final status = ApplicationStatus.values
        .where((s) => s.name == value['status'])
        .firstOrNull;
    final at = DateTime.tryParse('${value['at']}');
    return status == null || at == null
        ? null
        : StatusChange(status, at.toLocal());
  }
}

class SavedSearch {
  const SavedSearch({
    required this.name,
    required this.query,
    this.remote = false,
    this.matching = false,
    this.category = 0,
    this.location = '',
    this.jobType = '',
    this.days = 0,
  });
  final String name, query, location, jobType;
  final bool remote, matching;
  final int category, days;
  Map<String, dynamic> toJson() => {
    'name': name,
    'query': query,
    'remote': remote,
    'matching': matching,
    'category': category,
    'location': location,
    'jobType': jobType,
    'days': days,
  };
  factory SavedSearch.fromJson(Map value) => SavedSearch(
    name: '${value['name'] ?? ''}',
    query: '${value['query'] ?? ''}',
    remote: value['remote'] == true,
    matching: value['matching'] == true,
    category: ((value['category'] as num?)?.toInt() ?? 0).clamp(0, 2),
    location: '${value['location'] ?? ''}',
    jobType: '${value['jobType'] ?? ''}',
    days: [0, 1, 7, 30].contains(value['days'])
        ? (value['days'] as num).toInt()
        : 0,
  );
}
