// Main entry point — dark theme, auth flow, swipeable 4-tab nav with glowing FAB
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/friends_screen.dart';
import 'widgets/glowing_fab.dart';
import 'services/settings_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST (kept during migration)
  await Firebase.initializeApp();

  // Initialize Supabase (runs alongside Firebase — no conflicts)
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  debugPrint('✅ Supabase initialized successfully');


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
      builder: (context, mode, child) {
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

/// Checks login state via Supabase Auth with safe null handling
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  bool _loading = true;
  bool _loggedIn = false;

  // Supabase auth subscription (listens for Google OAuth redirects)
  late final dynamic _supabaseAuthSub;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _listenToSupabaseAuth();
  }

  @override
  void dispose() {
    // Cancel the Supabase auth listener
    try {
      _supabaseAuthSub.cancel();
    } catch (_) {}
    super.dispose();
  }

  /// Listen for Supabase auth state changes (Google OAuth callback)
  void _listenToSupabaseAuth() {
    _supabaseAuthSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        debugPrint('🔔 [AUTH] Supabase auth event: $event');

        if (event == AuthChangeEvent.signedIn) {
          // User returned from Google OAuth — sync session
          final err = await _auth.handleSupabaseSession();
          if (err == null && mounted) {
            setState(() {
              _loggedIn = true;
              _loading = false;
            });
          } else {
            debugPrint('⚠️ [AUTH] Supabase session sync failed: $err');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          if (mounted) {
            setState(() => _loggedIn = false);
          }
        }
      },
      onError: (e) {
        debugPrint('❌ [AUTH] Supabase auth listener error: $e');
      },
    );
  }

  Future<void> _checkAuth() async {
    // 1. Check for an existing Supabase session
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    if (supabaseSession != null) {
      debugPrint('🔵 [AUTH] Found existing Supabase session, syncing...');
      final err = await _auth.handleSupabaseSession();
      if (err == null) {
        if (mounted) setState(() { _loggedIn = true; _loading = false; });
        return;
      }
      debugPrint('⚠️ [AUTH] Supabase session sync failed: $err');
    }

    // 2. Try restoring from local SharedPreferences
    try {
      final ok = await _auth.tryAutoLogin();
      if (ok && mounted) {
        setState(() { _loggedIn = true; _loading = false; });
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH] Auto-login failed: $e');
    }

    // 3. No session found → show login
    if (mounted) setState(() { _loggedIn = false; _loading = false; });
  }

  void _onLogin() => setState(() => _loggedIn = true);
  
  void _onLogout() async {
    await _auth.logout(); // Clears local + Supabase session
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

/// 4-tab navigation with swipeable PageView + animated Glowing FAB
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
  final _friendsKey = GlobalKey<FriendsScreenState>();
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
    _friendsKey.currentState?.loadData();
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
            FriendsScreen(key: _friendsKey),
            AnalyticsScreen(key: _analyticsKey),
            ProfileScreen(onLogout: widget.onLogout),
          ],
        ),
      ),

      // Expandable FAB
      floatingActionButton: GlowingFab(
        onAddTransaction: _openAddScreen,
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
                _navItem(1, Icons.group_rounded, 'Friends'),
                _navItem(2, Icons.bar_chart_rounded, 'Analytics'),
                _navItem(3, Icons.person_rounded, 'Profile'),
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
