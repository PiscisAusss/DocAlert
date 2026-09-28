import 'package:docalert/models/app_settings.dart';
import 'package:docalert/models/doc.dart';
import 'package:docalert/models/doc_status.dart';
import 'package:docalert/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 28);

  test('daysLeft: azi, viitor, expirat', () {
    expect(daysLeft('2026-09-28', now: now), 0);
    expect(daysLeft('2026-10-08', now: now), 10);
    expect(daysLeft('2026-09-23', now: now), -5);
  });

  test('fmtData și toIsoDate', () {
    expect(fmtData('2027-01-15'), '15.01.2027');
    expect(toIsoDate(DateTime(2027, 1, 5)), '2027-01-05');
    expect(dPlus(2, now: now), '2026-09-30');
  });

  test('Doc JSON rămâne compatibil cu cheile vechi n/d/c/e', () {
    final doc = Doc.fromJson({
      'n': 'Maria',
      'd': 'Buletin',
      'c': 'Identitate',
      'e': '2027-01-15',
    });
    expect(doc.membru, 'Maria');
    expect(doc.nume, 'Buletin');
    expect(doc.id, 'Maria|Buletin|2027-01-15');
    final round = Doc.fromJson(doc.toJson());
    expect(round.membru, doc.membru);
    expect(round.expira, doc.expira);
  });

  test('statusFor respectă pragul din setări', () {
    const settings = AppSettings(
      urgentDays: 14,
      notifyDaysBefore: [7, 0],
      notifyHour: 9,
      notifyMinute: 0,
      members: [],
    );
    Doc d(String exp) => Doc(
          id: 'x',
          membru: 'A',
          nume: 'Doc',
          categorie: 'Altele',
          expira: exp,
        );
    expect(statusFor(d('2026-09-20'), settings, now: now), DocStatus.expired);
    expect(statusFor(d('2026-10-05'), settings, now: now), DocStatus.urgent);
    expect(statusFor(d('2026-12-01'), settings, now: now), DocStatus.ok);
  });

  test('AppSettings JSON', () {
    final s = AppSettings.defaults().copyWith(urgentDays: 45, members: ['Ana']);
    final back = AppSettings.fromJson(s.toJson());
    expect(back.urgentDays, 45);
    expect(back.members, ['Ana']);
    expect(back.notifyDaysBefore, [30, 14, 7, 0]);
  });
}
