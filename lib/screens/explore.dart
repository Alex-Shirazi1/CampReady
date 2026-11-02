part of '../screens.dart';

List<Widget> _exploreHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('Find your outside.', size: 26, weight: FontWeight.bold),
  _label('Conditions first. Good trips follow.', color: muted),
];

List<Widget> _exploreBody(PageControls ui) => _discovery(ui, guest: false);

List<Widget> _guestHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('Find your outside.', size: 26, weight: FontWeight.bold),
  _label('Explore California campsites.', color: muted),
];

List<Widget> _guestBody(PageControls ui) => _discovery(ui, guest: true);

List<Widget> _discovery(PageControls ui, {required bool guest}) {
  final query = ui.destination.toLowerCase().trim();
  final redwood = 'redwood grove, santa cruz, california'.contains(query);
  final sunset =
      (!guest || query.isNotEmpty) &&
      'sunset ridge, boulder creek, california'.contains(query);
  return [
    _panel([
      _label(
        query.isEmpty ? 'Santa Cruz, California  ›' : '${ui.destination}  ›',
        weight: FontWeight.w500,
      ),
      _label(
        guest ? 'Choose a destination  →' : 'Oct 23–25 · 2 travelers  →',
        size: 12,
        color: muted,
      ),
    ], onTap: () => ui.goTo(guest ? 'searchguest' : 'search')),
    if (!guest)
      Row(
        children: [
          Expanded(child: _button('Filters', () => ui.goTo('filters'))),
          const SizedBox(width: 12),
          Expanded(child: _button('Map view', () => ui.goTo('map'))),
        ],
      ),
    _label(
      query.isEmpty ? 'A weekend in the redwoods' : 'Search results',
      size: 20,
      weight: FontWeight.bold,
    ),
    if (redwood)
      _campsiteCard('assets/images/a1bf3d0137c87172.png', [
        _label('SANTA CRUZ · 45 MI', size: 12, color: muted),
        _label(ui.display('Redwood Grove'), size: 20, weight: FontWeight.bold),
        _label('Tent sites · Pets welcome', size: 12, color: muted),
        _label(
          '72° / 52°  ·  Fire restriction',
          weight: FontWeight.w500,
          color: const Color(0xFF8A5100),
        ),
        _label('\$65 / night', weight: FontWeight.w500),
      ], () => ui.act('Campsite card', guest ? 'guestdetail' : 'detail')),
    if (sunset)
      _panel([
        _label('Sunset Ridge  ›', weight: FontWeight.w500),
        _label(
          'Boulder Creek · \$55/night · Open views',
          size: 12,
          color: muted,
        ),
      ], onTap: () => ui.act('Sunset Ridge', 'ridge')),
    if (!redwood && !sunset)
      _panel([
        _label('No campsites found', weight: FontWeight.w500),
        _label('Try Santa Cruz or Boulder Creek to see the sample campsites.'),
      ]),
    if (query.isNotEmpty) _button('Clear search', () => ui.act('Clear search')),
    if (guest)
      _button(
        'Sign in to save your favorites',
        () => ui.act('Sign in to save your favorites', 'authgate'),
      )
    else
      _panel([
        _label('Connection scenarios', weight: FontWeight.w500),
        _label('Test offline and service recovery', size: 12, color: muted),
      ], onTap: () => ui.act('Connection scenarios', 'connection-scenarios')),
  ];
}

List<Widget> _searchguestHeader(PageControls ui) => [
  _back(ui),
  _label('Where are you headed?', size: 26, weight: FontWeight.bold),
  _label('Explore now. Sign in when you’re ready to save.', color: muted),
];

List<Widget> _searchguestBody(PageControls ui) => [
  ui.input('Destination', 'Santa Cruz, California', ui.destination),
  _button('Show campsites', () => ui.act('Show campsites')),
];

List<Widget> _searchHeader(PageControls ui) => [
  _back(ui),
  _label('Where are you headed?', size: 26, weight: FontWeight.bold),
  _label('Find a campsite by city or park.', color: muted),
];

List<Widget> _searchBody(PageControls ui) => [
  ui.input('Destination', 'Santa Cruz, California', ui.destination),
  _panel([
    _label('Use my current location  ›', weight: FontWeight.w500),
    _label('Discover campsites near me', size: 12, color: muted),
  ], onTap: () => ui.act('Use my current location', 'location-permission')),
  _label('Popular nearby', size: 20, weight: FontWeight.bold),
  _panel([
    _label('Santa Cruz  ›', weight: FontWeight.w500),
    _label('Redwood forests & coastal trails', size: 12, color: muted),
  ], onTap: () => ui.act('Santa Cruz')),
  _panel([
    _label('Boulder Creek  ›', weight: FontWeight.w500),
    _label('Quiet campsites in the mountains', size: 12, color: muted),
  ], onTap: () => ui.act('Boulder Creek')),
  _button('Show campsites', () => ui.act('Show campsites')),
];

List<Widget> _filtersHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Your kind of trip', size: 26, weight: FontWeight.bold),
  _label('Selections stay together until you reset them.'),
];

List<Widget> _filtersBody(PageControls ui) => [
  ui.filter('Site type'),
  ui.filter('Travelers'),
  ui.filter('Nightly budget'),
  ui.filter('Pet policy'),
  _button('Show matching campsites', () => ui.act('Show matching campsites')),
  _button('Reset filters', () => ui.act('Reset filters')),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _mapHeader(PageControls ui) => [
  _back(ui),
  _label('Find a place on the map', size: 26, weight: FontWeight.bold),
  _label('Santa Cruz & the surrounding mountains', color: muted),
];

List<Widget> _mapBody(PageControls ui) => [
  ui.areaMap(),
  _label('Illustrative map · Select a campsite below', size: 12, color: muted),
  _panel([
    _label(ui.display('Redwood Grove  ›'), weight: FontWeight.w500),
    _label('45 mi · \$65/night · View campsite', size: 12, color: muted),
  ], onTap: () => ui.act('Redwood Grove', 'detail')),
  _panel([
    _label('Sunset Ridge  ›', weight: FontWeight.w500),
    _label('38 mi · \$55/night · View campsite', size: 12, color: muted),
  ], onTap: () => ui.act('Sunset Ridge', 'ridge')),
  _button('Show list', () => ui.act('Show list', 'explore')),
];

List<Widget> _detailHeader(PageControls ui) => [
  Row(
    children: [
      _back(ui),
      const SizedBox(width: 8),
      Expanded(
        child: _label('Your campsite', size: 22, weight: FontWeight.bold),
      ),
    ],
  ),
];

List<Widget> _detailBody(PageControls ui) => [
  _photo('assets/images/a1bf3d0137c87172.png', 195, 'Redwood Grove'),
  _panel([
    _label(ui.display('Redwood Grove'), size: 25, weight: FontWeight.bold),
    _label('Santa Cruz, California', color: muted),
  ]),
  _amenities(),
  _label(
    'A quiet clearing beneath the redwoods. Set up your tent, explore nearby trails, and slow down.',
    color: muted,
  ),
  _panel(
    [
      _conditionsHeading(),
      _label('Oct 23–25 · Mostly sunny', weight: FontWeight.bold),
      _label('72° high · 52° low · 10% chance of rain', size: 12, color: muted),
      _label(
        'Fire ban in effect · No campfires',
        weight: FontWeight.bold,
        color: forest,
      ),
      _label('View weather, fire rules & closures  ›', size: 12, color: muted),
    ],
    onTap: () => ui.act('Trip Conditions', 'conditions'),

    color: softGreen,
  ),
  _button('Save campsite', () => ui.act('Save campsite', 'detailsaved')),
];

List<Widget> _guestdetailHeader(PageControls ui) => [
  Row(
    children: [
      _back(ui),
      const SizedBox(width: 8),
      Expanded(
        child: _label('Your campsite', size: 22, weight: FontWeight.bold),
      ),
    ],
  ),
];

List<Widget> _guestdetailBody(PageControls ui) => [
  _photo('assets/images/a1bf3d0137c87172.png', 195, 'Redwood Grove'),
  _panel([
    _label(ui.display('Redwood Grove'), size: 25, weight: FontWeight.bold),
    _label('Santa Cruz, California', color: muted),
  ]),
  _amenities(),
  _label(
    'A quiet clearing beneath the redwoods. Set up your tent, explore nearby trails, and slow down.',
    color: muted,
  ),
  _panel(
    [
      _conditionsHeading(),
      _label('Oct 23–25 · Mostly sunny', weight: FontWeight.bold),
      _label('72° high · 52° low · 10% chance of rain', size: 12, color: muted),
      _label(
        'Fire ban in effect · No campfires',
        weight: FontWeight.bold,
        color: forest,
      ),
      _label('View weather, fire rules & closures  ›', size: 12, color: muted),
    ],
    onTap: () => ui.goTo('conditions'),
    color: softGreen,
  ),
  _button('Save campsite', () => ui.act('Save campsite', 'authgate')),
];

List<Widget> _detailsavedHeader(PageControls ui) => [
  _back(ui),
  _label('Saved for later', size: 26, weight: FontWeight.bold),
  _label(ui.display('Redwood Grove · Santa Cruz'), color: muted),
];

List<Widget> _detailsavedBody(PageControls ui) => [
  _photo('assets/images/a1bf3d0137c87172.png', 180, 'Redwood Grove'),
  _panel([
    _label('Added to your saved campsites', weight: FontWeight.w500),
    _label(ui.display('You can find Redwood Grove in Saved.')),
  ], color: softGreen),
  _button('Plan this trip', () => ui.act('Plan this trip')),
  _button('View saved campsites', () => ui.act('View saved campsites')),
  _button('Remove from saved', () => ui.act('Remove from saved', 'detail')),
];

List<Widget> _ridgeHeader(PageControls ui) => [
  _back(ui),
  _label('Sunset Ridge', size: 26, weight: FontWeight.bold),
  _label('Boulder Creek, California', color: muted),
];

List<Widget> _ridgeBody(PageControls ui) => [
  _photo('assets/images/5b5ffeae6b8241ad.png', 180, 'Sunset Ridge'),
  _label(
    'Open mountain views, RV-friendly spaces and room for up to 4 travelers. From \$55/night.',
    color: muted,
  ),
  _panel([
    _label('Conditions unavailable', weight: FontWeight.w500),
    _label(
      'We couldn’t confirm current fire rules for this site. Check with the host before travelling.',
    ),
  ], color: softGreen),
  _button(
    'View condition details',
    () => ui.act('View condition details', 'unknown'),
  ),
  _button('Plan a trip here', () => ui.act('Plan a trip here')),
];

List<Widget> _ridgereviewHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Review and book', size: 26, weight: FontWeight.bold),
  _label('Sunset Ridge'),
];

List<Widget> _ridgereviewBody(PageControls ui) => [
  _panel([
    _label('Selected dates', weight: FontWeight.w500),
    _label(ui.display('Oct 23–25, 2026')),
  ], color: softGreen),
  _panel([
    _label('Booking total', weight: FontWeight.w500),
    _label('2 × \$55 = \$110 · No additional demo fees'),
  ], color: softGreen),
  _panel([
    _label(
      'Conditions',
      weight: FontWeight.w500,
      color: const Color(0xFF8A5100),
    ),
    _label(
      'Fire rules unconfirmed. Contact the host before travel.',
      color: const Color(0xFF8A5100),
    ),
  ], color: const Color(0xFFFFF2D8)),
  _panel([
    _label('Change dates', weight: FontWeight.w500),
    _label('Review a different range', size: 12, color: muted),
  ], onTap: () => ui.act('Change dates')),
  ui.alertSwitch('Condition-change alerts'),
  _label(ui.display('On')),
  _button('Request to book · Demo', () => ui.act('Request to book · Demo')),
  _panel([
    _label('Simulate request failure', weight: FontWeight.w500),
    _label('No trip is created by this test', size: 12, color: muted),
  ], onTap: () => ui.act('Simulate request failure', 'request-not-sent')),
  _button('Cancel', () => ui.act('Cancel', 'ridge')),
];

List<Widget> _ridgeconfirmedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Request sent', size: 26, weight: FontWeight.bold),
  _label('Prototype only · No charge or reservation'),
];

List<Widget> _ridgeconfirmedBody(PageControls ui) => [
  _panel([
    _label('Waiting for the host', weight: FontWeight.w500),
    _label(
      'A response is due within 24 hours. Follow booking status from your trip.',
    ),
  ], color: softGreen),
  _button('View trip', () => ui.act('View trip')),
  _button('All trips', () => ui.act('All trips', 'trips')),
];

List<Widget> _ridgetripHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Sunset Ridge', size: 26, weight: FontWeight.bold),
  _label('Your trip · Booking is simulated'),
];

List<Widget> _ridgetripBody(PageControls ui) => [
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
    _label('Confirm fire rules with the host', size: 12, color: muted),
  ], onTap: () => ui.act('Trip conditions', 'unknown')),
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

List<Widget> _conditionsHeader(PageControls ui) => [
  _back(ui),
  _label('Trip Conditions', size: 26, weight: FontWeight.bold),
  _label('Sample forecast · Oct 23–25', color: muted),
];

List<Widget> _conditionsBody(PageControls ui) => [
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
    _label('No campfires. Confirm permitted cooking equipment with the host.'),
  ], color: softGreen),
  _panel([
    _label('Weather details  ›', weight: FontWeight.w500),
    _label('3-day forecast · Updated 9:00 AM', size: 12, color: muted),
  ], onTap: () => ui.act('Weather details', 'weather')),
  _panel([
    _label('Fire rules  ›', weight: FontWeight.w500),
    _label('Restriction active · View details', size: 12, color: muted),
  ], onTap: () => ui.act('Fire rules', 'fire')),
  _panel([
    _label('Trail & road access  ›', weight: FontWeight.w500),
    _label('No closures reported · View details', size: 12, color: muted),
  ], onTap: () => ui.act('Trail & road access', 'closures')),
  _label(
    'Sources: example weather and park feeds. Last checked today, 9:00 AM. Prototype data.',
    color: muted,
  ),
  _button(
    'Plan with these conditions',
    () => ui.act('Plan with these conditions'),
  ),
];

List<Widget> _weatherHeader(PageControls ui) => [
  _back(ui),
  _label('Weather for your stay', size: 26, weight: FontWeight.bold),
  _label('Sample forecast · Oct 23–25', color: muted),
];

List<Widget> _weatherBody(PageControls ui) => [
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
    _label('Pack for cool evenings', weight: FontWeight.w500),
    _label(
      'Daytime highs around 72°F, with nights near 52°F. Bring warm layers.',
    ),
  ], color: softGreen),
  _label(
    'Rain chance: 10–20%\nWind: W 5–10 mph\nForecast last checked: Today, 9:00 AM\nSource: sample weather feed',
    color: muted,
  ),
  _button(
    'Back to Trip Conditions',
    () => ui.act('Back to Trip Conditions', 'conditions'),
  ),
];

List<Widget> _fireHeader(PageControls ui) => [
  _back(ui),
  _label('Fire rules', size: 26, weight: FontWeight.bold),
  _label(ui.display('Redwood Grove & surrounding area'), color: muted),
];

List<Widget> _fireBody(PageControls ui) => [
  _panel([
    _label('No campfires', weight: FontWeight.w500),
    _label('A fire restriction is in effect for your planned dates.'),
  ], color: softGreen),
  _label(
    'Avoid wood and charcoal fires. Ask the campsite host which cooking equipment is permitted before packing.',
    color: muted,
  ),
  _label('Source: sample park advisory\nUpdated today, 9:00 AM', color: muted),
  _button('Enable trip updates', () => ui.act('Enable trip updates')),
  _button(
    'Back to Trip Conditions',
    () => ui.act('Back to Trip Conditions', 'conditions'),
  ),
];

List<Widget> _closuresHeader(PageControls ui) => [
  _back(ui),
  _label('Trail & road access', size: 26, weight: FontWeight.bold),
  _label(ui.display('Redwood Grove & surrounding area'), color: muted),
];

List<Widget> _closuresBody(PageControls ui) => [
  _panel([
    _label('No closures reported', weight: FontWeight.w500),
    _label(
      'The current feed lists no trail or road closures near this campsite.',
    ),
  ], color: softGreen),
  _label(
    'This does not guarantee all routes are open. Check signs and local notices when you arrive.\n\nSource: sample park advisory\nUpdated today, 9:00 AM',
    color: muted,
  ),
  _button('Enable trip updates', () => ui.act('Enable trip updates')),
  _button(
    'Back to Trip Conditions',
    () => ui.act('Back to Trip Conditions', 'conditions'),
  ),
];

List<Widget> _unknownHeader(PageControls ui) => [
  _back(ui),
  _label('Conditions not confirmed', size: 26, weight: FontWeight.bold),
  _label('Sunset Ridge · Data unavailable', color: muted),
];

List<Widget> _unknownBody(PageControls ui) => [
  _panel([
    _label('Some information is missing', weight: FontWeight.w500),
    _label(
      'We couldn’t retrieve the latest fire restrictions and closure notices.',
    ),
  ], color: softGreen),
  _label(
    'Unknown does not mean unrestricted. Check with the campsite host or land manager before you travel.',
    color: muted,
  ),
  _button('Try again', () => ui.act('Try again', 'unknownretry')),
  _button('Back to campsite', () => ui.act('Back to campsite', 'ridge')),
];

List<Widget> _unknownretryHeader(PageControls ui) => [
  _back(ui),
  _label('Still checking', size: 26, weight: FontWeight.bold),
  _label('Sunset Ridge · Oct 23–25', color: muted),
];

List<Widget> _unknownretryBody(PageControls ui) => [
  _panel([
    _label('Feed is still unavailable', weight: FontWeight.w500),
    _label(
      'Current restrictions are still unknown. Return to the campsite or choose another place.',
    ),
  ], color: softGreen),
  _button('Return to campsite', () => ui.act('Return to campsite', 'ridge')),
  _button(
    'Explore another campsite',
    () => ui.act('Explore another campsite', 'explore'),
  ),
];

Widget _amenities() => Row(
  children: [
    for (final label in ['Tent site', '2 guests', 'Pet friendly'])
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _label(label, size: 12),
        ),
      ),
  ],
);

Widget _conditionsHeading() => Row(
  children: [
    Image.asset('assets/images/b2eee30e9d38261e.png', width: 24, height: 24),
    const SizedBox(width: 8),
    Expanded(
      child: _label(
        'Trip Conditions',
        size: 18,
        weight: FontWeight.bold,
        color: forest,
      ),
    ),
  ],
);
