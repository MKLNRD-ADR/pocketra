import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: PocketraApp()));
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
      home: const SplashScreen(),
    );
  }
}