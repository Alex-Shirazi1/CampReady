import 'package:flutter/material.dart';

import 'models/campsite.dart';
import 'models/stay.dart';
import 'repositories/trip_repository.dart';
import 'services/services.dart';
import 'theme.dart';

part 'screens/welcome.dart';
part 'screens/explore.dart';
part 'screens/booking.dart';
part 'screens/trips.dart';
part 'screens/account.dart';
part 'screens/offline.dart';
part 'screens/recovery.dart';
part 'screens/registry.dart';

abstract class PageControls {
  void back();
  void goTo(String route, {Object? extra});
  void act(String label, [String? target]);
  Widget input(String label, String hint, String initial);
  Widget filter(String label);
  Widget alertSwitch(String label);
  Widget areaMap();
  Widget brandMark(String asset, Widget caption);

  /// Live forecast for the current campsite (and trip dates, if any).
  Widget forecast({bool details = false});
  Widget profilePhoto();

  Campsite get campsite;
  TripView? get trip;
  String get tripDates;
  String get draftDates;
  String? get bookingError;
  String get bookingTotal;
  bool get alertsOn;
  String get userName;
  String get userEmail;
  String get resetEmail;
  bool get plus;
  String get destination;
  List<Campsite> get results;
  List<Campsite> get savedSites;
  List<Campsite> get matches;
  List<TripView> get trips;
  List<TripView> get downloads;
  List<AppNotification> get notifications;
  AppNotification? get selectedNotification;
  String? distanceLabel(Campsite site);
  String get locationMessage;
  String get shareLink;
  bool get showDemo;
  bool get localMode;
  bool get nearMe;
}

typedef PageWidgets = List<Widget> Function(PageControls ui);

class CampPage {
  const CampPage(
    this.route,
    this.name,
    this.header,
    this.body, {
    this.tabs = false,
  });
  final String route, name;
  final PageWidgets header, body;
  final bool tabs;
  List<String> get tabAssets => const [
    'assets/images/cbc170d6adb6bb4f.png',
    'assets/images/fd4ffee87d64d43e.png',
    'assets/images/1d68519b9523cef7.png',
    'assets/images/c742f97d6c4cfb46.png',
    'assets/images/0daa5e723ae733b3.png',
  ];
}

Widget _label(
  String value, {
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = ink,
}) {
  final lineHeight = size == 34
      ? 40
      : size >= 26
      ? 32
      : size >= 20
      ? 26
      : size == 12
      ? 16
      : 20;
  return Text(
    value,
    style: TextStyle(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
    ),
  );
}

Widget _lines(List<Widget> children) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (int i = 0; i < children.length; i++) ...[
      if (i > 0) const SizedBox(height: 6),
      children[i],
    ],
  ],
);

Widget _panel(
  List<Widget> children, {
  Color color = Colors.white,
  VoidCallback? onTap,
}) {
  final panel = Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: outline),
      boxShadow: onTap == null
          ? null
          : const [
              BoxShadow(
                color: Color(0x17263329),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
    ),
    child: _lines(children),
  );
  if (onTap == null) return panel;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: panel,
  );
}

Widget _button(String label, VoidCallback onPressed) => FilledButton(
  onPressed: onPressed,
  child: Text(label, textAlign: TextAlign.center),
);

Widget _back(PageControls ui) => Align(
  alignment: Alignment.centerLeft,
  child: TextButton(onPressed: ui.back, child: const Text('‹ Back')),
);

Widget _photo(String path, double height, String label) => ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Image.asset(
    path,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    semanticLabel: label,
  ),
);

Widget _campsiteCard(
  String path,
  String name,
  List<Widget> description,
  VoidCallback onTap,
) => InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(20),
  child: Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: outline),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photo(path, 142, name),
        Padding(padding: const EdgeInsets.all(16), child: _lines(description)),
      ],
    ),
  ),
);
