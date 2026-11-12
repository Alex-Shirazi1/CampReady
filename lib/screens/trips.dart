part of '../screens.dart';

List<Widget> _tripsHeader(PageControls ui) => ui.trips.isEmpty
    ? _tripsemptyHeader(ui)
    : [
        _label('Your next outside', size: 26, weight: FontWeight.bold),
        _label('Your trips and the ones shared with you.'),
      ];

List<Widget> _tripsBody(PageControls ui) => ui.trips.isEmpty
    ? _tripsemptyBody(ui)
    : [
        for (final trip in ui.trips)
          _panel([
            _label('${trip.record.site}  ›', weight: FontWeight.w500),
            _label(trip.record.dates, size: 12, color: muted),
            _label(
              trip.isOwner
                  ? '${trip.record.status} · Simulated'
                  : 'Shared by ${trip.record.ownerEmail}',
              size: 12,
              color: muted,
            ),
          ], onTap: () => ui.act('Open trip: ${trip.id}')),
        _button(
          'Plan another trip',
          () => ui.act('Plan another trip', 'explore'),
        ),
        _button('Downloaded summaries', () => ui.act('Downloaded summaries')),
        _button('Back to Explore', () => ui.act('Back to Explore', 'explore')),
      ];

List<Widget> _tripHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label(ui.campsite.name, size: 26, weight: FontWeight.bold),
  _label('Your trip · Booking is simulated'),
];

List<Widget> _tripBody(PageControls ui) => [
  _panel([
    _label('Trip dates', weight: FontWeight.w500),
    _label(ui.tripDates),
  ], color: softGreen),
  _panel([
    _label('Booking status', weight: FontWeight.w500),
    _label('${ui.trip?.record.status ?? 'Request pending'} · Simulated'),
  ], color: softGreen),
  if (ui.showDemo)
    _panel([
      _label('Booking response', weight: FontWeight.w500),
      _label('Review simulated host outcomes', size: 12, color: muted),
    ], onTap: () => ui.act('Booking response', 'booking-response')),
  _panel([
    _label('Trip conditions', weight: FontWeight.w500),
    _label('Live forecast, fire rules and closures', size: 12, color: muted),
  ], onTap: () => ui.act('Trip conditions')),
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
  _label('${ui.campsite.name} · ${ui.tripDates}', color: muted),
];

List<Widget> _tripconditionsBody(PageControls ui) => [
  ui.forecast(details: true),
  _panel([
    _label(ui.campsite.fireRule, weight: FontWeight.w500),
    _label(ui.campsite.fireDetail),
  ], color: ui.campsite.conditionsKnown ? softGreen : _warningSurface),
  _label(
    '${ui.campsite.closures}\nFire rules and closures: sample park advisories.',
    color: muted,
  ),
  _button('Manage alerts', () => ui.act('Manage alerts', 'preferences')),
  _button('Back to my trip', () => ui.act('Back to my trip')),
];

List<Widget> _tripupdatedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Dates updated', size: 26, weight: FontWeight.bold),
  _label('Your group gets a trip update with the new dates.'),
];

List<Widget> _tripupdatedBody(PageControls ui) => [
  _panel([
    _label('New dates', weight: FontWeight.w500),
    _label(ui.tripDates),
  ], color: softGreen),
  if (ui.trip?.record.downloadedDates.isNotEmpty ?? false)
    _panel([
      _label('Offline copy', weight: FontWeight.w500, color: _warning),
      _label(
        'Your download keeps its old dates until you refresh it.',
        color: _warning,
      ),
    ], color: _warningSurface),
  _button('View updated trip', () => ui.act('View trip')),
  _button('View group', () => ui.act('View group', 'your-camping-group')),
];

List<Widget> _updatedplanHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Updated trip', size: 26, weight: FontWeight.bold),
  _label('Open the current saved record.'),
];

List<Widget> _updatedplanBody(PageControls ui) => [
  _button('View current trip', () => ui.act('View trip')),
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
    _label(ui.campsite.name),
  ], color: softGreen),
  _panel([
    _label('Current dates', weight: FontWeight.w500),
    _label(ui.tripDates),
  ], color: softGreen),
  ui.input('Invitation email', 'friend@example.com', ''),
  _button('Send invitation', () => ui.act('Send invitation')),
  _button('Copy trip link', () => ui.act('Copy trip link', 'linkcopied')),
  _panel([
    _label('People on this trip', weight: FontWeight.w500),
    _label('See invitation and membership status', size: 12, color: muted),
  ], onTap: () => ui.act('People on this trip', 'your-camping-group')),
  if (ui.showDemo)
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
    'They get a trip update and see this trip after signing in with that email.',
  ),
];

List<Widget> _sharedBody(PageControls ui) => [
  _panel([
    _label('Invited to', weight: FontWeight.w500),
    _label('${ui.campsite.name} · ${ui.tripDates}'),
  ], color: softGreen),
  _button(
    'People on this trip',
    () => ui.act('People on this trip', 'your-camping-group'),
  ),
  _button('Return to trip', () => ui.act('Return to trip')),
];

List<Widget> _linkcopiedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Trip link copied', size: 26, weight: FontWeight.bold),
  _label('Only people you invite by email can open it.'),
];

List<Widget> _linkcopiedBody(PageControls ui) => [
  SelectableText(ui.shareLink),
  _panel([
    _label('Invited to', weight: FontWeight.w500),
    _label(ui.campsite.name),
  ], color: softGreen),
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
      'This also removes its group and offline copy',
      weight: FontWeight.w500,
    ),
    _label('Your other trips and notification preference are kept.'),
  ], color: softGreen),
  _button('Remove trip', () => ui.act('Confirm remove trip')),
  _button('Keep trip', () => ui.act('Return to trip')),
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

List<Widget> _savedHeader(PageControls ui) => ui.savedSites.isEmpty
    ? _savedemptyHeader(ui)
    : [
        _label('CAMPREADY', size: 12, color: forest),
        _label('Places worth returning to', size: 26, weight: FontWeight.bold),
        _label(
          '${ui.savedSites.length} saved ${ui.savedSites.length == 1 ? 'campsite' : 'campsites'}',
          color: muted,
        ),
      ];

List<Widget> _savedBody(PageControls ui) => ui.savedSites.isEmpty
    ? _savedemptyBody(ui)
    : [
        for (final site in ui.savedSites) ...[
          _siteCard(ui, site),
          _button(
            'Remove ${site.name}',
            () => ui.act('Remove saved: ${site.id}'),
          ),
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

List<Widget> _alertsHeader(PageControls ui) => ui.notifications.isEmpty
    ? _alertsemptyHeader(ui)
    : [
        _button('‹ Back', ui.back),
        _label('Trip updates', size: 26, weight: FontWeight.bold),
        _label('Updates for your trips.'),
      ];

List<Widget> _alertsBody(PageControls ui) => ui.notifications.isEmpty
    ? _alertsemptyBody(ui)
    : [
        for (final notification in ui.notifications)
          _panel([
            _label(notification.title, weight: FontWeight.w500),
            _label(notification.body, size: 12, color: muted),
          ], onTap: () => ui.act('Open update: ${notification.id}')),
        _label(
          ui.alertsOn
              ? 'Trip alerts are on for this account.'
              : 'Trip alerts are off. Turn them on in preferences.',
          size: 12,
          color: muted,
        ),
        _button(
          'Notification preferences',
          () => ui.act('Notification preferences', 'preferences'),
        ),
        _button('View trips', () => ui.act('View trips')),
        _button('Explore', () => ui.act('Explore', 'explore')),
      ];

List<Widget> _alertdetailHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('A change to your trip', size: 26, weight: FontWeight.bold),
  _label(ui.selectedNotification?.site ?? 'Trip update'),
];

List<Widget> _alertdetailBody(PageControls ui) => [
  _panel([
    _label(
      ui.selectedNotification?.title ?? 'Update unavailable',
      weight: FontWeight.w500,
    ),
    _label(ui.selectedNotification?.body ?? 'Open Alerts to see your updates.'),
  ], color: softGreen),
  if (ui.selectedNotification?.tripId != null)
    _button('View affected trip', () => ui.act('View affected trip')),
  _button('All updates', () => ui.act('All updates', 'alerts')),
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
      'Trip invitations, date changes, booking updates and condition alerts for your trips.',
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
    _label(ui.alertsOn ? 'On' : 'Off'),
  ], color: softGreen),
  _button('Done', () => ui.act('Done', 'alerts')),
];

List<Widget> _alertsemptyHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('All quiet for now', size: 26, weight: FontWeight.bold),
  _label('You may have no trips or notifications turned off.'),
];

List<Widget> _alertsemptyBody(PageControls ui) => [
  _panel([
    _label('Saved notification preference', weight: FontWeight.w500),
    _label(ui.alertsOn ? 'On' : 'Off'),
  ], color: softGreen),
  _button(
    'Notification preferences',
    () => ui.act('Notification preferences', 'preferences'),
  ),
  _button('View trips', () => ui.act('View trips')),
  _button('Explore', () => ui.act('Explore', 'explore')),
];
