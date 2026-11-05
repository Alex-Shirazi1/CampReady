import 'package:flutter/material.dart';

import 'theme.dart';
import 'services/services.dart';

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
  void goTo(String route);
  void act(String label, [String? target]);
  String display(String value);
  String noticeValue(String name, String fallback);
  Widget input(String label, String hint, String initial);
  Widget filter(String label);
  Widget alertSwitch(String label);
  Widget areaMap();
  Widget brandMark(String asset, Widget caption);
  bool get ridgeMatch;
  bool get hasRedwoodAlert;
  /// Notification records for this account (MessagingService /
  /// Firestore), newest first. Empty until a condition changes.
  List<AppNotification> get notifications;
  /// 'firebase' when Firebase is configured, otherwise 'local'.
  String get backendMode;
  String get destination;
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
  String? get statusAsset => 'assets/images/a1ff48a2723cc98a.png';
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
        _photo(path, 142, 'Redwood Grove'),
        Padding(padding: const EdgeInsets.all(16), child: _lines(description)),
      ],
    ),
  ),
);

Widget _forecastDay(List<Widget> forecast) => Expanded(
  child: Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: _lines(forecast),
  ),
);
