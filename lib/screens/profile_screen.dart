import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'export_report_screen.dart';
import 'recurring_screen.dart';
import 'calendar_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _settings = SettingsService();
  bool _darkMode = true;
  bool _notifications = true;
  String _currency = '₹ INR';
  double _monthlyBudget = 0;

  final _currencies = ['₹ INR', '\$ USD', '€ EUR', '£ GBP', '¥ JPY'];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final isDark = await _settings.getThemeMode();
    final budget = await _settings.getMonthlyBudget(_auth.userId);
    if (mounted) {
      setState(() {
        _darkMode = isDark;
        _monthlyBudget = budget;
      });
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r16)),
        title: Text('Logout',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _auth.logout();
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // ── Gradient Header with Profile ────────────────
              _buildProfileHeader(),

              // ── Quick Stats Row ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildQuickStats(),
              ),

              // ── Feature Grid ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildFeatureGrid(),
              ),

              // ── Settings Section ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildSettingsSection(),
              ),

              // ── About Section ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildAboutSection(),
              ),

              // ── Logout Button ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildLogoutButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── PROFILE HEADER ────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF4834D4),
            Color(0xFF00CEFF),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          // ── Title ──
          Text(
            'My Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // ── Avatar ──
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Name ──
          Text(
            'SmartSpend User',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // ── Email ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              FirebaseAuth.instance.currentUser == null
                  ? 'No user logged in'
                  : FirebaseAuth.instance.currentUser?.email ?? 'Email not available',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),

          // ── Tagline ──
          Text(
            'Track smart. Spend wise. Save more.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── QUICK STATS ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Budget',
          value: _monthlyBudget > 0
              ? '₹${_monthlyBudget.toStringAsFixed(0)}'
              : 'Not set',
          color: AppTheme.neonBlue,
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.currency_exchange_rounded,
          label: 'Currency',
          value: _currency.split(' ').first,
          color: AppTheme.neonGreen,
        ),
        const SizedBox(width: 12),
        _statCard(
          icon: Icons.palette_rounded,
          label: 'Theme',
          value: _darkMode ? 'Dark' : 'Light',
          color: AppTheme.neonPurple,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── FEATURE GRID ──────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  Widget _buildFeatureGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Quick Actions', Icons.bolt_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            _featureCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Budget',
              subtitle: 'Set monthly',
              gradient: const [Color(0xFF00D4FF), Color(0xFF0097E6)],
              onTap: _showBudgetDialog,
            ),
            const SizedBox(width: 12),
            _featureCard(
              icon: Icons.category_rounded,
              label: 'Categories',
              subtitle: 'Set limits',
              gradient: const [Color(0xFFFF9100), Color(0xFFFF6D00)],
              onTap: _showCategoryLimitsSheet,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _featureCard(
              icon: Icons.repeat_rounded,
              label: 'Recurring',
              subtitle: 'Auto expenses',
              gradient: const [Color(0xFFE040FB), Color(0xFFAB47BC)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecurringScreen()),
              ),
            ),
            const SizedBox(width: 12),
            _featureCard(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Export',
              subtitle: 'PDF report',
              gradient: const [Color(0xFFFF5252), Color(0xFFD32F2F)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportReportScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _featureCard(
              icon: Icons.calendar_month_rounded,
              label: 'Calendar',
              subtitle: 'Spending map',
              gradient: const [Color(0xFF00E676), Color(0xFF00C853)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient[0].withValues(alpha: 0.15),
                gradient[1].withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.r20),
            border: Border.all(
              color: gradient[0].withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── SETTINGS SECTION ──────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Settings', Icons.settings_rounded),
        const SizedBox(height: 14),
        _settingsCard([
          _tile(
            icon: Icons.dark_mode_rounded,
            color: AppTheme.neonPurple,
            title: 'Dark Mode',
            subtitle: _darkMode ? 'Enabled' : 'Disabled',
            trailing: Switch.adaptive(
              value: _darkMode,
              onChanged: (v) async {
                setState(() => _darkMode = v);
                await _settings.setThemeMode(v);
                themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
              },
              activeTrackColor: AppTheme.neonPurple,
              inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.2),
            ),
          ),
          _divider(),
          _tile(
            icon: Icons.notifications_rounded,
            color: AppTheme.neonOrange,
            title: 'Notifications',
            subtitle: _notifications ? 'On' : 'Off',
            trailing: Switch.adaptive(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
              activeTrackColor: AppTheme.neonOrange,
              inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.2),
            ),
          ),
          _divider(),
          _tile(
            icon: Icons.currency_exchange_rounded,
            color: AppTheme.neonGreen,
            title: 'Currency',
            subtitle: _currency,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
            onTap: _showCurrencyPicker,
          ),
        ]),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── ABOUT SECTION ─────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('About', Icons.info_outline_rounded),
        const SizedBox(height: 14),

        // ── Description Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border:
                Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SmartSpend',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v2.0.0',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Your AI-powered expense tracker that helps you manage finances, '
                'set budgets, track recurring payments, and get smart insights — '
                'all in one beautiful app.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Divider(
                  color: AppTheme.textMuted.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  _aboutChip(Icons.code_rounded, 'Flutter & Dart'),
                  const SizedBox(width: 8),
                  _aboutChip(Icons.bolt_rounded, 'AI Powered'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.neonBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── LOGOUT BUTTON ─────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text('Logout',
            style:
                GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonRed.withValues(alpha: 0.1),
          foregroundColor: AppTheme.neonRed,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r16),
            side: BorderSide(
              color: AppTheme.neonRed.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── SHARED HELPERS ────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neonBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _settingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border:
              Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
        ),
        child: Column(children: children),
      );

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.r16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          trailing,
        ]),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(
            height: 1, color: AppTheme.textMuted.withValues(alpha: 0.1)),
      );

  // ═══════════════════════════════════════════════════════════
  // ── DIALOGS & SHEETS (LOGIC UNCHANGED) ────────────────────
  // ═══════════════════════════════════════════════════════════

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select Currency',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ..._currencies.map((c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(c.split(' ').first,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                  title: Text(c,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppTheme.textPrimary)),
                  trailing: _currency == c
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppTheme.neonGreen)
                      : null,
                  onTap: () {
                    setState(() => _currency = c);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog() {
    final ctrl = TextEditingController(text: _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Set Monthly Budget', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Enter amount (e.g. 20000)', hintStyle: TextStyle(color: AppTheme.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text) ?? 0;
              await _settings.setMonthlyBudget(_auth.userId, val);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSettings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCategoryLimitsSheet() async {
    final categories = ['Food', 'Travel', 'Shopping', 'Bills', 'Entertainment', 'Other'];
    final limits = <String, double>{};
    for (final cat in categories) {
      limits[cat] = await _settings.getCategoryBudget(_auth.userId, cat);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Category Limits', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              ...categories.map((cat) {
                final ctrl = TextEditingController(text: limits[cat]! > 0 ? limits[cat]!.toStringAsFixed(0) : '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(cat, style: const TextStyle(color: AppTheme.textSecondary))),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(hintText: 'Limit', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          onChanged: (v) {
                            limits[cat] = double.tryParse(v) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    for (final entry in limits.entries) {
                      await _settings.setCategoryBudget(_auth.userId, entry.key, entry.value);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save All Limits'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
