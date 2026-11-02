part of '../screens.dart';

List<Widget> _offlineHeader(PageControls ui) => [
  _back(ui),
  _label('You’re offline', size: 26, weight: FontWeight.bold),
  _label('Your trip can still come with you.', color: muted),
];

List<Widget> _offlineBody(PageControls ui) => [
  _panel([
    _label('Live updates are paused', weight: FontWeight.w500),
    _label('Reconnect to refresh weather and park advisories.'),
  ], color: softGreen),
  _button('Open downloaded trip', () => ui.act('Open downloaded trip')),
  _button(
    'Try connection again',
    () => ui.act('Try connection again', 'loading'),
  ),
];

List<Widget> _downloadedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Offline trip summary', size: 26, weight: FontWeight.bold),
  _label('Saved snapshot · Conditions may be outdated.'),
];

List<Widget> _downloadedBody(PageControls ui) => [
  _panel([
    _label('Campsite', weight: FontWeight.w500),
    _label(ui.display('Redwood Grove')),
  ], color: softGreen),
  _panel([
    _label('Downloaded dates', weight: FontWeight.w500),
    _label(
      ui.noticeValue(
        'Notice / Downloaded dates',
        'Saved dates unavailable. Refresh this download.',
      ),
    ),
  ], color: softGreen),
  _panel([
    _label(
      'Safety information',
      weight: FontWeight.w500,
      color: const Color(0xFF8A5100),
    ),
    _label(
      'Reconnect and check weather, fire rules and access before travel. This snapshot is not a current conditions report.',
      color: const Color(0xFF8A5100),
    ),
  ], color: const Color(0xFFFFF2D8)),
  _button('Refresh while online', () => ui.act('Refresh while online')),
  _button('Delete downloaded copy', () => ui.act('Delete downloaded copy')),
  _button('All downloads', () => ui.act('All downloads')),
];

List<Widget> _loadingHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('Finding your outside', size: 26, weight: FontWeight.bold),
  _label('Checking campsites and trip conditions…', color: muted),
];

List<Widget> _loadingBody(PageControls ui) => [
  ui.brandMark(
    'assets/images/e2b5a5974f266a55.png',
    _label('A little more ready.', weight: FontWeight.w500, color: forest),
  ),
  _label('This will only take a moment.', color: muted),
];

List<Widget> _serviceerrorHeader(PageControls ui) => [
  _back(ui),
  _label('We couldn’t load campsites', size: 26, weight: FontWeight.bold),
  _label('Please try again in a moment.', color: muted),
];

List<Widget> _serviceerrorBody(PageControls ui) => [
  _panel([
    _label('Your saved plans are safe', weight: FontWeight.w500),
    _label('The campsite service is temporarily unavailable.'),
  ], color: softGreen),
  _button('Try again', () => ui.act('Try again', 'loading')),
  _button('View saved trips', () => ui.act('View saved trips')),
];
