import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/app_state.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState()..initCalculator(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}