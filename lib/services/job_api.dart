import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';

class FeedNotConfigured implements Exception {}

class JobPage {
  const JobPage(this.jobs, this.hasMore);
  final List<Job> jobs;
  final bool hasMore;
}

abstract class JobApi {
  Future<JobPage> fetch(int page);
}

class IndonesiaJobApi implements JobApi {
  IndonesiaJobApi(this.client);
  final SupabaseClient? client;
  @override
  Future<JobPage> fetch(int page) async {
    if (client == null) throw FeedNotConfigured();
    const size = 40;
    final rows = await client!
        .from('jobs')
        .select('payload')
        .eq('country', 'ID')
        .eq('published', true)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('published_at', ascending: false)
        .order('id')
        .range((page - 1) * size, page * size)
        .timeout(const Duration(seconds: 20));
    final jobs = <Job>[];
    for (final row in rows.take(size)) {
      try {
        final job = Job.fromJson(
          Map<String, dynamic>.from(row['payload'] as Map),
        );
        if (!job.demo && job.applicationUri != null) jobs.add(job);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return JobPage(jobs, rows.length > size);
  }
}
