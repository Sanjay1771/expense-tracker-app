import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'export_report_screen.dart';
import 'calendar_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _settings = SettingsService();

  String _userName = 'User';
  String _userEmail = 'Not available';
  bool _darkMode = true;
  String _appVersion = 'Version 1.0.0 (Build 1)';

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
    _loadUserProfile();
    _loadSettings();
    _loadAppInfo();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    String name = 'User';
    String email = 'Not available';

    if (user != null) {
      final authEmail = user.email;
      if (authEmail != null && authEmail.trim().isNotEmpty) {
        email = authEmail.trim();
      }

      try {
        final userData = await supabase
            .from('users')
            .select('name, email')
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null) {
          if (email == 'Not available' && userData['email'] != null) {
            final dbEmail = userData['email'].toString().trim();
            if (dbEmail.isNotEmpty) email = dbEmail;
          }
          if (userData['name'] != null) {
            final dbName = userData['name'].toString().trim();
            if (dbName.isNotEmpty) name = dbName;
          }
        }
      } catch (e) {
        debugPrint('[PROFILE] Fetch user from public.users failed: $e');
      }

      if (name == 'User' && user.userMetadata != null) {
        final metaName = user.userMetadata!['full_name'] ?? user.userMetadata!['name'];
        if (metaName != null && metaName.toString().trim().isNotEmpty) {
          name = metaName.toString().trim();
        }
      }
    }

    if (mounted) {
      setState(() {
        _userName = name;
        _userEmail = email;
      });
    }
  }

  Future<void> _loadSettings() async {
    final isDark = await _settings.getThemeMode();
    if (mounted) {
      setState(() {
        _darkMode = isDark;
      });
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'Version ${info.version} (Build ${info.buildNumber})';
        });
      }
    } catch (e) {
      debugPrint('[PROFILE] Fetch PackageInfo failed: $e');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
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
              _buildProfileHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildFunctionalOptions(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildPreferencesSection(),
              ),
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
          Text(
            'My Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
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
          Text(
            _userName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _userEmail,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track smart. Spend wise. Save more.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Tools & Reports', Icons.build_circle_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            _featureCard(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Export Data',
              subtitle: 'PDF report',
              gradient: const [Color(0xFFFF5252), Color(0xFFD32F2F)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportReportScreen()),
              ),
            ),
            const SizedBox(width: 12),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('App Settings', Icons.settings_rounded),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _tile(
                icon: Icons.dark_mode_rounded,
                color: Colors.purpleAccent,
                title: 'Dark Mode',
                subtitle: _darkMode ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: _darkMode,
                  onChanged: (v) async {
                    setState(() => _darkMode = v);
                    await _settings.setThemeMode(v);
                    themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              _tile(
                icon: Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
                title: 'App Version',
                subtitle: _appVersion,
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 1),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          trailing,
        ]),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: const BorderSide(color: AppTheme.error),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
