// Signup screen — dark theme matching login design
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onSignupSuccess;
  const SignupScreen({super.key, required this.onSignupSuccess});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obs1 = true;
  bool _obs2 = true;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    debugPrint('🔵 [SIGNUP] Button clicked. Attempting signup for: $email');

    try {
      debugPrint('🔵 [SIGNUP] Before Firebase Auth createUser call...');
      // 🔥 STRICT FIX: FORCE FIREBASE SIGNUP
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      debugPrint('✅ [SIGNUP] Firebase Signup SUCCESS! User UID: ${userCredential.user?.uid}');
      
      // Sync local user so transactions and mapping don't crash the app
      final localErr = await _auth.register(email, password);
      if (localErr != null) {
          debugPrint('⚠️ [SIGNUP] Local sync warned: $localErr');
      }

      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context); // close signup screen properly
        widget.onSignupSuccess(); // trigger home navigation callback
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [SIGNUP] Firebase Signup FAILED. Code: ${e.code}, Message: ${e.message}');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message ?? 'Signup failed. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('❌ [SIGNUP] Unknown Error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'An unexpected error occurred.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.textMuted
                                    .withValues(alpha: 0.12)),
                          ),
                          child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.textPrimary,
                              size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow:
                            AppTheme.neonGlow(AppTheme.neonPurple),
                      ),
                      child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 34),
                    ),
                    const SizedBox(height: 20),
                    Text('Create Account',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Sign up to get started',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textMuted)),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius:
                            BorderRadius.circular(AppTheme.r20),
                        border: Border.all(
                            color: AppTheme.textMuted
                                .withValues(alpha: 0.1)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonRed
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Row(children: [
                                  const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppTheme.neonRed,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(_error!,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppTheme
                                                  .neonRed))),
                                ]),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _lbl('Email'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType:
                                  TextInputType.emailAddress,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                                prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: AppTheme.textMuted,
                                    size: 18),
                              ),
                              validator: (v) {
                                if (v == null ||
                                    v.trim().isEmpty) {
                                  return 'Enter email';
                                }
                                if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v.trim())) {
                                  return 'Invalid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _lbl('Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obs1,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Min 6 characters',
                                prefixIcon: const Icon(
                                    Icons.lock_rounded,
                                    color: AppTheme.textMuted,
                                    size: 18),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obs1 = !_obs1),
                                  child: Icon(
                                      _obs1
                                          ? Icons
                                              .visibility_off_rounded
                                          : Icons
                                              .visibility_rounded,
                                      color: AppTheme.textMuted,
                                      size: 18),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter password';
                                }
                                if (v.length < 6) {
                                  return 'Min 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _lbl('Confirm Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obs2,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Re-enter password',
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppTheme.textMuted,
                                    size: 18),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obs2 = !_obs2),
                                  child: Icon(
                                      _obs2
                                          ? Icons
                                              .visibility_off_rounded
                                          : Icons
                                              .visibility_rounded,
                                      color: AppTheme.textMuted,
                                      size: 18),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passCtrl.text) {
                                  return 'Passwords don\'t match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    _loading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppTheme.r16)),
                                  elevation: 0,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient:
                                        AppTheme.primaryGradient,
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppTheme.r16),
                                    boxShadow: AppTheme.neonGlow(
                                        AppTheme.neonPurple,
                                        blur: 14),
                                  ),
                                  child: Center(
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child:
                                                CircularProgressIndicator(
                                                    strokeWidth:
                                                        2.5,
                                                    color: Colors
                                                        .white))
                                        : Text('Create Account',
                                            style:
                                                GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                    color: Colors
                                                        .white)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textMuted)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('Sign In',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neonBlue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary));
}
