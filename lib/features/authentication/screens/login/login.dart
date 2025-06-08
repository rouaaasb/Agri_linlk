import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../home/screens/home_screenn.dart';
import '../forgot_password/forgot_password.dart';
import '../signup_widgets/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _login() async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // Navigate to the home screen upon successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      print(e); // Log the error
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isSmallScreen = MediaQuery.of(context).size.height < 600;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: TSizes.xs,
                    vertical: isSmallScreen
                        ? TSizes.defaultSpace
                        : TSizes.defaultSpace + kToolbarHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo, Title & Sub-Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image(
                              height: isSmallScreen ? 100 : 150,
                              image: AssetImage(
                                  dark ? TImages.lightAppLogo : TImages.darkAppLogo),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? TSizes.xs : TSizes.sm),
                          Text(
                            TTexts.loginTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                              fontSize: isSmallScreen ? 24 : null,
                              color: dark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: TSizes.xs),
                          Text(
                            TTexts.loginSubTitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: isSmallScreen ? TSizes.sm : TSizes.md),
                        ],
                      ),

                      // Form
                      Form(
                        child: Column(
                          children: [
                            // Email
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Iconsax.direct_right,
                                    color: Color(0xFFDBCFBA)),
                                labelText: TTexts.email,
                                labelStyle: const TextStyle(color: Colors.black),
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(TSizes.inputFieldRadius),
                                  borderSide:
                                  const BorderSide(color: Color(0xFFDBCFBA)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(TSizes.inputFieldRadius),
                                  borderSide:
                                  const BorderSide(color: Color(0xFFDBCFBA)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(TSizes.inputFieldRadius),
                                  borderSide:
                                  const BorderSide(color: Color(0xFFDBCFBA)),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFDBCFBA).withOpacity(0.1),
                              ),
                            ),
                            SizedBox(
                                height: isSmallScreen
                                    ? TSizes.sm
                                    : TSizes.spaceBtwInputFields),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.black),
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Iconsax.password_check,
                                    color: Color(0xFFDBCFBA)),
                                labelText: TTexts.password,
                                labelStyle: const TextStyle(color: Colors.black),
                                suffixIcon: const Icon(Iconsax.eye_slash,
                                    color: Color(0xFFDBCFBA)),
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(TSizes.inputFieldRadius),
                                  borderSide:
                                  const BorderSide(color: Color(0xFFDBCFBA)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(TSizes.inputFieldRadius),
                                  borderSide:
                                  const BorderSide(color: Color(0xFFDBCFBA)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(TSizes.inputFieldRadius),
                                  borderSide:
                                  const BorderSide(color: Color(0xFFDBCFBA)),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFDBCFBA).withOpacity(0.1),
                              ),
                            ),
                            SizedBox(
                                height: isSmallScreen
                                    ? TSizes.sm
                                    : TSizes.spaceBtwInputFields),

                            // Remember Me & Forget Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Remember Me
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(value: true, onChanged: (value) {}),
                                    ),
                                    const SizedBox(width: TSizes.sm),
                                    Text(
                                      TTexts.rememberMe,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),

                                // Forget Password
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                          const ForgotPasswordScreen()),
                                    );
                                  },
                                  child: Text(
                                    TTexts.forgetPassword,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height: isSmallScreen
                                    ? TSizes.sm
                                    : TSizes.spaceBtwSections),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _login, // Call the _login function
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDBCFBA),
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(TTexts.signIn,
                                    style: const TextStyle(color: Colors.black)),
                              ),
                            ),
                            SizedBox(
                                height: isSmallScreen
                                    ? TSizes.sm
                                    : TSizes.spaceBtwItems),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Get.to(() => const SignUpScreen()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Color(0xFFDBCFBA)),
                                ),
                                child: Text(TTexts.createAccount,
                                    style: const TextStyle(color: Colors.black)),
                              ),
                            ),
                            SizedBox(
                                height: isSmallScreen
                                    ? TSizes.sm
                                    : TSizes.spaceBtwSections),

                            // Divider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  child: Divider(),
                                ),
                                const SizedBox(width: TSizes.sm),
                                Text(TTexts.orSignInWith,
                                    style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(width: TSizes.sm),
                                const Flexible(
                                  child: Divider(),
                                ),
                              ],
                            ),
                            SizedBox(
                                height: isSmallScreen
                                    ? TSizes.sm
                                    : TSizes.spaceBtwItems),

                            // Social Buttons (Google)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Image.asset(TImages.google, height: 24),
                                    label: const Text('Sign in with Google',
                                        style: TextStyle(color: Colors.black)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TColors.mine,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      // Google sign in logic
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}