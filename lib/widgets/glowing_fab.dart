import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlowingFab extends StatefulWidget {
  final VoidCallback onAddTransaction;
  final IconData icon;

  const GlowingFab({
    super.key,
    required this.onAddTransaction,
    this.icon = Icons.add_rounded,
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
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.3, end: 0.6).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.seedColor.withValues(alpha: _glowAnim.value),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
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
