part of '../screens.dart';

List<Widget> _tripsHeader(PageControls ui) => [
  _label('Your next outside', size: 26, weight: FontWeight.bold),
  _label('Your saved trips stay separate.'),
];

List<Widget> _tripsBody(PageControls ui) => [
  _button('Plan another trip', () => ui.act('Plan another trip', 'explore')),
  _button('Downloaded summaries', () => ui.act('Downloaded summaries')),
  _button('Back to Explore', () => ui.act('Back to Explore', 'explore')),
];

List<Widget> _tripHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label(ui.display('Redwood Grove'), size: 26, weight: FontWeight.bold),
  _label('Your trip · Booking is simulated'),
];

List<Widget> _tripBody(PageControls ui) => [
  _panel([
    _label('Trip dates', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  _panel([
    _label('Booking status', weight: FontWeight.w500),
    _label(
      ui.noticeValue(
        'Notice / Booking status',
        'Request pending · Host response within 24 hours',
      ),
    ),
  ], color: softGreen),
  _panel([
    _label('Booking response', weight: FontWeight.w500),
    _label('Review simulated host outcomes', size: 12, color: muted),
  ], onTap: () => ui.act('Booking response', 'booking-response')),
  _panel([
    _label('Trip conditions', weight: FontWeight.w500),
    _label('Weather, fire rules and closures', size: 12, color: muted),
  ], onTap: () => ui.act('Trip conditions', 'tripconditions')),
  _panel([
    _label('Edit dates', weight: FontWeight.w500),
    _label('Save a new range or cancel', size: 12, color: muted),
  ], onTap: () => ui.act('Edit dates')),
  _panel([
    _label('Share & group', weight: FontWeight.w500),
    _label('Invite, review people and sync changes', size: 12, color: muted),
  ], onTap: () => ui.act('Share & group', 'share')),
  _panel([
    _label('Trip notifications', weight: FontWeight.w500),
    _label('Manage saved notification preferences', size: 12, color: muted),
  ], onTap: () => ui.act('Trip notifications', 'preferences')),
  _panel([
    _label('Download summary', weight: FontWeight.w500),
    _label('Save this trip for offline use', size: 12, color: muted),
  ], onTap: () => ui.act('Download summary')),
  _button('Remove trip', () => ui.act('Remove trip', 'remove')),
  _button('All trips', () => ui.act('All trips', 'trips')),
];

List<Widget> _tripconditionsHeader(PageControls ui) => [
  _back(ui),
  _label('Your trip conditions', size: 26, weight: FontWeight.bold),
  _label('Sample forecast · Oct 23–25', color: muted),
];

List<Widget> _tripconditionsBody(PageControls ui) => [
  Row(
    children: [
      _forecastDay([
        _label('FRI 23', size: 12, color: muted),
        _label('Sunny', weight: FontWeight.w500),
        _label('72° / 52°', weight: FontWeight.w500),
        _label('10% rain', size: 12, color: muted),
      ]),
      _forecastDay([
        _label('SAT 24', size: 12, color: muted),
        _label('Partly sunny', weight: FontWeight.w500),
        _label('70° / 51°', weight: FontWeight.w500),
        _label('20% rain', size: 12, color: muted),
      ]),
      _forecastDay([
        _label('SUN 25', size: 12, color: muted),
        _label('Sunny', weight: FontWeight.w500),
        _label('71° / 50°', weight: FontWeight.w500),
        _label('10% rain', size: 12, color: muted),
      ]),
    ],
  ),
  _panel([
    _label('Fire ban in effect', weight: FontWeight.w500),
    _label('No campfires. Bring an approved alternative for cooking.'),
  ], color: softGreen),
  _label(
    'No trail closures reported.\nLast checked today, 9:00 AM.\nSource: sample weather and park feeds.',
    color: muted,
  ),
  _button('Manage alerts', () => ui.act('Manage alerts')),
  _button('Back to my trip', () => ui.act('Back to my trip')),
];

List<Widget> _tripupdatedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Dates updated', size: 26, weight: FontWeight.bold),
  _label('Your group sees the new dates when it refreshes.'),
];

List<Widget> _tripupdatedBody(PageControls ui) => [
  _panel([
    _label(
      'Offline copy',
      weight: FontWeight.w500,
      color: const Color(0xFF8A5100),
    ),
    _label(
      'An existing download keeps its old dates until you refresh it.',
      color: const Color(0xFF8A5100),
    ),
  ], color: const Color(0xFFFFF2D8)),
  _button('View updated trip', () => ui.act('View updated trip')),
  _button('View group', () => ui.act('View group', 'your-camping-group')),
];

List<Widget> _updatedplanHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Updated trip', size: 26, weight: FontWeight.bold),
  _label('Open the current saved record.'),
];

List<Widget> _updatedplanBody(PageControls ui) => [
  _button('View current trip', () => ui.act('View current trip')),
  _button('All trips', () => ui.act('All trips', 'trips')),
];

List<Widget> _shareHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Better with your people', size: 26, weight: FontWeight.bold),
  _label('Invite someone to view this trip.'),
];

List<Widget> _shareBody(PageControls ui) => [
  _panel([
    _label('Trip', weight: FontWeight.w500),
    _label(ui.display('Redwood Grove')),
  ], color: softGreen),
  _panel([
    _label('Current dates', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  ui.input('Invitation email', 'Invitation email', ''),
  _button('Send invitation', () => ui.act('Send invitation', 'shared')),
  _button(
    'View demo trip link',
    () => ui.act('View demo trip link', 'linkcopied'),
  ),
  _panel([
    _label('People on this trip', weight: FontWeight.w500),
    _label('See invitation and membership status', size: 12, color: muted),
  ], onTap: () => ui.act('People on this trip', 'your-camping-group')),
  _panel([
    _label('Simulate send failure', weight: FontWeight.w500),
    _label('No invitation is sent', size: 12, color: muted),
  ], onTap: () => ui.act('Simulate send failure', 'invitation-not-sent')),
  _button('Return to trip', () => ui.act('Return to trip')),
];

List<Widget> _sharedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Invitation sent', size: 26, weight: FontWeight.bold),
  _label(
    'The invited account gets an in-app notification and can find this trip after signing in. No email is sent.',
  ),
];

List<Widget> _sharedBody(PageControls ui) => [
  _panel([
    _label('Invited to', weight: FontWeight.w500),
    _label(ui.display('Redwood Grove')),
  ], color: softGreen),
  _button('Open recipient view', () => ui.act('Open recipient view')),
  _button(
    'People on this trip',
    () => ui.act('People on this trip', 'your-camping-group'),
  ),
  _button('Return to trip', () => ui.act('Return to trip')),
];

List<Widget> _linkcopiedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Demo trip link', size: 26, weight: FontWeight.bold),
  _label('Select the link to copy it.'),
];

List<Widget> _linkcopiedBody(PageControls ui) => [
  const SelectableText('campready://invitation/demo'),
  _panel([
    _label('Invited to', weight: FontWeight.w500),
    _label(ui.display('Redwood Grove')),
  ], color: softGreen),
  _button('Open recipient view', () => ui.act('Open recipient view')),
  _button(
    'People on this trip',
    () => ui.act('People on this trip', 'your-camping-group'),
  ),
  _button('Return to trip', () => ui.act('Return to trip')),
];

List<Widget> _removeHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Remove this trip?', size: 26, weight: FontWeight.bold),
  _label('Only the selected trip will be removed.'),
];

List<Widget> _removeBody(PageControls ui) => [
  _panel([
    _label(
      'This also clears its group link and download',
      weight: FontWeight.w500,
    ),
    _label('Your other trip and global notification preference are kept.'),
  ], color: softGreen),
  _button('Remove trip', () => ui.act('Remove trip')),
  _button('Keep trip', () => ui.act('Keep trip')),
];

List<Widget> _tripsemptyHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('Your next trip starts here', size: 26, weight: FontWeight.bold),
  _label('You don’t have any upcoming plans.', color: muted),
];

List<Widget> _tripsemptyBody(PageControls ui) => [
  ui.brandMark(
    'assets/images/e2b5a5974f266a55.png',
    _label('A little more ready.', weight: FontWeight.w500, color: forest),
  ),
  _label(
    'Find a campsite, check the conditions and save your first weekend away.',
    color: muted,
  ),
  _button('Explore campsites', () => ui.act('Explore campsites', 'explore')),
];

List<Widget> _savedHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('Places worth returning to', size: 26, weight: FontWeight.bold),
  _label(
    '${ui.savedSites.length} saved ${ui.savedSites.length == 1 ? 'campsite' : 'campsites'}',
    color: muted,
  ),
];

List<Widget> _savedBody(PageControls ui) => [
  for (final site in ui.savedSites) ...[
    _campsiteCard(
      site == 'Sunset Ridge'
          ? 'assets/images/5b5ffeae6b8241ad.png'
          : 'assets/images/a1bf3d0137c87172.png',
      [
        _label(
          site == 'Sunset Ridge' ? 'BOULDER CREEK' : 'SANTA CRUZ · 45 MI',
          size: 12,
          color: muted,
        ),
        _label(site, size: 20, weight: FontWeight.bold),
        _label(
          site == 'Sunset Ridge'
              ? 'RV-friendly spaces'
              : 'Tent sites · Pets welcome',
          size: 12,
          color: muted,
        ),
        _label(
          site == 'Sunset Ridge'
              ? 'Conditions unavailable'
              : '72° / 52°  ·  Fire restriction',
          weight: FontWeight.w500,
          color: const Color(0xFF8A5100),
        ),
        _label(
          site == 'Sunset Ridge' ? '\$55 / night' : '\$65 / night',
          weight: FontWeight.w500,
        ),
      ],
      () => ui.act('Open saved: $site'),
    ),
    _button('Remove $site', () => ui.act('Remove saved: $site')),
  ],
];

List<Widget> _savedemptyHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('Save a little inspiration', size: 26, weight: FontWeight.bold),
  _label('Your saved list is empty.', color: muted),
];

List<Widget> _savedemptyBody(PageControls ui) => [
  ui.brandMark(
    'assets/images/e2b5a5974f266a55.png',
    _label('A little more ready.', weight: FontWeight.w500, color: forest),
  ),
  _label(
    'Save campsites you like and compare them when you’re ready to plan.',
    color: muted,
  ),
  _button('Find a campsite', () => ui.act('Find a campsite', 'explore')),
];

List<Widget> _alertsHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Trip updates', size: 26, weight: FontWeight.bold),
  _label('Updates for your saved trips.'),
];

List<Widget> _alertsBody(PageControls ui) => [
  if (ui.hasRedwoodAlert)
    _panel([
      _label('Redwood: fire restriction', weight: FontWeight.w500),
      _label(
        'No campfires. Read the trip-specific update.',
        size: 12,
        color: muted,
      ),
    ], onTap: () => ui.act('Redwood: fire restriction')),
  // First Integrations: real notification records from
  // MessagingService / Firestore, not hardcoded panels.
  for (final notification in ui.notifications)
    _panel([
      _label(notification.title, weight: FontWeight.w500),
      _label(notification.body, size: 12, color: muted),
    ], onTap: () => ui.act('All updates')),
  _label(
    ui.backendMode == 'firebase'
        ? 'Saved trip updates · push requires notification permission and registration'
        : 'Local demo · in-app only',
    size: 12,
    color: muted,
  ),
  _button(
    'Notification preferences',
    () => ui.act('Notification preferences', 'preferences'),
  ),
  _button('View trips', () => ui.act('View trips', 'trips')),
  _button('Explore', () => ui.act('Explore', 'explore')),
];

List<Widget> _alertdetailHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('A change to your trip', size: 26, weight: FontWeight.bold),
  _label(ui.display('Redwood Grove · Fire restriction')),
];

List<Widget> _alertdetailBody(PageControls ui) => [
  _panel([
    _label('No campfires', weight: FontWeight.w500),
    _label(
      'Check official conditions before travel. This is a sample notification.',
    ),
  ], color: softGreen),
  _button('View affected trip', () => ui.act('View affected trip')),
  _button('All updates', () => ui.act('All updates')),
];

List<Widget> _preferencesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Trip notifications', size: 26, weight: FontWeight.bold),
  _label('Changes apply only when you save.'),
];

List<Widget> _preferencesBody(PageControls ui) => [
  ui.alertSwitch('Condition-change notifications'),
  _panel([
    _label('What you receive', weight: FontWeight.w500),
    _label(
      'Weather changes, fire restrictions and access updates for your saved trips.',
    ),
  ], color: softGreen),
  _button(
    'Save preferences',
    () => ui.act('Save preferences', 'preferencessaved'),
  ),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _preferencessavedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Preferences saved', size: 26, weight: FontWeight.bold),
  _label('Your notification choice is now saved.'),
];

List<Widget> _preferencessavedBody(PageControls ui) => [
  _panel([
    _label('Notifications', weight: FontWeight.w500),
    _label(ui.display('On')),
  ], color: softGreen),
  _button('Done', () => ui.act('Done')),
];

List<Widget> _alertsemptyHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('All quiet for now', size: 26, weight: FontWeight.bold),
  _label('You may have no trips or notifications turned off.'),
];

List<Widget> _alertsemptyBody(PageControls ui) => [
  _panel([
    _label('Saved notification preference', weight: FontWeight.w500),
    _label(ui.display('On')),
  ], color: softGreen),
  _button(
    'Notification preferences',
    () => ui.act('Notification preferences', 'preferences'),
  ),
  _button('View trips', () => ui.act('View trips', 'trips')),
  _button('Explore', () => ui.act('Explore', 'explore')),
];
