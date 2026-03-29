// Login screen — premium dark theme with neon accents
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscure = true;
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
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err =
        await _auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        setState(() => _error = err);
      } else {
        widget.onLoginSuccess();
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
                    // Logo
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow:
                            AppTheme.neonGlow(AppTheme.neonBlue),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 38),
                    ),
                    const SizedBox(height: 24),
                    Text('Welcome Back',
                        style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Sign in to continue',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textMuted)),
                    const SizedBox(height: 36),

                    // Form card
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
                                              color:
                                                  AppTheme.neonRed))),
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
                                if (v == null || v.trim().isEmpty) {
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
                              obscureText: _obscure,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Enter password',
                                prefixIcon: const Icon(
                                    Icons.lock_rounded,
                                    color: AppTheme.textMuted,
                                    size: 18),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons
                                            .visibility_off_rounded
                                        : Icons
                                            .visibility_rounded,
                                    color: AppTheme.textMuted,
                                    size: 18,
                                  ),
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
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    _loading ? null : _login,
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
                                        AppTheme.neonBlue,
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
                                        : Text('Sign In',
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
                        Text("Don't have an account? ",
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textMuted)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SignupScreen(
                                      onSignupSuccess:
                                          widget.onLoginSuccess))),
                          child: Text('Sign Up',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neonBlue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Test credentials
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.neonBlue
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.neonBlue
                                .withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppTheme.neonBlue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Test: testuser@gmail.com / 123456',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.neonBlue)),
                        ),
                      ]),
                    ),
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
