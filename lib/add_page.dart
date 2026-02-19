import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/simple_page.dart';

class AddPage extends StatelessWidget {
  final Locale locale;
  const AddPage({super.key, required this.locale});

  @override
  Widget build(BuildContext context) => SimplePage(title: S.of(locale, 'add_title'));
}
