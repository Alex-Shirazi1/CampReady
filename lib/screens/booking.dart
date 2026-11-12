part of '../screens.dart';

List<Widget> _datesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Choose your dates', size: 26, weight: FontWeight.bold),
  _label(ui.campsite.name),
];

List<Widget> _datesBody(PageControls ui) => [
  _panel([
    _label('Selected range', weight: FontWeight.w500),
    _label(ui.draftDates),
  ], color: softGreen),
  if (ui.bookingError != null)
    _panel([
      _label('Choose another range', weight: FontWeight.w500, color: _warning),
      _label(ui.bookingError!, color: _warning),
    ], color: _warningSurface),
  _button('Choose dates', () => ui.act('Choose dates')),
  _button('Use selected dates', () => ui.act('Use selected dates')),
  _label(
    'Up to ${Stay.maxNights} nights, starting today or later.',
    size: 12,
    color: muted,
  ),
  if (ui.showDemo)
    _panel([
      _label('Other date states', weight: FontWeight.w500),
      _label(
        'Prototype examples: incomplete, reversed, past and unavailable',
        size: 12,
        color: muted,
      ),
    ], onTap: () => ui.act('Other date states', 'choose-a-checkout-date')),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _dateerrorHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Choose upcoming dates', size: 26, weight: FontWeight.bold),
  _label('Past dates can’t be booked. Your trip has not changed.'),
];

List<Widget> _dateerrorBody(PageControls ui) => [
  _button('Choose a valid range', () => ui.act('Choose a valid range')),
  _button('Cancel date change', () => ui.act('Cancel')),
];

List<Widget> _reviewHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Review and book', size: 26, weight: FontWeight.bold),
  _label(ui.campsite.name),
];

List<Widget> _reviewBody(PageControls ui) => [
  _panel([
    _label('Selected dates', weight: FontWeight.w500),
    _label(ui.draftDates),
  ], color: softGreen),
  _panel([
    _label('Booking total', weight: FontWeight.w500),
    _label(ui.bookingTotal),
  ], color: softGreen),
  _panel([
    _label('Conditions', weight: FontWeight.w500, color: _warning),
    _label(
      '${ui.campsite.fireRule}. Recheck the forecast before you travel.',
      color: _warning,
    ),
  ], color: _warningSurface),
  _panel([
    _label('Change dates', weight: FontWeight.w500),
    _label('Review a different range', size: 12, color: muted),
  ], onTap: () => ui.act('Change dates')),
  ui.alertSwitch('Condition-change alerts'),
  _button('Request to book', () => ui.act('Request to book')),
  _label(
    'Booking requests are simulated. No payment is taken.',
    size: 12,
    color: muted,
  ),
  if (ui.showDemo)
    _panel([
      _label('Simulate request failure', weight: FontWeight.w500),
      _label('No trip is created by this test', size: 12, color: muted),
    ], onTap: () => ui.act('Simulate request failure', 'request-not-sent')),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _notifpromptHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Stay ahead of changes', size: 26, weight: FontWeight.bold),
  _label('Get a push when dates, bookings or conditions change.'),
];

List<Widget> _notifpromptBody(PageControls ui) => [
  _button('Allow notifications', () => ui.act('Allow notifications')),
  _button('Not now', () => ui.act('Not now')),
  _panel([
    _label('Your choice', weight: FontWeight.w500, color: _warning),
    _label(
      'You can change this any time in Profile → Notification preferences.',
      color: _warning,
    ),
  ], color: _warningSurface),
];

List<Widget> _confirmedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Request sent', size: 26, weight: FontWeight.bold),
  _label('Simulated booking · No charge or reservation'),
];

List<Widget> _confirmedBody(PageControls ui) => [
  _panel([
    _label('Waiting for the host', weight: FontWeight.w500),
    _label('${ui.campsite.name} · ${ui.tripDates}'),
    _label('Follow booking status from your trip.', size: 12, color: muted),
  ], color: softGreen),
  _button('View trip', () => ui.act('View trip')),
  _button('All trips', () => ui.act('All trips', 'trips')),
];
