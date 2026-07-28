import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/ai_chat_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/orders_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await Hive.openBox<String>('history');
  await Supabase.initialize(
    url: 'https://nomzdoqhsjuadrjwgbup.supabase.co',
    publishableKey: 'sb_publishable_m_rVULWTJut_1MkApY9Rjg_594Bep1e',
  );
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;
  runApp(MyApp(isDark: isDark));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.isDark});

  final bool isDark;

  @override
  State<MyApp> createState() => _AppShellState();
}

class _AppShellState extends State<MyApp> {
  late final ThemeController _themeController;
  Locale _locale = const Locale('en');

  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => WelcomeScreen(
          themeController: _themeController,
          currentLocale: _locale,
          onLocaleChanged: _setLocale,
        ),
      ),
      GoRoute(path: '/shop', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/search', redirect: (context, state) => '/shop'),
      GoRoute(path: '/ai-chat', builder: (context, state) => const AIChatScreen()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
    ],
  );

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(initialDark: widget.isDark);
    _themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> toggleTheme() async {
    await _themeController.toggleTheme();
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme(fontFamily: AppConstants.defaultFontFamily),
      darkTheme: AppTheme.darkTheme(fontFamily: AppConstants.defaultFontFamily),
      themeMode: _themeController.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}
