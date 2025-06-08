import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfaa/features/authentication/screens/signup_widgets/signup.dart';

import '../../../../utils/constants/colors.dart';



class VerifyEmailScreen extends StatefulWidget {
  final String email;
  
  const VerifyEmailScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // final _authController = Get.find<LoginScreen>();
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Skipped email verification logic for UI preview
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Close button at the top right
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    // Navigate directly to the create account screen
                    Get.offAll(() => const SignUpScreen());
                  },
                ),
              ),
              
              // Illustration
              Image.asset(
                'assets/images/sammy-line-man-receives-a-mail.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Verify your email address!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Email text
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                'Congratulations! Your Account Awaits - Verify Your Email to Start Shopping and Experience a World of Unrivaled Deals and Personalized Offers.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Mocked: Just show a snackbar for UI test
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Continue pressed (UI test only)')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.mine,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Resend email button
              TextButton(
                onPressed: _isResending
                    ? null
                    : () async {
                        setState(() => _isResending = true);
                        await Future.delayed(const Duration(seconds: 1));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resend Email pressed (UI test only)')),
                        );
                        setState(() => _isResending = false);
                      },
                child: Text(
                  'Resend Email',
                  style: TextStyle(
                    fontSize: 14,
                    color: TColors.mine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}