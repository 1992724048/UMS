import 'package:flutter/material.dart';
import 'package:webui/pages/login_page.dart';
import 'package:webui/pages/main_page.dart';
import 'package:webui/pages/not_found_page.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const App());
}

final pageRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/login'),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/main', builder: (context, state) => const MainPage()),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '系统后台',
      theme: ThemeData(
        fontFamily: 'HarmonyOS',
        colorScheme: .fromSeed(seedColor: Colors.blueAccent, brightness: .dark),
      ),
      routerConfig: pageRouter,
    );
  }
}
