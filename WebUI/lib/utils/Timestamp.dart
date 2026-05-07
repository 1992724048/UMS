String formatTimestamp(int timestampMillis) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

  final formatted =
      "${dateTime.year.toString().padLeft(4, '0')}-"
      "${dateTime.month.toString().padLeft(2, '0')}-"
      "${dateTime.day.toString().padLeft(2, '0')} "
      "${dateTime.hour.toString().padLeft(2, '0')}:"
      "${dateTime.minute.toString().padLeft(2, '0')}:"
      "${dateTime.second.toString().padLeft(2, '0')}";

  return formatted;
}
