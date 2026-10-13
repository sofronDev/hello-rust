import 'package:intl/intl.dart';

const thaiWeekdaysShort = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
const thaiWeekdays = [
  'จันทร์',
  'อังคาร',
  'พุธ',
  'พฤหัสบดี',
  'ศุกร์',
  'เสาร์',
  'อาทิตย์',
];
const thaiMonthsShort = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];
const thaiMonths = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

/// Thai (Buddhist Era) short date, e.g. "13 ต.ค. 69".
String thaiDate(DateTime d, {bool year = true}) =>
    '${d.day} ${thaiMonthsShort[d.month - 1]}'
    '${year ? ' ${(d.year + 543) % 100}' : ''}';

/// e.g. "วันอังคารที่ 13 ตุลาคม 2569".
String thaiDateLong(DateTime d) =>
    'วัน${thaiWeekdays[d.weekday - 1]}ที่ ${d.day} ${thaiMonths[d.month - 1]} ${d.year + 543}';

String thaiMonthYear(DateTime d) => '${thaiMonths[d.month - 1]} ${d.year + 543}';

String hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m นาที';
  return m == 0 ? '$h ชม.' : '$h ชม. $m นาที';
}

String fmtClock(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

final _number = NumberFormat('#,##0');
String fmtNumber(num n) => _number.format(n);

String fmtSets(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
