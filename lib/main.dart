import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  runApp(AnimeNexusApp(authService: authService));
}

class AnimeNexusApp extends StatelessWidget {
  final AuthService authService;

  const AnimeNexusApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF8E44AD);

    return MaterialApp(
      title: 'AnimeNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF5FB),
        fontFamilyFallback: const ['Noto Color Emoji'],
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      initialRoute: authService.isAuthenticated() ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
