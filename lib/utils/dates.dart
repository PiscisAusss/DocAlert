/// Zile până la expirare (0 = expiră azi, negativ = expirat).
int daysLeft(String expira, {DateTime? now}) {
  final exp = DateTime.parse(expira);
  final azi = now ?? DateTime.now();
  final miezulNoptii = DateTime(azi.year, azi.month, azi.day);
  return exp.difference(miezulNoptii).inDays;
}

/// Transformă `2027-01-15` în `15.01.2027`.
String fmtData(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  return '${p[2]}.${p[1]}.${p[0]}';
}

String toIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String dPlus(int n, {DateTime? now}) {
  final base = now ?? DateTime.now();
  return toIsoDate(base.add(Duration(days: n)));
}

DateTime? tryParseIsoDate(String iso) {
  try {
    return DateTime.parse(iso);
  } catch (_) {
    return null;
  }
}

String newDocId() => DateTime.now().microsecondsSinceEpoch.toRadixString(16);
