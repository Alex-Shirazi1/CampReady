part of '../screens.dart';

const _warning = Color(0xFF8A5100);
const _warningSurface = Color(0xFFFFF2D8);

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

Widget _siteCard(PageControls ui, Campsite site) =>
    _campsiteCard(site.image, site.name, [
      _label(
        [
          site.area.split(',').first.toUpperCase(),
          if (ui.distanceLabel(site) != null)
            ui.distanceLabel(site)!.toUpperCase(),
        ].join(' · '),
        size: 12,
        color: muted,
      ),
      _label(site.name, size: 20, weight: FontWeight.bold),
      _label(site.summary, size: 12, color: muted),
      _label(site.fireRule, weight: FontWeight.w500, color: _warning),
      _label(site.price, weight: FontWeight.w500),
    ], () => ui.act('Open campsite: ${site.id}'));

List<Widget> _discovery(PageControls ui, {required bool guest}) {
  final query = ui.destination;
  return [
    _panel([
      _label(
        query.isNotEmpty
            ? '$query  ›'
            : ui.nearMe
            ? 'Near you  ›'
            : 'Santa Cruz, California  ›',
        weight: FontWeight.w500,
      ),
      _label('Search by city or park  →', size: 12, color: muted),
    ], onTap: () => ui.goTo(guest ? 'searchguest' : 'search')),
    if (!guest)
      Row(
        children: [
          Expanded(child: _button('Filters', () => ui.goTo('filters'))),
          const SizedBox(width: 12),
          Expanded(child: _button('Map view', () => ui.goTo('map'))),
        ],
      ),
    if (!ui.nearMe)
      _button('Use my location', () => ui.act('Use my current location')),
    _label(
      query.isNotEmpty
          ? 'Search results'
          : ui.nearMe
          ? 'Closest to you'
          : 'A weekend in the redwoods',
      size: 20,
      weight: FontWeight.bold,
    ),
    for (final site in ui.results) _siteCard(ui, site),
    if (ui.results.isEmpty)
      _panel([
        _label('No campsites found', weight: FontWeight.w500),
        _label('Try Santa Cruz or Boulder Creek.'),
      ]),
    if (query.isNotEmpty) _button('Clear search', () => ui.act('Clear search')),
    if (guest)
      _button(
        'Sign in to save your favorites',
        () => ui.act('Sign in to save your favorites', 'authgate'),
      )
    else if (ui.showDemo)
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

List<Widget> _searchguestBody(PageControls ui) => _searchBody(ui);

List<Widget> _searchHeader(PageControls ui) => [
  _back(ui),
  _label('Where are you headed?', size: 26, weight: FontWeight.bold),
  _label('Find a campsite by city or park.', color: muted),
];

List<Widget> _searchBody(PageControls ui) => [
  ui.input('Destination', 'Santa Cruz, California', ui.destination),
  _panel([
    _label('Use my current location  ›', weight: FontWeight.w500),
    _label('Sort campsites by distance from you', size: 12, color: muted),
  ], onTap: () => ui.act('Use my current location')),
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
  for (final site in ui.results)
    _panel([
      _label('${site.name}  ›', weight: FontWeight.w500),
      _label(
        [
          ?ui.distanceLabel(site),
          '\$${site.pricePerNight}/night',
          'View campsite',
        ].join(' · '),
        size: 12,
        color: muted,
      ),
    ], onTap: () => ui.act('Open campsite: ${site.id}')),
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

List<Widget> _detailBody(PageControls ui) {
  final site = ui.campsite;
  return [
    _photo(site.image, 195, site.name),
    _panel([
      _label(site.name, size: 25, weight: FontWeight.bold),
      _label([site.area, ?ui.distanceLabel(site)].join(' · '), color: muted),
    ]),
    _amenities(site),
    _label(site.description, color: muted),
    _panel(
      [
        _conditionsHeading(),
        ui.forecast(),
        _label(
          site.fireRule,
          weight: FontWeight.bold,
          color: site.conditionsKnown ? forest : _warning,
        ),
        _label(
          'View weather, fire rules & closures  ›',
          size: 12,
          color: muted,
        ),
      ],
      onTap: () => ui.act('Trip Conditions'),
      color: softGreen,
    ),
    _button('Save campsite', () => ui.act('Save campsite')),
  ];
}

List<Widget> _detailsavedHeader(PageControls ui) => [
  _back(ui),
  _label('Saved for later', size: 26, weight: FontWeight.bold),
  _label('${ui.campsite.name} · ${ui.campsite.area}', color: muted),
];

List<Widget> _detailsavedBody(PageControls ui) => [
  _photo(ui.campsite.image, 180, ui.campsite.name),
  _panel([
    _label('Added to your saved campsites', weight: FontWeight.w500),
    _label('You can find ${ui.campsite.name} in Saved.'),
  ], color: softGreen),
  _button('Plan this trip', () => ui.act('Plan this trip')),
  _button('View saved campsites', () => ui.act('View saved campsites')),
  _button('Remove from saved', () => ui.act('Remove from saved')),
];

List<Widget> _conditionsHeader(PageControls ui) => [
  _back(ui),
  _label('Trip Conditions', size: 26, weight: FontWeight.bold),
  _label('${ui.campsite.name} · Live forecast', color: muted),
];

List<Widget> _conditionsBody(PageControls ui) {
  final site = ui.campsite;
  return [
    ui.forecast(details: true),
    _panel([
      _label(site.fireRule, weight: FontWeight.w500),
      _label(site.fireDetail),
    ], color: site.conditionsKnown ? softGreen : _warningSurface),
    _panel([
      _label('Weather details  ›', weight: FontWeight.w500),
      _label('Daily forecast · Open-Meteo', size: 12, color: muted),
    ], onTap: () => ui.act('Weather details', 'weather')),
    _panel([
      _label('Fire rules  ›', weight: FontWeight.w500),
      _label(
        site.conditionsKnown
            ? 'Restriction active · View details'
            : 'Not confirmed',
        size: 12,
        color: muted,
      ),
    ], onTap: () => ui.act('Fire rules', 'fire')),
    _panel([
      _label('Trail & road access  ›', weight: FontWeight.w500),
      _label(site.closures, size: 12, color: muted),
    ], onTap: () => ui.act('Trail & road access', 'closures')),
    _label(
      'Weather: live from Open-Meteo. Fire rules and closures: sample park advisories for this course project.',
      color: muted,
    ),
    _button(
      'Plan with these conditions',
      () => ui.act('Plan with these conditions'),
    ),
  ];
}

List<Widget> _weatherHeader(PageControls ui) => [
  _back(ui),
  _label('Weather for your stay', size: 26, weight: FontWeight.bold),
  _label(ui.campsite.name, color: muted),
];

List<Widget> _weatherBody(PageControls ui) => [
  ui.forecast(details: true),
  _button(
    'Back to Trip Conditions',
    () => ui.act('Back to Trip Conditions', 'conditions'),
  ),
];

List<Widget> _fireHeader(PageControls ui) => [
  _back(ui),
  _label('Fire rules', size: 26, weight: FontWeight.bold),
  _label('${ui.campsite.name} & surrounding area', color: muted),
];

List<Widget> _fireBody(PageControls ui) => [
  _panel([
    _label(ui.campsite.fireRule, weight: FontWeight.w500),
    _label(ui.campsite.fireDetail),
  ], color: ui.campsite.conditionsKnown ? softGreen : _warningSurface),
  _label(
    'Unknown does not mean unrestricted. Check with the campsite host or land manager before you travel.',
    color: muted,
  ),
  _label('Source: sample park advisory', color: muted),
  _button('Enable trip updates', () => ui.act('Enable trip updates')),
  _button(
    'Back to Trip Conditions',
    () => ui.act('Back to Trip Conditions', 'conditions'),
  ),
];

List<Widget> _closuresHeader(PageControls ui) => [
  _back(ui),
  _label('Trail & road access', size: 26, weight: FontWeight.bold),
  _label('${ui.campsite.name} & surrounding area', color: muted),
];

List<Widget> _closuresBody(PageControls ui) => [
  _panel([
    _label(
      ui.campsite.conditionsKnown
          ? 'No closures reported'
          : 'Closure notices unavailable',
      weight: FontWeight.w500,
    ),
    _label(ui.campsite.closures),
  ], color: softGreen),
  _label(
    'This does not guarantee all routes are open. Check signs and local notices when you arrive.\n\nSource: sample park advisory',
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
  _label('${ui.campsite.name} · Park feed unavailable', color: muted),
];

List<Widget> _unknownBody(PageControls ui) => [
  _panel([
    _label('Some information is missing', weight: FontWeight.w500),
    _label(
      'We couldn’t retrieve the latest fire restrictions and closure notices.',
    ),
  ], color: softGreen),
  ui.forecast(),
  _label(
    'Unknown does not mean unrestricted. Check with the campsite host or land manager before you travel.',
    color: muted,
  ),
  _button('Try again', () => ui.act('Try again', 'unknownretry')),
  _button('Back to campsite', () => ui.act('Back to campsite')),
];

List<Widget> _unknownretryHeader(PageControls ui) => [
  _back(ui),
  _label('Still checking', size: 26, weight: FontWeight.bold),
  _label(ui.campsite.name, color: muted),
];

List<Widget> _unknownretryBody(PageControls ui) => [
  _panel([
    _label('Feed is still unavailable', weight: FontWeight.w500),
    _label(
      'Current restrictions are still unknown. Return to the campsite or choose another place.',
    ),
  ], color: softGreen),
  _button('Return to campsite', () => ui.act('Back to campsite')),
  _button(
    'Explore another campsite',
    () => ui.act('Explore another campsite', 'explore'),
  ),
];

Widget _amenities(Campsite site) => Row(
  children: [
    for (final label in [
      site.siteType == 'Tent' ? 'Tent site' : 'RV site',
      '${site.maxGuests} guests',
      site.petFriendly ? 'Pet friendly' : 'No pets',
    ])
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
