import 'package:flutter/material.dart';
import '../main.dart';
import '../models/job.dart';
import '../services/job_store.dart';
import '../screens/detail.dart';

class CompanyMark extends StatelessWidget {
  const CompanyMark(this.company, {super.key, this.size = 52});
  final String company;
  final double size;
  @override
  Widget build(BuildContext context) {
    final index = company.codeUnits.fold<int>(0, (a, b) => a + b) % 4;
    const colors = [lavender, Color(0xFFFFDACE), Color(0xFFDDE7FF), lime];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[index], colors[index].withValues(alpha: .65)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        company.isEmpty ? '?' : company.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: size * .64,
          height: 1,
          fontWeight: FontWeight.w800,
          color: plum,
          letterSpacing: -2,
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.store,
    this.compact = false,
  });
  final Job job;
  final JobStore store;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 1 : 12),
    child: Material(
      color: Colors.white.withValues(alpha: .88),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 14 : 20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => JobDetail(job: job, store: store),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 13 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompanyMark(job.company, size: compact ? 49 : 58),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 12 : 14,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            letterSpacing: -.4,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: ink, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: muted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${job.remote ? 'Remote · ' : ''}${job.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: store.saved.containsKey(job.id)
                          ? 'Hapus favorit'
                          : 'Simpan favorit',
                      onPressed: () => store.toggleSave(job),
                      icon: Icon(
                        store.saved.containsKey(job.id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 23,
                        color: plum,
                      ),
                    ),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 9),
                Text(
                  job.demo ? 'Data ilustrasi' : job.source,
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
              if (!compact || store.applications.containsKey(job.id)) ...[
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    ...job.tags
                        .take(2)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => Pill(e.value, warm: e.key == 0)),
                    if (job.demo) const Pill('Demo'),
                    if (store.applications[job.id] != null)
                      Pill(store.applications[job.id]!.label, warm: true),
                  ],
                ),
              ] else if (job.demo) ...[
                const SizedBox(height: 6),
                const Pill('Demo'),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.warm = false});
  final String text;
  final bool warm;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
    decoration: BoxDecoration(
      color: warm ? lime : lavender,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );
}
