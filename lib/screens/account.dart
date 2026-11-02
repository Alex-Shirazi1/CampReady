part of '../screens.dart';

List<Widget> _profileHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Your profile', size: 26, weight: FontWeight.bold),
  _label('CampReady Free'),
];

List<Widget> _profileBody(PageControls ui) => [
  _panel([
    _label('Name', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Name', 'John')),
  ], color: softGreen),
  _panel([
    _label('Email', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Email', 'john.doe@example.com')),
  ], color: softGreen),
  _panel([
    _label('Edit profile', weight: FontWeight.w500),
    _label('Update your sample display name', size: 12, color: muted),
  ], onTap: () => ui.act('Edit profile', 'editprofile')),
  _panel([
    _label('Explore Plus', weight: FontWeight.w500),
    _label('Multiple trips and offline summaries', size: 12, color: muted),
  ], onTap: () => ui.act('Explore Plus', 'premium')),
  _panel([
    _label('Downloaded trips', weight: FontWeight.w500),
    _label('View saved offline summaries', size: 12, color: muted),
  ], onTap: () => ui.act('Downloaded trips')),
  _panel([
    _label('Notification preferences', weight: FontWeight.w500),
    _label('Choose and save your preference', size: 12, color: muted),
  ], onTap: () => ui.act('Notification preferences', 'preferences')),
  _panel([
    _label('About CampReady', weight: FontWeight.w500),
    _label('Sources and prototype information', size: 12, color: muted),
  ], onTap: () => ui.act('About CampReady', 'about')),
  _button('Sign out', () => ui.act('Sign out', 'signout')),
  _button('Explore', () => ui.act('Explore', 'explore')),
];

List<Widget> _editprofileHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Edit profile', size: 26, weight: FontWeight.bold),
  _label('Tap the name to use a sample edit.'),
];

List<Widget> _editprofileBody(PageControls ui) => [
  ui.input('Display name', 'Display name', ''),
  _panel([
    _label('Email', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Email', 'john.doe@example.com')),
  ], color: softGreen),
  _button('Save profile', () => ui.act('Save profile', 'profilesaved')),
  _panel([
    _label('Test empty name', weight: FontWeight.w500),
    _label(
      'Show validation without changing saved data',
      size: 12,
      color: muted,
    ),
  ], onTap: () => ui.act('Test empty name', 'enter-a-display-name')),
  _button('Cancel', () => ui.act('Cancel')),
];

List<Widget> _profilesavedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Profile updated', size: 26, weight: FontWeight.bold),
  _label('Your saved name appears across your profile.'),
];

List<Widget> _profilesavedBody(PageControls ui) => [
  _panel([
    _label('Name', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Name', 'John')),
  ], color: softGreen),
  _button('Done', () => ui.act('Done')),
];

List<Widget> _profileupdatedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Your profile', size: 26, weight: FontWeight.bold),
  _label('CampReady Free'),
];

List<Widget> _profileupdatedBody(PageControls ui) => [
  _panel([
    _label('Name', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Name', 'John')),
  ], color: softGreen),
  _panel([
    _label('Email', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Email', 'john.doe@example.com')),
  ], color: softGreen),
  _panel([
    _label('Edit profile', weight: FontWeight.w500),
    _label('Update your sample display name', size: 12, color: muted),
  ], onTap: () => ui.act('Edit profile', 'editprofile')),
  _panel([
    _label('Explore Plus', weight: FontWeight.w500),
    _label('Multiple trips and offline summaries', size: 12, color: muted),
  ], onTap: () => ui.act('Explore Plus', 'premium')),
  _panel([
    _label('Downloaded trips', weight: FontWeight.w500),
    _label('View saved offline summaries', size: 12, color: muted),
  ], onTap: () => ui.act('Downloaded trips')),
  _panel([
    _label('Notification preferences', weight: FontWeight.w500),
    _label('Choose and save your preference', size: 12, color: muted),
  ], onTap: () => ui.act('Notification preferences', 'preferences')),
  _panel([
    _label('About CampReady', weight: FontWeight.w500),
    _label('Sources and prototype information', size: 12, color: muted),
  ], onTap: () => ui.act('About CampReady', 'about')),
  _button('Sign out', () => ui.act('Sign out', 'signout')),
  _button('Explore', () => ui.act('Explore', 'explore')),
];

List<Widget> _signoutHeader(PageControls ui) => [
  _back(ui),
  _label('Sign out of CampReady?', size: 26, weight: FontWeight.bold),
  _label('Your saved trips will be here when you return.', color: muted),
];

List<Widget> _signoutBody(PageControls ui) => [
  _button('Sign out', () => ui.act('Sign out', 'welcome')),
  _button('Stay signed in', () => ui.act('Stay signed in')),
];

List<Widget> _premiumHeader(PageControls ui) => [
  _back(ui),
  _label('More weekends. Less work.', size: 26, weight: FontWeight.bold),
  _label('CampReady Plus · \$2.99 / month', color: muted),
];

List<Widget> _premiumBody(PageControls ui) => [
  _panel([
    _label('Your basics stay free', weight: FontWeight.w500),
    _label(
      'Campsite browsing, conditions and essential change alerts are always included.',
    ),
  ], color: softGreen),
  _panel([
    _label('Monitor multiple trips', weight: FontWeight.w500),
    _label(
      'Keep more than one upcoming plan organized',
      size: 12,
      color: muted,
    ),
  ]),
  _panel([
    _label('Offline trip summaries', weight: FontWeight.w500),
    _label(
      'Take your saved itinerary beyond reception',
      size: 12,
      color: muted,
    ),
  ]),
  _panel([
    _label('Extended planning tools', weight: FontWeight.w500),
    _label('Compare and organize upcoming stays', size: 12, color: muted),
  ]),
  _button(
    'Try Plus · Demo upgrade',
    () => ui.act('Try Plus · Demo upgrade', 'upgrade'),
  ),
  _button('Continue with free', () => ui.act('Continue with free')),
];

List<Widget> _upgradeHeader(PageControls ui) => [
  _back(ui),
  _label('Review CampReady Plus', size: 26, weight: FontWeight.bold),
  _label('A little more room to plan.', color: muted),
];

List<Widget> _upgradeBody(PageControls ui) => [
  _label(
    'Monthly membership                  \$2.99\nCancel anytime in your profile.',
    color: muted,
  ),
  _panel([
    _label('Prototype checkout', weight: FontWeight.w500),
    _label(
      'This confirms a simulated upgrade. No payment details are collected and you won’t be charged.',
    ),
  ], color: softGreen),
  _button(
    'Confirm demo upgrade',
    () => ui.act('Confirm demo upgrade', 'demo-payment-response'),
  ),
  _button('Cancel', () => ui.act('Cancel', 'premium')),
];

List<Widget> _upgradeerrorHeader(PageControls ui) => [
  _back(ui),
  _label('Upgrade didn’t go through', size: 26, weight: FontWeight.bold),
  _label('Your free plan is still active.', color: muted),
];

List<Widget> _upgradeerrorBody(PageControls ui) => [
  _panel([
    _label('No charge was made', weight: FontWeight.w500),
    _label('We couldn’t complete the request. Please try again.'),
  ], color: softGreen),
  _button('Try again', () => ui.act('Try again', 'upgrade')),
  _button('Keep the free plan', () => ui.act('Keep the free plan')),
];

List<Widget> _upgradedHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Welcome to Plus', size: 26, weight: FontWeight.bold),
  _label('Multiple trips and offline summaries are enabled.'),
];

List<Widget> _upgradedBody(PageControls ui) => [
  _button('Continue planning', () => ui.act('Continue planning')),
  _button('View all trips', () => ui.act('View all trips', 'trips')),
  _button('Downloaded summaries', () => ui.act('Downloaded summaries')),
  _button(
    'Manage membership',
    () => ui.act('Manage membership', 'subscription'),
  ),
];

List<Widget> _subscriptionHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Your membership', size: 26, weight: FontWeight.bold),
  _label('CampReady Plus · \$2.99/month · Simulated'),
];

List<Widget> _subscriptionBody(PageControls ui) => [
  _panel([
    _label('Offline summaries', weight: FontWeight.w500),
    _label('View your actual saved copies', size: 12, color: muted),
  ], onTap: () => ui.act('Offline summaries')),
  _panel([
    _label('Your trips', weight: FontWeight.w500),
    _label('Compare and organize your saved plans', size: 12, color: muted),
  ], onTap: () => ui.act('Your trips', 'trips')),
  _button('Cancel Plus', () => ui.act('Cancel Plus', 'cancelplus')),
  _button('Back to Profile', () => ui.act('Back to Profile')),
];

List<Widget> _profileplusHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Your profile', size: 26, weight: FontWeight.bold),
  _label('CampReady Plus'),
];

List<Widget> _profileplusBody(PageControls ui) => [
  _panel([
    _label('Name', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Name', 'John')),
  ], color: softGreen),
  _panel([
    _label('Email', weight: FontWeight.w500),
    _label(ui.noticeValue('Notice / Email', 'john.doe@example.com')),
  ], color: softGreen),
  _panel([
    _label('Edit profile', weight: FontWeight.w500),
    _label('Update your sample display name', size: 12, color: muted),
  ], onTap: () => ui.act('Edit profile', 'editprofile')),
  _panel([
    _label('Manage membership', weight: FontWeight.w500),
    _label('Plan and download multiple trips', size: 12, color: muted),
  ], onTap: () => ui.act('Manage membership', 'subscription')),
  _panel([
    _label('Downloaded trips', weight: FontWeight.w500),
    _label('View saved offline summaries', size: 12, color: muted),
  ], onTap: () => ui.act('Downloaded trips')),
  _panel([
    _label('Notification preferences', weight: FontWeight.w500),
    _label('Choose and save your preference', size: 12, color: muted),
  ], onTap: () => ui.act('Notification preferences', 'preferences')),
  _panel([
    _label('About CampReady', weight: FontWeight.w500),
    _label('Sources and prototype information', size: 12, color: muted),
  ], onTap: () => ui.act('About CampReady', 'about')),
  _button('Sign out', () => ui.act('Sign out', 'signout')),
  _button('Explore', () => ui.act('Explore', 'explore')),
];

List<Widget> _cancelplusHeader(PageControls ui) => [
  _back(ui),
  _label('Cancel CampReady Plus?', size: 26, weight: FontWeight.bold),
  _label('Your core trip information stays free.', color: muted),
];

List<Widget> _cancelplusBody(PageControls ui) => [
  _label(
    'Cancellation returns this demo to the free plan. Core campsite conditions and essential alerts stay available.',
    color: muted,
  ),
  _button(
    'Cancel membership',
    () => ui.act('Cancel membership', 'pluscancelled'),
  ),
  _button('Keep Plus', () => ui.act('Keep Plus', 'subscription')),
];

List<Widget> _pluscancelledHeader(PageControls ui) => [
  _button('‹ Back', ui.back),
  _label('Membership cancelled', size: 26, weight: FontWeight.bold),
  _label('Your saved trips and downloads remain available.'),
];

List<Widget> _pluscancelledBody(PageControls ui) => [
  _panel([
    _label('Free plan', weight: FontWeight.w500),
    _label(
      'You can view existing trips. Adding another trip or refreshing downloads requires Plus.',
    ),
  ], color: softGreen),
  _button('View trips', () => ui.act('View trips', 'trips')),
  _button('Profile', () => ui.act('Profile')),
];

List<Widget> _aboutHeader(PageControls ui) => [
  _back(ui),
  _label('About CampReady', size: 26, weight: FontWeight.bold),
  _label('Know what to expect before you camp.', color: muted),
];

List<Widget> _aboutBody(PageControls ui) => [
  _label(
    'A California camping companion for finding campsites, checking conditions and sharing trip plans.',
    color: muted,
  ),
  _label(
    'Course prototype · CSEN 268\nGroup 2 · Atishay Jain & Alexander Shirazi\n\nAll campsite conditions, fees and alerts shown here are sample data. Bookings, account actions and payments are simulated.',
    color: muted,
  ),
  _button('Back to Profile', () => ui.act('Back to Profile')),
];
