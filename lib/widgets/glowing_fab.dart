// An expandable floating action button with neon glow, staggered options, and blur backdrop
// Features: Plus rotation, backdrop filter, scale and fade animations
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class GlowingFab extends StatefulWidget {
  final VoidCallback onAddTransaction;
  final VoidCallback onAddFriend;

  const GlowingFab({
    super.key,
    required this.onAddTransaction,
    required this.onAddFriend,
  });

  @override
  State<GlowingFab> createState() => _GlowingFabState();
}

class _GlowingFabState extends State<GlowingFab> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _expandCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // Continuous pulse animation
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    
    // Expansion animation (when clicked)
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));

    _glowAnim = Tween<double>(begin: 0.25, end: 0.55).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
        
    // Rotates the plus to an 'X'
    _rotateAnim = Tween<double>(begin: 0, end: 0.125).animate(
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _expandCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMenu() {
    if (_isOpen) {
      _expandCtrl.reverse().then((_) {
        _removeOverlay();
        setState(() => _isOpen = false);
      });
    } else {
      setState(() => _isOpen = true);
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
      _expandCtrl.forward();
    }
  }

  void _handleAction(VoidCallback action) {
    _toggleMenu();
    action();
  }

  OverlayEntry _createOverlay() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return OverlayEntry(builder: (_) => const SizedBox());
    
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Blurry Backdrop (tappable to close)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                behavior: HitTestBehavior.opaque,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                      parent: _expandCtrl, curve: Curves.easeOut),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(color: AppTheme.bg.withValues(alpha: 0.85)),
                  ),
                ),
              ),
            ),
            
            // Staggered Menu Options
            Positioned(
              bottom: MediaQuery.of(context).size.height - offset.dy + 16,
              right: MediaQuery.of(context).size.width - offset.dx - size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMenuItem(
                    icon: Icons.person_add_rounded,
                    label: 'Add Friend / Split',
                    color: AppTheme.neonPurple,
                    onTap: () => _handleAction(widget.onAddFriend),
                    index: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.add_rounded,
                    label: 'Add Transaction',
                    color: AppTheme.neonBlue,
                    onTap: () => _handleAction(widget.onAddTransaction),
                    index: 0,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int index,
  }) {
    // Delay each item's animation slightly to create a staggered entrance
    final startDelay = 0.1 * index;
    final anim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Interval(startDelay, 1.0, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: anim,
      child: FadeTransition(
        opacity: anim,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
                  ],
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _expandCtrl]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTap: _toggleMenu,
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
              child: RotationTransition(
                turns: _rotateAnim,
                child: Icon(
                  _isOpen ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
