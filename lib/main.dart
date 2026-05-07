import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  // Ensures Flutter is ready before running Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase connection
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope wraps the whole app for Riverpod state management
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
        // Main dark background color
        scaffoldBackgroundColor: const Color(0xFF111411),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3DDB6F),   // Green accent
          surface: Color(0xFF1A1F1A),   // Card color
        ),
        useMaterial3: true,
      ),
      // StreamBuilder watches Firebase login state 24/7
      // If logged in → go to Dashboard
      // If not logged in → go to Login screen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Still connecting to Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF111411),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3DDB6F),
                ),
              ),
            );
          }
          // User is logged in
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          // User is not logged in
          return const LoginScreen();
        },
      ),
    );
  }
}