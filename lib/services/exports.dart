import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'job_store.dart';

String csvCell(String input) {
  var value = input;
  if (RegExp(r'^[\s]*[=+@\-\t\r]').hasMatch(value)) value = "'$value";
  return '"${value.replaceAll('"', '""')}"';
}

String applicationsCsv(JobStore store) {
  final rows = <List<String>>[
    [
      'Posisi',
      'Perusahaan',
      'Status',
      'Perubahan terakhir',
      'Agenda',
      'Tautan',
      'Catatan',
    ],
  ];
  for (final entry in store.applications.entries) {
    final job = store.applicationJobs[entry.key];
    if (job == null) continue;
    rows.add([
      job.title,
      job.company,
      entry.value.label,
      store.timeline[entry.key]?.firstOrNull?.at.toIso8601String() ?? '',
      store.followUps[entry.key]?.toIso8601String() ?? '',
      job.url,
      store.notes[entry.key] ?? '',
    ]);
  }
  return '\uFEFF${rows.map((row) => row.map(csvCell).join(',')).join('\r\n')}';
}

Future<void> shareDocument(
  BuildContext context,
  String content,
  String name,
  String mimeType,
) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      title: name,
      files: [
        XFile.fromData(utf8.encode(content), mimeType: mimeType, name: name),
      ],
      fileNameOverrides: [name],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

Future<void> shareJob(
  BuildContext context,
  String title,
  String company,
  String url,
) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: '$title — $company\n$url\nDitemukan melalui LangkahKerja.',
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
