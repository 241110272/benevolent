/// Only the current agenda can resolve a notification to a private record.
class ReminderTarget {
  const ReminderTarget(this.jobId, this.atMilliseconds);
  final String jobId;
  final int atMilliseconds;

  static ReminderTarget? parse(String? payload) {
    if (payload == null || payload.length > 530) return null;
    final separator = payload.lastIndexOf('|');
    if (separator <= 0) return null;
    final id = payload.substring(0, separator);
    final at = int.tryParse(payload.substring(separator + 1));
    if (id.length > 500 || at == null || at <= 0 || at > 4102444800000) {
      return null;
    }
    return ReminderTarget(id, at);
  }

  bool matches(Map<String, DateTime> agenda) =>
      agenda[jobId]?.millisecondsSinceEpoch == atMilliseconds;
}
