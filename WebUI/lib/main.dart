import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_performance_monitor_plus/flutter_performance_monitor_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;
import 'package:webui/pages/index_page.dart';
import 'package:webui/pages/login_page.dart';
import 'package:webui/pages/main_page.dart';
import 'package:webui/pages/not_found_page.dart';
import 'package:webui/widget/ThemeRevealTransition.dart';

void main() {
  if (kDebugMode || kProfileMode) {
    debugProfileBuildsEnabled = true;
    debugProfileLayoutsEnabled = true;
    debugProfilePaintsEnabled = true;
    runApp(
      PerformanceMonitorPlus(config: PerformanceMonitorConfig(), child: App()),
    );
  } else {
    runApp(const App());
  }
}

final pageRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const IndexPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/main', builder: (context, state) => const MainPage()),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isDark = false;
  Color _seedColor = Colors.blueAccent;
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

  void _rebuildThemes() {
    _lightTheme = ThemeData(
      fontFamily: 'HarmonyOS',
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    );
    _darkTheme = ThemeData(
      fontFamily: 'HarmonyOS',
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final mode = web.window.localStorage.getItem('theme_mode');
    if (mode == 'dark') _isDark = true;
    final savedColor = web.window.localStorage.getItem('seed_color');
    if (savedColor != null) {
      _seedColor = Color(int.parse(savedColor));
    }
    _rebuildThemes();
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
      web.window.localStorage.setItem('theme_mode', _isDark ? 'dark' : 'light');
    });
  }

  void _setSeedColor(Color color) {
    setState(() {
      _seedColor = color;
      web.window.localStorage.setItem('seed_color', color.value.toString());
      _rebuildThemes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '系统后台',
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      routerConfig: pageRouter,
      themeAnimationDuration: Duration.zero,
      themeAnimationStyle: AnimationStyle.noAnimation,
      builder: (context, child) => ThemeRevealTransition(
        isDark: _isDark,
        onToggle: _toggleTheme,
        seedColor: _seedColor,
        onColorChanged: _setSeedColor,
        child: child!,
      ),
    );
  }
}
