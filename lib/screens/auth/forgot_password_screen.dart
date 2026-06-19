import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later';
          break;
        default:
          message = 'Something went wrong. Try again';
      }
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111411),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _emailSent ? _buildSuccessView() : _buildEmailInputView(),
        ),
      ),
    );
  }

  Widget _buildEmailInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A1F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A3A2F)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Logo
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3DDB6F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pocketra',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Title
        const Text(
          'Forgot\npassword?',
          style: TextStyle(color: Colors.white, fontSize: 38, height: 1.1),
        ),

        const SizedBox(height: 12),

        const Text(
          "No worries! Enter your email and we'll send you a reset link.",
          style: TextStyle(color: Color(0xFF6B7C75), fontSize: 15),
        ),

        const SizedBox(height: 40),

        // Email label
        const Text(
          'Email',
          style: TextStyle(color: Color(0xFFB0C4B8), fontSize: 13),
        ),
        const SizedBox(height: 8),

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'mike@example.com',
            hintStyle: const TextStyle(color: Color(0xFF4A5A50)),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF6B7C75),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFF1A2A1F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A3A2F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A3A2F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3DDB6F),
                width: 1.5,
              ),
            ),
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFF87171),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 32),

        // Send reset link button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DDB6F),
              disabledBackgroundColor: const Color(0xFF1A3A2A),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Send Reset Link', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.send_outlined, size: 18),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 32),

        // Back to login
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Remembered it? ',
                    style: TextStyle(color: Color(0xFF6B7C75)),
                  ),
                  TextSpan(
                    text: 'Log In',
                    style: TextStyle(color: Color(0xFF3DDB6F)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final sentEmail = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A1F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A3A2F)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),

        const SizedBox(height: 60),

        // Success icon
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF3DDB6F).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3DDB6F).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFF3DDB6F),
              size: 44,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Title
        const Center(
          child: Text(
            'Check your email',
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: Text(
            'We sent a password reset link to\n$sentEmail',
            style: const TextStyle(
              color: Color(0xFF6B7C75),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Steps info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A1F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A3A2F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What to do next:',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _step('1', 'Open your email app'),
              const SizedBox(height: 12),
              _step('2', 'Find the email from Pocketra'),
              const SizedBox(height: 12),
              _step('3', 'Click the reset link'),
              const SizedBox(height: 12),
              _step('4', 'Set your new password'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Back to login button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DDB6F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Back to Login', style: TextStyle(fontSize: 16)),
          ),
        ),

        const SizedBox(height: 20),

        // Try again
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _emailSent = false);
            },
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 14),
                children: [
                  TextSpan(
                    text: "Didn't receive it? ",
                    style: TextStyle(color: Color(0xFF6B7C75)),
                  ),
                  TextSpan(
                    text: 'Try again',
                    style: TextStyle(color: Color(0xFF3DDB6F)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _step(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF3DDB6F).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Color(0xFF3DDB6F), fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Color(0xFF6B7C75), fontSize: 14),
        ),
      ],
    );
  }
}
