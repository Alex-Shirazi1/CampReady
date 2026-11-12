import 'package:equatable/equatable.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

/// Check-in and check-out days for one trip.
class Stay extends Equatable {
  Stay(DateTime checkIn, DateTime checkOut)
    : checkIn = dateOnly(checkIn),
      checkOut = dateOnly(checkOut);

  static const maxNights = 14;

  final DateTime checkIn;
  final DateTime checkOut;

  int get nights => checkOut.difference(checkIn).inHours ~/ 24;

  /// Null when the stay is valid, otherwise the message to show.
  String? validate(DateTime today) {
    final now = dateOnly(today);
    if (checkIn.isBefore(now)) {
      return 'Choose upcoming dates. Arrival can’t be in the past.';
    }
    if (!checkOut.isAfter(checkIn)) {
      return 'Checkout must be at least one night after arrival.';
    }
    if (nights > maxNights) {
      return 'Trips can be up to $maxNights nights.';
    }
    return null;
  }

  /// "Dec 12–14, 2026", "Nov 28–Dec 1, 2026" or "Dec 30, 2026–Jan 2, 2027".
  String get label {
    final a = checkIn, b = checkOut;
    if (a.year != b.year) {
      return '${_months[a.month - 1]} ${a.day}, ${a.year}–'
          '${_months[b.month - 1]} ${b.day}, ${b.year}';
    }
    if (a.month != b.month) {
      return '${_months[a.month - 1]} ${a.day}–'
          '${_months[b.month - 1]} ${b.day}, ${a.year}';
    }
    return '${_months[a.month - 1]} ${a.day}–${b.day}, ${a.year}';
  }

  String get nightsLabel => nights == 1 ? '1 night' : '$nights nights';

  Map<String, String> toMap() => {
    'checkIn': isoDate(checkIn),
    'checkOut': isoDate(checkOut),
  };

  static Stay? fromMap(Map<String, dynamic> map) {
    final start = DateTime.tryParse(map['checkIn'] as String? ?? '');
    final end = DateTime.tryParse(map['checkOut'] as String? ?? '');
    if (start == null || end == null) return null;
    return Stay(start, end);
  }

  @override
  List<Object?> get props => [checkIn, checkOut];
}
