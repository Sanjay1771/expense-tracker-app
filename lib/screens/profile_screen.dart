import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'export_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _settings = SettingsService();
  bool _darkMode = true;
  bool _notifications = true;
  String _currency = '₹ INR';
  double _monthlyBudget = 0;

  final _currencies = ['₹ INR', '\$ USD', '€ EUR', '£ GBP', '¥ JPY'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('Manage your account',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 28),

            // ── Profile card ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.r20),
                boxShadow: AppTheme.neonGlow(AppTheme.neonPurple,
                    blur: 24),
              ),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white
                                  .withValues(alpha: 0.7))),
                      const SizedBox(height: 2),
                      Text(_auth.userEmail,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // ── Settings section ─────────────────────────
            _section('Preferences'),
            const SizedBox(height: 12),
            _settingsCard([
              _tile(
                icon: Icons.dark_mode_rounded,
                color: AppTheme.neonPurple,
                title: 'Dark Mode',
                subtitle: 'Enabled',
                trailing: Switch.adaptive(
                  value: _darkMode,
                  onChanged: (v) async {
                    setState(() => _darkMode = v);
                    await _settings.setThemeMode(v);
                    themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                  },
                  activeTrackColor: AppTheme.neonPurple,
                  inactiveTrackColor:
                      AppTheme.textMuted.withValues(alpha: 0.2),
                ),
              ),
              _divider(),
              _tile(
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.neonBlue,
                title: 'Monthly Budget',
                subtitle: _monthlyBudget > 0 ? '₹$_monthlyBudget' : 'Not set',
                trailing: const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 18),
                onTap: _showBudgetDialog,
              ),
              _divider(),
              _tile(
                icon: Icons.category_rounded,
                color: AppTheme.neonOrange,
                title: 'Category Limits',
                subtitle: 'Manage spending per category',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                onTap: _showCategoryLimitsSheet,
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
              _divider(),
              _tile(
                icon: Icons.notifications_rounded,
                color: AppTheme.neonOrange,
                title: 'Notifications',
                subtitle: _notifications ? 'On' : 'Off',
                trailing: Switch.adaptive(
                  value: _notifications,
                  onChanged: (v) =>
                      setState(() => _notifications = v),
                  activeTrackColor: AppTheme.neonOrange,
                  inactiveTrackColor:
                      AppTheme.textMuted.withValues(alpha: 0.2),
                ),
              ),
              _divider(),
              _tile(
                icon: Icons.picture_as_pdf_rounded,
                color: AppTheme.neonRed,
                title: 'Export Report',
                subtitle: 'Generate monthly PDF report',
                trailing: const Icon(Icons.download_rounded, color: AppTheme.textMuted, size: 20),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportReportScreen())),
              ),
            ]),
            const SizedBox(height: 28),

            _section('About'),
            const SizedBox(height: 12),
            _settingsCard([
              _tile(
                icon: Icons.info_outline_rounded,
                color: AppTheme.neonBlue,
                title: 'App Version',
                subtitle: '2.0.0',
                trailing: const SizedBox(),
              ),
              _divider(),
              _tile(
                icon: Icons.code_rounded,
                color: AppTheme.neonPink,
                title: 'Built with',
                subtitle: 'Flutter & Dart',
                trailing: const SizedBox(),
              ),
            ]),
            const SizedBox(height: 28),

            // ── Logout ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text('Logout',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.neonRed.withValues(alpha: 0.12),
                  foregroundColor: AppTheme.neonRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.r16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
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

  Widget _section(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary));

  Widget _settingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.1)),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
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
            height: 1,
            color: AppTheme.textMuted.withValues(alpha: 0.1)),
      );

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
