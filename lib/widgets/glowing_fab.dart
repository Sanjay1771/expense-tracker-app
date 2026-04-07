// A glowing floating action button with neon pulse animation
// Directly opens Add Transaction screen on tap (single action, no menu)
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlowingFab extends StatefulWidget {
  final VoidCallback onAddTransaction;

  const GlowingFab({
    super.key,
    required this.onAddTransaction,
  });

  @override
  State<GlowingFab> createState() => _GlowingFabState();
}

class _GlowingFabState extends State<GlowingFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // Continuous pulse animation
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.25, end: 0.55).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTap: widget.onAddTransaction,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonBlue.withValues(alpha: _glowAnim.value),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppTheme.neonPurple
                        .withValues(alpha: _glowAnim.value * 0.6),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}
