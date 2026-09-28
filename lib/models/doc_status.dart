import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/doc.dart';
import '../utils/dates.dart';

enum DocStatus { ok, urgent, expired }

DocStatus statusFor(Doc doc, AppSettings settings, {DateTime? now}) {
  final dl = daysLeft(doc.expira, now: now);
  if (dl < 0) return DocStatus.expired;
  if (dl <= settings.urgentDays) return DocStatus.urgent;
  return DocStatus.ok;
}

Color statusColor(BuildContext context, DocStatus status) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (status) {
    case DocStatus.ok:
      return dark ? const Color(0xFF3ECF72) : const Color(0xFF1E9E50);
    case DocStatus.urgent:
      return dark ? const Color(0xFFFFB347) : const Color(0xFFD97706);
    case DocStatus.expired:
      return dark ? const Color(0xFFFF6B6B) : const Color(0xFFD93A3A);
  }
}

String statusBadge(Doc doc, {DateTime? now}) {
  final dl = daysLeft(doc.expira, now: now);
  if (dl < 0) return 'Expirat de ${-dl} zile';
  if (dl == 0) return 'Expiră azi';
  if (dl == 1) return 'Expiră mâine';
  return '$dl zile';
}
