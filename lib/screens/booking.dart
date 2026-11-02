part of '../screens.dart';

List<Widget> _datesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Choose your dates', size: 26, weight: FontWeight.bold),
  _label(ui.display('Redwood Grove · October 2026')),
];

List<Widget> _datesBody(PageControls ui) => [
  _panel([
    _label('Selected range', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  _panel([
    _label('October 23–25', weight: FontWeight.w500),
    _label('2 nights · Available', size: 12, color: muted),
  ], onTap: () => ui.act('October 23–25')),
  _panel([
    _label('October 30–November 1', weight: FontWeight.w500),
    _label('2 nights · Available', size: 12, color: muted),
  ], onTap: () => ui.act('October 30–November 1')),
  _button('Use selected dates', () => ui.act('Use selected dates')),
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
  _label('October 1–10 is in the past. Your trip has not changed.'),
];

List<Widget> _dateerrorBody(PageControls ui) => [
  _button('Choose a valid range', () => ui.act('Choose a valid range')),
  _panel([
    _label('Try reversed range', weight: FontWeight.w500),
    _label('Oct 25 → Oct 23', size: 12, color: muted),
  ], onTap: () => ui.act('Try reversed range', 'checkout-must-follow-arrival')),
  _panel(
    [
      _label('Try unavailable dates', weight: FontWeight.w500),
      _label('Oct 26–28', size: 12, color: muted),
    ],
    onTap: () => ui.act('Try unavailable dates', 'those-dates-are-unavailable'),
  ),
  _panel([
    _label('Try past dates', weight: FontWeight.w500),
    _label('Oct 1–10', size: 12, color: muted),
  ], onTap: () => ui.act('Try past dates')),
  _button('Cancel date change', () => ui.act('Cancel date change')),
];

List<Widget> _reviewHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Review and book', size: 26, weight: FontWeight.bold),
  _label(ui.display('Redwood Grove')),
];

List<Widget> _reviewBody(PageControls ui) => [
  _panel([
    _label('Selected dates', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  _panel([
    _label('Booking total', weight: FontWeight.w500),
    _label('2 × \$65 = \$130 · No additional demo fees'),
  ], color: softGreen),
  _panel([
    _label(
      'Conditions',
      weight: FontWeight.w500,
      color: const Color(0xFF8A5100),
    ),
    _label(
      'Fire ban: no campfires. Forecast shown is an Oct 23–25 sample; recheck before travel.',
      color: const Color(0xFF8A5100),
    ),
  ], color: const Color(0xFFFFF2D8)),
  _panel([
    _label('Change dates', weight: FontWeight.w500),
    _label('Review a different range', size: 12, color: muted),
  ], onTap: () => ui.act('Change dates')),
  ui.alertSwitch('Condition-change alerts'),
  _button('Request to book · Demo', () => ui.act('Request to book · Demo')),
  _panel([
    _label('Simulate request failure', weight: FontWeight.w500),
    _label('No trip is created by this test', size: 12, color: muted),
  ], onTap: () => ui.act('Simulate request failure', 'request-not-sent')),
  _button('Cancel', () => ui.act('Cancel', 'detail')),
];

List<Widget> _notifpromptHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Stay ahead of changes', size: 26, weight: FontWeight.bold),
  _label('Prototype notification permission.'),
];

List<Widget> _notifpromptBody(PageControls ui) => [
  _button('Allow notifications', () => ui.act('Allow notifications')),
  _button('Not now', () => ui.act('Not now')),
  _panel([
    _label(
      'Your choice',
      weight: FontWeight.w500,
      color: const Color(0xFF8A5100),
    ),
    _label(
      'Your saved preference changes only when you submit the booking.',
      color: const Color(0xFF8A5100),
    ),
  ], color: const Color(0xFFFFF2D8)),
];

List<Widget> _confirmedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Request sent', size: 26, weight: FontWeight.bold),
  _label('Prototype only · No charge or reservation'),
];

List<Widget> _confirmedBody(PageControls ui) => [
  _panel([
    _label('Waiting for the host', weight: FontWeight.w500),
    _label(
      'A response is due within 24 hours. Follow booking status from your trip.',
    ),
  ], color: softGreen),
  _button('View trip', () => ui.act('View trip')),
  _button('All trips', () => ui.act('All trips', 'trips')),
];
