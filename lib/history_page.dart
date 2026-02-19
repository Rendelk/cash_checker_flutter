import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/simple_page.dart';

class HomePage extends StatelessWidget {
  final Locale locale;
  const HomePage({super.key, required this.locale});

  @override
  Widget build(BuildContext context) => SimplePage(title: S.of(locale, 'home_title'));
}
