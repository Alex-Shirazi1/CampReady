import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final screens = (jsonDecode(
    await rootBundle.loadString('assets/screens.json'),
  ) as List).cast<Map<String, dynamic>>();
  runApp(CampReady(screens: screens));
}
