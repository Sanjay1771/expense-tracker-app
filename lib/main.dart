// Main entry point — dark theme, auth flow, swipeable 4-tab nav with glowing FAB
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
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
import 'services/notification_service.dart';
import 'services/background_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// Top-level FCM background handler (MUST be top-level, runs in separate isolate)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔥 FCM background message: ${message.messageId}');
  // Firebase automatically shows the notification for background messages
  // This handler is for any additional data processing you need
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Register FCM background handler (before any other Firebase calls)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notifications (local + FCM) early so they're ready before any screen loads
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
    _initAuthStateListener();
  }

  void _initAuthStateListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        if (mounted) setState(() { _loggedIn = false; _loading = false; });
        return;
      }

      try {
        final ok = await _auth.tryAutoLogin();
        if (!ok) {
          await _auth.syncSupabaseUser(session.user);
        }
        if (mounted) setState(() { _loggedIn = true; _loading = false; });
      } catch (e) {
        if (mounted) setState(() { _loggedIn = false; _loading = false; });
      }
    });
  }

  void _onLogin() => setState(() => _loggedIn = true);
  
  void _onLogout() async {
    await _auth.logout();
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
                boxShadow: [BoxShadow(color: AppTheme.seedColor.withValues(alpha: 0.4), blurRadius: 16)],
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
    _homeKey.currentState?.loadTransactions();
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

  void _openAddScreen() async {
    final result = await Navigator.push(
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

    if (result == true) {
      _onTxnAdded();
    }
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
      floatingActionButton: _idx == 0
          ? GlowingFab(
              onAddTransaction: _openAddScreen,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // MD3 NavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
