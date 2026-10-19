import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_kerja/models/job.dart';
import 'package:langkah_kerja/services/exports.dart';
import 'package:langkah_kerja/models/reminder_target.dart';

void main() {
  test('payload pengingat harus valid dan sesuai jadwal terbaru', () {
    final at = DateTime(2026, 10, 19, 9);
    final target = ReminderTarget.parse(
      'manual-x|${at.millisecondsSinceEpoch}',
    );
    expect(target?.matches({'manual-x': at}), isTrue);
    expect(
      target?.matches({'manual-x': at.add(const Duration(hours: 1))}),
      isFalse,
    );
    expect(target?.matches({}), isFalse);
    for (final raw in [
      null,
      '',
      '|123',
      'x|bad',
      'x|-1',
      'x|99999999999999999',
    ]) {
      expect(ReminderTarget.parse(raw), isNull);
    }
  });
  test(
    'deskripsi tidak dapat memuat gambar tracker, skrip, atau link javascript',
    () {
      const job = Job(
        id: 'x',
        title: 'T',
        company: 'C',
        location: 'L',
        url: 'https://example.com',
        description:
            '<script>alert(1)</script><img src="https://tracker.invalid/x"><p onclick="bad()" style="x">Hello</p><a href="javascript:alert(1)">Bad</a><a href="https://example.com">Good</a>',
      );
      final safe = job.safeDescription;
      expect(safe, isNot(contains('<script')));
      expect(safe, isNot(contains('<img')));
      expect(safe, isNot(contains('onclick')));
      expect(safe, isNot(contains('javascript:')));
      expect(safe, contains('href="https://example.com"'));
    },
  );
  test('link sumber harus HTTPS dan tanpa user-info', () {
    expect(safeExternalUri('javascript:alert(1)'), isNull);
    expect(safeExternalUri('http://example.com'), isNull);
    expect(safeExternalUri('https://user:pass@example.com'), isNull);
    expect(safeExternalUri('https://example.com/job')?.host, 'example.com');
  });
  test('CSV tidak mengeksekusi formula dari judul atau catatan', () {
    expect(csvCell('=HYPERLINK("x")'), startsWith('"\''));
    expect(csvCell(' @SUM(1)'), startsWith('"\''));
    expect(csvCell('normal'), '"normal"');
    expect(csvCell('a"b'), '"a""b"');
  });
}
