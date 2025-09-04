import 'package:flutter/material.dart';

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFF2E6FF2),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
  visualDensity: VisualDensity.standard,
);
