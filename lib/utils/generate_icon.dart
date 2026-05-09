import 'package:flutter/material.dart';

// This widget shows what your app icon looks like
// Use a screenshot tool to save it as app_icon.png
class AppIconWidget extends StatelessWidget {
  const AppIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF111411),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF3DDB6F),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.black,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}