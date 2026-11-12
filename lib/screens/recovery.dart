part of '../screens.dart';

List<Widget> _chooseYourDatesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Choose your dates', size: 26, weight: FontWeight.bold),
  _label('Sunset Ridge · October 2026'),
];

List<Widget> _chooseYourDatesBody(PageControls ui) => [
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

List<Widget> _chooseACheckoutDateHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Choose a checkout date', size: 26, weight: FontWeight.bold),
  _label('An arrival date alone cannot be saved.'),
];

List<Widget> _chooseACheckoutDateBody(PageControls ui) => [
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
  ], onTap: () => ui.act('Try past dates', 'dateerror')),
  _button('Cancel date change', () => ui.act('Cancel date change')),
];

List<Widget> _checkoutMustFollowArrivalHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Checkout must follow arrival', size: 26, weight: FontWeight.bold),
  _label('The reversed range has not changed your trip.'),
];

List<Widget> _checkoutMustFollowArrivalBody(PageControls ui) => [
  _button('Choose a valid range', () => ui.act('Choose a valid range')),
  _panel([
    _label('Try reversed range', weight: FontWeight.w500),
    _label('Oct 25 → Oct 23', size: 12, color: muted),
  ], onTap: () => ui.act('Try reversed range')),
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
  ], onTap: () => ui.act('Try past dates', 'dateerror')),
  _button('Cancel date change', () => ui.act('Cancel date change')),
];

List<Widget> _thoseDatesAreUnavailableHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Those dates are unavailable', size: 26, weight: FontWeight.bold),
  _label('October 26–28 is unavailable. Choose another range.'),
];

List<Widget> _thoseDatesAreUnavailableBody(PageControls ui) => [
  _button('Choose a valid range', () => ui.act('Choose a valid range')),
  _panel([
    _label('Try reversed range', weight: FontWeight.w500),
    _label('Oct 25 → Oct 23', size: 12, color: muted),
  ], onTap: () => ui.act('Try reversed range', 'checkout-must-follow-arrival')),
  _panel([
    _label('Try unavailable dates', weight: FontWeight.w500),
    _label('Oct 26–28', size: 12, color: muted),
  ], onTap: () => ui.act('Try unavailable dates')),
  _panel([
    _label('Try past dates', weight: FontWeight.w500),
    _label('Oct 1–10', size: 12, color: muted),
  ], onTap: () => ui.act('Try past dates', 'dateerror')),
  _button('Cancel date change', () => ui.act('Cancel date change')),
];

List<Widget> _requestNotSentHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Request not sent', size: 26, weight: FontWeight.bold),
  _label('Your existing trips and dates are unchanged.'),
];

List<Widget> _requestNotSentBody(PageControls ui) => [
  _button('Retry request', () => ui.act('Retry request')),
  _button('Return to review', () => ui.act('Return to review')),
  _button('Cancel', () => ui.act('Cancel', 'trips')),
];

List<Widget> _bookingResponseHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Booking response', size: 26, weight: FontWeight.bold),
  _label('Prototype controls · Choose a host outcome.'),
];

List<Widget> _bookingResponseBody(PageControls ui) => [
  _button('Host accepts', () => ui.act('Host accepts')),
  _button('Host declines', () => ui.act('Host declines')),
  _button('No response in 24 hours', () => ui.act('No response in 24 hours')),
  _button('Request again', () => ui.act('Request again')),
  _button('Return to trip', () => ui.act('Return to trip')),
];

List<Widget> _yourCampingGroupHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Your camping group', size: 26, weight: FontWeight.bold),
  _label('Shared dates update when a recipient refreshes.'),
];

List<Widget> _yourCampingGroupBody(PageControls ui) => [
  _panel([
    _label('Trip', weight: FontWeight.w500),
    _label(ui.display('Redwood Grove')),
  ], color: softGreen),
  _panel([
    _label('People', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / People', 'No invitations yet')),
  ], color: softGreen),
  _panel([
    _label('Current dates', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  _button('Open recipient view', () => ui.act('Open recipient view')),
  _button('Invite again', () => ui.act('Invite again', 'share')),
  _button('Revoke invitation', () => ui.act('Revoke invitation')),
  _button('Return to trip', () => ui.act('Return to trip')),
];

List<Widget> _youReInvitedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('You’re invited', size: 26, weight: FontWeight.bold),
  _label(
    ui.backendMode == 'firebase'
        ? 'View-only access to the shared trip.'
        : 'Recipient preview · View-only access to this trip.',
  ),
];

List<Widget> _youReInvitedBody(PageControls ui) => [
  _panel([
    _label('Campsite', weight: FontWeight.w500),
    _label(ui.display('Redwood Grove')),
  ], color: softGreen),
  _panel([
    _label('Shared dates', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  _button('Accept invitation', () => ui.act('Accept invitation')),
  _button('Decline invitation', () => ui.act('Decline invitation')),
  _button('Refresh shared plan', () => ui.act('Refresh shared plan')),
  _panel([
    _label('Try expired link', weight: FontWeight.w500),
    _label('Simulate an expired invitation', size: 12, color: muted),
  ], onTap: () => ui.act('Try expired link', 'this-invitation-is-unavailable')),
  _button(
    ui.backendMode == 'firebase' ? 'Return to trips' : 'Return to owner',
    () =>
        ui.act(ui.backendMode == 'firebase' ? 'View trips' : 'Return to owner'),
  ),
];

List<Widget> _youJoinedTheTripHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('You joined the trip', size: 26, weight: FontWeight.bold),
  _label(
    ui.backendMode == 'firebase'
        ? 'Owner’s current shared plan.'
        : 'Recipient preview · Owner’s current shared plan.',
  ),
];

List<Widget> _youJoinedTheTripBody(PageControls ui) => [
  _panel([
    _label('Campsite', weight: FontWeight.w500),
    _label(ui.display('Redwood Grove')),
  ], color: softGreen),
  _panel([
    _label('Shared dates', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  _button('Refresh shared plan', () => ui.act('Refresh shared plan')),
  _panel([
    _label('View conditions', weight: FontWeight.w500),
    _label('Check current conditions before leaving', size: 12, color: muted),
  ], onTap: () => ui.act('View conditions')),
  _button(
    ui.backendMode == 'firebase' ? 'Return to trips' : 'Return to owner',
    () =>
        ui.act(ui.backendMode == 'firebase' ? 'View trips' : 'Return to owner'),
  ),
];

List<Widget> _invitationDeclinedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Invitation declined', size: 26, weight: FontWeight.bold),
  _label('No trip was added to the recipient’s plans.'),
];

List<Widget> _invitationDeclinedBody(PageControls ui) => [
  _button(
    ui.backendMode == 'firebase' ? 'Return to trips' : 'Return to owner',
    () =>
        ui.act(ui.backendMode == 'firebase' ? 'View trips' : 'Return to owner'),
  ),
  if (ui.backendMode != 'firebase')
    _button(
      'Send another invitation',
      () => ui.act('Send another invitation', 'share'),
    ),
];

List<Widget> _thisInvitationIsUnavailableHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('This invitation is unavailable', size: 26, weight: FontWeight.bold),
  _label('It expired, was revoked, or its trip was removed.'),
];

List<Widget> _thisInvitationIsUnavailableBody(PageControls ui) => [
  _button('View your trips', () => ui.act('View your trips', 'trips')),
  if (ui.backendMode == 'firebase')
    _label('Ask the trip owner to invite you again.')
  else
    _button(
      'Ask owner to invite again',
      () => ui.act('Ask owner to invite again'),
    ),
];

List<Widget> _invitationNotSentHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Invitation not sent', size: 26, weight: FontWeight.bold),
  _label('Your trip is safe. Check the connection and retry.'),
];

List<Widget> _invitationNotSentBody(PageControls ui) => [
  _button('Retry', () => ui.act('Retry', 'shared')),
  _button('Cancel', () => ui.act('Cancel', 'share')),
];

List<Widget> _downloadedSummariesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Downloaded summaries', size: 26, weight: FontWeight.bold),
  _label('Offline copies are snapshots, not live safety advice.'),
];

List<Widget> _downloadedSummariesBody(PageControls ui) => [
  _button(
    'Choose a trip to download',
    () => ui.act('Choose a trip to download', 'trips'),
  ),
  _button('Profile', () => ui.act('Profile')),
];

List<Widget> _saveForOfflineUseHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Save for offline use', size: 26, weight: FontWeight.bold),
  _label('Demo download · Choose the connection outcome.'),
];

List<Widget> _saveForOfflineUseBody(PageControls ui) => [
  _panel([
    _label('Included in the summary', weight: FontWeight.w500),
    _label(
      'Trip dates and a conditions warning. Live weather and alerts still require a connection.',
    ),
  ], color: softGreen),
  _button(
    'Complete download',
    () => ui.act('Complete download', 'ready-for-offline-use'),
  ),
  _button(
    'Simulate connection failure',
    () => ui.act('Simulate connection failure', 'download-failed'),
  ),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _downloadFailedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Download failed', size: 26, weight: FontWeight.bold),
  _label('Your previous offline copy, if any, is unchanged.'),
];

List<Widget> _downloadFailedBody(PageControls ui) => [
  _button(
    'Retry download',
    () => ui.act('Retry download', 'save-for-offline-use'),
  ),
  _button('View saved summaries', () => ui.act('View saved summaries')),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _readyForOfflineUseHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Ready for offline use', size: 26, weight: FontWeight.bold),
  _label('The selected trip’s current dates are saved.'),
];

List<Widget> _readyForOfflineUseBody(PageControls ui) => [
  _button('Open downloaded summary', () => ui.act('Open downloaded summary')),
  _button('All downloads', () => ui.act('All downloads')),
  _button('Return to trip', () => ui.act('Return to trip')),
];

List<Widget> _noDownloadedTripsHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('No downloaded trips', size: 26, weight: FontWeight.bold),
  _label('Download a trip while connected before heading offline.'),
];

List<Widget> _noDownloadedTripsBody(PageControls ui) => [
  _button('Choose a trip', () => ui.act('Choose a trip', 'trips')),
  _button('Back to Profile', () => ui.act('Back to Profile')),
];

List<Widget> _yourOfflineCopyIsOlderHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Your offline copy is older', size: 26, weight: FontWeight.bold),
  _label('The trip’s dates changed after this download.'),
];

List<Widget> _yourOfflineCopyIsOlderBody(PageControls ui) => [
  _panel([
    _label('Downloaded dates', weight: FontWeight.w500),
    _label(
      ui.noticeValue(
        'Notice / Downloaded dates',
        'Saved dates unavailable. Refresh this download.',
      ),
    ),
  ], color: softGreen),
  _button('Refresh download', () => ui.act('Refresh download')),
  _button('View older copy', () => ui.act('View older copy', 'downloaded')),
  _button('All downloads', () => ui.act('All downloads')),
];

List<Widget> _thisTripIsNoLongerAvailableHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('This trip is no longer available', size: 26, weight: FontWeight.bold),
  _label('It may have been removed by its owner.'),
];

List<Widget> _thisTripIsNoLongerAvailableBody(PageControls ui) => [
  _button('View your trips', () => ui.act('View your trips', 'trips')),
  _button('Explore campsites', () => ui.act('Explore campsites', 'explore')),
];

List<Widget> _matchingCampsitesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Matching campsites', size: 26, weight: FontWeight.bold),
  _label('Sample inventory · Only matching sites appear.'),
];

List<Widget> _matchingCampsitesBody(PageControls ui) => [
  if (ui.ridgeMatch)
    ListTile(
      title: const Text('Sunset Ridge'),
      subtitle: const Text('RV · Up to 4 · From \$55/night'),
      onTap: () => ui.act('Sunset Ridge', 'ridge'),
    )
  else
    _panel([
      _label(ui.display('Redwood Grove'), weight: FontWeight.w500),
      _label(
        'Tent · Up to 2 · \$65/night · Pets allowed',
        size: 12,
        color: muted,
      ),
    ], onTap: () => ui.act('Redwood Grove', 'detail')),
  _button('Adjust filters', () => ui.act('Adjust filters', 'filters')),
  _button('Explore all', () => ui.act('Explore all', 'explore')),
];

List<Widget> _noMatchingCampsitesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('No matching campsites', size: 26, weight: FontWeight.bold),
  _label('Try a higher budget, fewer guests or a different site type.'),
];

List<Widget> _noMatchingCampsitesBody(PageControls ui) => [
  _button('Adjust filters', () => ui.act('Adjust filters', 'filters')),
  _button('Reset filters', () => ui.act('Reset filters', 'filters')),
  _button('Explore all', () => ui.act('Explore all', 'explore')),
];

List<Widget> _locationPermissionHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Location permission', size: 26, weight: FontWeight.bold),
  _label('Prototype permission response.'),
];

List<Widget> _locationPermissionBody(PageControls ui) => [
  _button('Allow location', () => ui.act('Allow location', 'loading')),
  _button('Deny location', () => ui.act('Deny location', 'denied')),
  _button(
    'Enter destination manually',
    () => ui.act('Enter destination manually', 'search'),
  ),
];

List<Widget> _connectionScenariosHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Connection scenarios', size: 26, weight: FontWeight.bold),
  _label('Prototype controls for search recovery.'),
];

List<Widget> _connectionScenariosBody(PageControls ui) => [
  _button('Search succeeds', () => ui.act('Search succeeds', 'loading')),
  _button(
    'Service unavailable',
    () => ui.act('Service unavailable', 'serviceerror'),
  ),
  _button('Go offline', () => ui.act('Go offline', 'offline')),
  _button('Return to Explore', () => ui.act('Return to Explore', 'explore')),
];

List<Widget> _demoPaymentResponseHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Demo payment response', size: 26, weight: FontWeight.bold),
  _label('No real payment is processed.'),
];

List<Widget> _demoPaymentResponseBody(PageControls ui) => [
  _button('Upgrade succeeds', () => ui.act('Upgrade succeeds', 'upgraded')),
  _button('Upgrade fails', () => ui.act('Upgrade fails', 'upgradeerror')),
  _button('Cancel', () => ui.act('Cancel', 'upgrade')),
];

List<Widget> _enterADisplayNameHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Enter a display name', size: 26, weight: FontWeight.bold),
  _label('An empty name cannot be saved. Your profile is unchanged.'),
];

List<Widget> _enterADisplayNameBody(PageControls ui) => [
  _button('Correct name', () => ui.act('Correct name', 'editprofile')),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _splashReadyHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('CampReady', size: 34, weight: FontWeight.bold),
  _label('Know what to expect before you camp.', color: muted),
];

List<Widget> _splashReadyBody(PageControls ui) => [
  ui.brandMark(
    'assets/images/45e519768b205109.png',
    _label('CAMPREADY', weight: FontWeight.w500, color: forest),
  ),
  _label('A little planning. A better outside.', color: muted),
];
