// Main entry point — dark theme, auth flow, swipeable 3-tab nav with glowing FAB
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/glowing_fab.dart';
import 'models/friend_model.dart';
import 'services/friend_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST
  await Firebase.initializeApp();
  
  // Initialize notifications early so they're ready before any screen loads
  await NotificationService().initialize();

  // Initialize WorkManager for background recurring transaction checks
  await BackgroundService.initialize();

  final settings = SettingsService();
  final isDark = await settings.getThemeMode();
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Checks login state natively via Firebase Auth with safe null handling
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1. SAFELY check Firebase currentUser (MANDATORY NULL CHECK)
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    
    // 2. If user == null -> Navigate to Login
    if (firebaseUser == null) {
      if (mounted) setState(() { _loggedIn = false; _loading = false; });
      return;
    }

    // 3. User != null -> Safely synchronize our local SQLite dependencies so app doesn't crash
    try {
      final ok = await _auth.tryAutoLogin();
      if (!ok) {
        // If SharedPreferences was cleared but Firebase is active, re-sync locally safely
        await _auth.register(firebaseUser.email ?? 'unknown', 'sync123');
      }
      if (mounted) setState(() { _loggedIn = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loggedIn = false; _loading = false; });
    }
  }

  void _onLogin() => setState(() => _loggedIn = true);
  
  void _onLogout() async {
    await FirebaseAuth.instance.signOut(); // Ensure Firebase session clears
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _splash();
    // Safe Navigation Routing
    if (!_loggedIn) return LoginScreen(onLoginSuccess: _onLogin);
    return MainNavigation(onLogout: _onLogout);
  }

  Widget _splash() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppTheme.neonGlow(AppTheme.neonBlue),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppTheme.neonBlue),
          ],
        ),
      ),
    );
  }
}

/// 3-tab navigation with swipeable PageView + animated Glowing FAB
class MainNavigation extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigation({super.key, required this.onLogout});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  late PageController _pageCtrl;
  final _homeKey = GlobalKey<HomeScreenState>();
  final _analyticsKey = GlobalKey<AnalyticsScreenState>();

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onTxnAdded() {
    _homeKey.currentState?.loadData();
    _analyticsKey.currentState?.loadData();
    // Navigate to home tab
    _goToPage(0);
  }

  /// Navigate to a specific tab (via both bottom nav and swipe)
  void _goToPage(int index) {
    setState(() => _idx = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _openAddScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddTransactionScreen(onTransactionAdded: _onTxnAdded),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  void _openAddFriend() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Friend',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Friend name',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textMuted)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonBlue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await FriendService().addFriend(FriendModel(name: name, userId: AuthService().userId));
                if (ctx.mounted) Navigator.pop(ctx);
                _onTxnAdded(); // Refresh data
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        // PageView enables swipe between tabs
        child: PageView(
          controller: _pageCtrl,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) => setState(() => _idx = i),
          children: [
            HomeScreen(key: _homeKey),
            AnalyticsScreen(key: _analyticsKey),
            ProfileScreen(onLogout: widget.onLogout),
          ],
        ),
      ),

      // Expandable FAB
      floatingActionButton: GlowingFab(
        onAddTransaction: _openAddScreen,
        onAddFriend: _openAddFriend,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom nav (synced with PageView)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(
            top: BorderSide(
                color: AppTheme.textMuted.withValues(alpha: 0.08)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.bar_chart_rounded, 'Analytics'),
                _navItem(2, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final sel = _idx == i;
    return GestureDetector(
      onTap: () => _goToPage(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? AppTheme.neonBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: sel ? AppTheme.neonBlue : AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? AppTheme.neonBlue : AppTheme.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}
