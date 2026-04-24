import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

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
      // Auto check if user is already logged in
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Still loading Firebase
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
          // User is logged in → go to Dashboard
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          // User is not logged in → go to Login
          return const LoginScreen();
        },
      ),
    );
  }
}