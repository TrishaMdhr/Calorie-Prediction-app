import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/app_provider.dart';
import 'screens/opening_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const CalowrieApp(),
    ),
  );
}

class CalowrieApp extends StatelessWidget {
  const CalowrieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'caLOWrie',
      theme: AppTheme.theme,
      home: const OpeningScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}