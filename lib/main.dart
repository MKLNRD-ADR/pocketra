import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const PocketraApp());
}

class PocketraApp extends StatelessWidget {
  const PocketraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocketra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF111411),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3DDB6F),
          surface: Color(0xFF1A1F1A),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}