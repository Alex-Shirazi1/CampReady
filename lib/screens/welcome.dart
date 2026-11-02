part of '../screens.dart';

List<Widget> _guideHeader(PageControls ui) => [
  _label('CampReady', size: 26, weight: FontWeight.bold),
  _label('CSEN 268 · Group 2 · Prototype walkthrough'),
];

List<Widget> _guideBody(PageControls ui) => [
  _panel([
    _label('How to try it', weight: FontWeight.w500),
    _label(
      'Tap sample fields and options. Scroll long screens. Bookings, emails, payments and downloads are simulated; no real transactions occur.',
    ),
  ], color: softGreen),
  _button('Start full app', () => ui.act('Start full app', 'splash')),
  _panel([
    _label('Explore and plan', weight: FontWeight.w500),
    _label(
      'Both campsites support dates, booking and trip management',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Explore and plan', 'explore')),
  _panel([
    _label('Trips and group sharing', weight: FontWeight.w500),
    _label(
      'Seed a Redwood trip and open its saved record',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Trips and group sharing', 'trip')),
  _panel([
    _label('Account and Plus', weight: FontWeight.w500),
    _label(
      'Edit, preferences, upgrade and cancellation',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Account and Plus')),
  _panel([
    _label('Recovery scenarios', weight: FontWeight.w500),
    _label(
      'Permissions, offline, errors and empty states',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Recovery scenarios', 'states')),
  _panel([
    _label('Review scope', weight: FontWeight.w500),
    _label(
      'Two sample date ranges; all alternative outcomes are explicitly labelled demo controls.',
    ),
  ], color: softGreen),
  _label('Atishay Jain · Alexander Shirazi'),
];

List<Widget> _statesHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Alternative paths', size: 26, weight: FontWeight.bold),
  _label('Demonstrate recovery from the corresponding journeys.'),
];

List<Widget> _statesBody(PageControls ui) => [
  _panel([
    _label('Search recovery', weight: FontWeight.w500),
    _label('Offline, service unavailable and success', size: 12, color: muted),
  ], onTap: () => ui.act('Search recovery', 'connection-scenarios')),
  _panel([
    _label('Location permission', weight: FontWeight.w500),
    _label('Allow, deny or enter a destination', size: 12, color: muted),
  ], onTap: () => ui.act('Location permission', 'location-permission')),
  _panel([
    _label('Booking outcomes', weight: FontWeight.w500),
    _label(
      'Accept, decline and expire a sample request',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Booking outcomes', 'booking-response')),
  _panel([
    _label('Empty trips', weight: FontWeight.w500),
    _label(
      'Clear demo trips and their associated shares/downloads',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Empty trips', 'tripsempty')),
  _panel([
    _label('Empty saved', weight: FontWeight.w500),
    _label('Clear saved campsite', size: 12, color: muted),
  ], onTap: () => ui.act('Empty saved', 'savedempty')),
  _panel([
    _label('Payment failure', weight: FontWeight.w500),
    _label(
      'Choose success or failure without a charge',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Payment failure', 'demo-payment-response')),
  _button('Back to guide', () => ui.act('Back to guide', 'guide')),
];

List<Widget> _splashHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label('CampReady', size: 34, weight: FontWeight.bold),
  _label('Know what to expect before you camp.', color: muted),
];

List<Widget> _splashBody(PageControls ui) => [
  ui.brandMark(
    'assets/images/45e519768b205109.png',
    _label('CAMPREADY', weight: FontWeight.w500, color: forest),
  ),
  _label('A little planning. A better outside.', color: muted),
];

List<Widget> _welcomeHeader(PageControls ui) => [
  _label('CAMPREADY', size: 12, color: forest),
  _label(
    'Your next weekend,\nwell prepared.',
    size: 26,
    weight: FontWeight.bold,
  ),
  _label('Find a campsite. Know the conditions. Go ready.', color: muted),
];

List<Widget> _welcomeBody(PageControls ui) => [
  _photo('assets/images/a1bf3d0137c87172.png', 225, 'Redwood Grove'),
  _button('Get started', () => ui.act('Get started', 'guest')),
  _button('Sign in', () => ui.act('Sign in', 'signin')),
  _button('Explore as a guest', () => ui.act('Explore as a guest', 'guest')),
  _label(
    'Weather, fire rules and trail access — together in one place.',
    color: muted,
  ),
];

List<Widget> _signinHeader(PageControls ui) => [
  _back(ui),
  _label('Welcome back', size: 26, weight: FontWeight.bold),
  _label('Sign in to save trips and keep your group in sync.', color: muted),
];

List<Widget> _signinBody(PageControls ui) => [
  ui.input('Email', 'Enter your email', ''),
  ui.input('Password', 'Enter your password', ''),
  _button('Sign in', () => ui.act('Sign in', 'signinerror')),
  _button('Forgot password?', () => ui.act('Forgot password?', 'forgot')),
  _panel([
    _label('New to CampReady?  ›', weight: FontWeight.w500),
    _label('Create an account', size: 12, color: muted),
  ], onTap: () => ui.act('New to CampReady?', 'signup')),
];

List<Widget> _signinfilledHeader(PageControls ui) => [
  _back(ui),
  _label('Welcome back', size: 26, weight: FontWeight.bold),
  _label('Your next trip is waiting.', color: muted),
];

List<Widget> _signinfilledBody(PageControls ui) => [
  ui.input('Email', 'john.doe@example.com', 'john.doe@example.com'),
  ui.input('Password', '••••••••••', 'campready123'),
  _button('Sign in', () => ui.act('Sign in', 'location')),
  _button('Forgot password?', () => ui.act('Forgot password?', 'forgot')),
  _panel([
    _label('New to CampReady?  ›', weight: FontWeight.w500),
    _label('Create an account', size: 12, color: muted),
  ], onTap: () => ui.act('New to CampReady?', 'signup')),
];

List<Widget> _signinerrorHeader(PageControls ui) => [
  _back(ui),
  _label('Let’s try that again', size: 26, weight: FontWeight.bold),
  _label('Your account is safe.', color: muted),
];

List<Widget> _signinerrorBody(PageControls ui) => [
  _panel([
    _label('Couldn’t sign in', weight: FontWeight.w500),
    _label('Check your email and password, then try again.'),
  ], color: softGreen),
  ui.input('Email', 'john.doe@example.com', 'john.doe@example.com'),
  ui.input('Password', '••••••', '123456'),
  _button('Try again', () => ui.act('Try again', 'signinfilled')),
  _button('Reset password', () => ui.act('Reset password', 'forgot')),
];

List<Widget> _signupHeader(PageControls ui) => [
  _back(ui),
  _label('Make room for outside', size: 26, weight: FontWeight.bold),
  _label('Create your CampReady account.', color: muted),
];

List<Widget> _signupBody(PageControls ui) => [
  ui.input('Your name', 'Tap to enter your name', ''),
  ui.input('Email', 'Tap to enter your email', ''),
  ui.input('Password', 'At least 8 characters', ''),
  _button('Create account', () => ui.act('Create account', 'signuperror')),
  _button(
    'Already have an account? Sign in',
    () => ui.act('Already have an account? Sign in', 'signin'),
  ),
];

List<Widget> _signupfilledHeader(PageControls ui) => [
  _back(ui),
  _label('Make room for outside', size: 26, weight: FontWeight.bold),
  _label('Your details are ready.', color: muted),
];

List<Widget> _signupfilledBody(PageControls ui) => [
  ui.input('Your name', 'John Doe', 'John Doe'),
  ui.input('Email', 'john.doe@example.com', 'john.doe@example.com'),
  ui.input('Password', '••••••••••', 'campready123'),
  _button('Create account', () => ui.act('Create account', 'location')),
  _button(
    'Already have an account? Sign in',
    () => ui.act('Already have an account? Sign in', 'signin'),
  ),
];

List<Widget> _signuperrorHeader(PageControls ui) => [
  _back(ui),
  _label('Check your details', size: 26, weight: FontWeight.bold),
  _label('Let’s finish creating your account.', color: muted),
];

List<Widget> _signuperrorBody(PageControls ui) => [
  _panel([
    _label('A few details are missing', weight: FontWeight.w500),
    _label(
      'Enter a name, a valid email and a password with at least 8 characters.',
    ),
  ], color: softGreen),
  ui.input('Your name', 'John', 'John'),
  ui.input('Email', 'john@', 'john@'),
  ui.input('Password', '•••', '123'),
  _button(
    'Correct my details',
    () => ui.act('Correct my details', 'signupfilled'),
  ),
];

List<Widget> _forgotHeader(PageControls ui) => [
  _back(ui),
  _label('Forgot your password?', size: 26, weight: FontWeight.bold),
  _label('We’ll send a reset link to your email.', color: muted),
];

List<Widget> _forgotBody(PageControls ui) => [
  ui.input('Email', 'john.doe@example.com', 'john.doe@example.com'),
  _button('Send reset link', () => ui.act('Send reset link', 'resetsent')),
  _button('Back to sign in', () => ui.act('Back to sign in', 'signin')),
];

List<Widget> _resetsentHeader(PageControls ui) => [
  _back(ui),
  _label('Check your inbox', size: 26, weight: FontWeight.bold),
  _label('Your next step is in your email.', color: muted),
];

List<Widget> _resetsentBody(PageControls ui) => [
  _panel([
    _label('Reset link requested', weight: FontWeight.w500),
    _label(
      'If an account exists for john.doe@example.com, you’ll receive a password reset link.',
    ),
  ], color: softGreen),
  _label(
    'Follow the link to choose a new password, then return to CampReady.',
    color: muted,
  ),
  _button('Back to sign in', () => ui.act('Back to sign in', 'signinfilled')),
  _button('Send another link', () => ui.act('Send another link', 'forgot')),
];

List<Widget> _locationHeader(PageControls ui) => [
  _back(ui),
  _label('Find your nearby outside', size: 26, weight: FontWeight.bold),
  _label('Use your location to discover campsites around you.', color: muted),
];

List<Widget> _locationBody(PageControls ui) => [
  ui.brandMark(
    'assets/images/e2b5a5974f266a55.png',
    _label('A little more ready.', weight: FontWeight.w500, color: forest),
  ),
  _label(
    'CampReady uses your location while you search. You can always enter a destination instead.',
    color: muted,
  ),
  _button(
    'Allow location',
    () => ui.act('Allow location', 'location-permission'),
  ),
  _button(
    'Enter a destination instead',
    () => ui.act('Enter a destination instead', 'search'),
  ),
];

List<Widget> _deniedHeader(PageControls ui) => [
  _back(ui),
  _label('Pick your destination', size: 26, weight: FontWeight.bold),
  _label('Location access is off.', color: muted),
];

List<Widget> _deniedBody(PageControls ui) => [
  _panel([
    _label('You can still explore', weight: FontWeight.w500),
    _label(
      'Search by city or park. Location access isn’t required to plan a trip.',
    ),
  ], color: softGreen),
  ui.input('Destination', 'Santa Cruz, California', ''),
  _button('Search campsites', () => ui.act('Search campsites')),
  _button('Try location again', () => ui.act('Try location again', 'location')),
];

List<Widget> _authgateHeader(PageControls ui) => [
  _back(ui),
  _label('Keep your plans together', size: 26, weight: FontWeight.bold),
  _label(
    'Sign in to save campsites, create trips and share updates.',
    color: muted,
  ),
];

List<Widget> _authgateBody(PageControls ui) => [
  _panel([
    _label('Your campsite is waiting', weight: FontWeight.w500),
    _label('Create a free account to continue planning.'),
  ], color: softGreen),
  _button('Sign in', () => ui.act('Sign in', 'signin')),
  _button('Create an account', () => ui.act('Create an account', 'signup')),
  _button('Keep browsing', () => ui.act('Keep browsing', 'guestdetail')),
];
