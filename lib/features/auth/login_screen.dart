import 'package:flutter/material.dart';

import '../navigation/main_bottom_nav_screen.dart';
import 'google_sign_in_service.dart';
import 'auth_service.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Color bgColor = Color(0xFFF6F7FB);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color subText = Color(0xFF6B7280);
  static const Color googleBorder = Color(0xFFE5E7EB);
  static const Color primary = Color(0xFF5B67F1);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final credential = await GoogleSignInService.instance.signIn();

      if (!mounted) return;

      if (credential?.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainBottomNavScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }
  Future<void> _handleGuestLogin() async {
    try {
      final credential = await AuthService.instance.signInAsGuest();

      if (!mounted) return;

      if (credential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainBottomNavScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Guest login failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginScreen.bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: LoginScreen.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      size: 56,
                      color: LoginScreen.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to GameBox',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: LoginScreen.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'One place for kids games, routines, rewards, and healthy play.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: LoginScreen.subText,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: LoginScreen.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: OutlinedButton(
                            onPressed:
                            _isGoogleLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: LoginScreen.googleBorder,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isGoogleLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                                : const Row(
                              children: [
                                Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 32,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Continue with Google',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: LoginScreen.textDark,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

// GUEST LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _handleGuestLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LoginScreen.primary.withOpacity(0.12),
                              foregroundColor: LoginScreen.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Continue as Guest',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'You can upgrade your account later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: LoginScreen.subText,
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
      ),
    );
  }
}