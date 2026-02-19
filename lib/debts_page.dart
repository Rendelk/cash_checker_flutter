import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/simple_page.dart';

class DebtsPage extends StatelessWidget {
  final Locale locale;
  const DebtsPage({super.key, required this.locale});

  @override
  Widget build(BuildContext context) => SimplePage(title: S.of(locale, 'debts_title'));
}
