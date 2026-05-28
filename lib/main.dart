import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize AuthService with SharedPreferences before checking authentication
  final authService = AuthService();
  await authService.init();
  runApp(MotosTweeterApp(authService: authService));
}

class MotosTweeterApp extends StatelessWidget {
  final AuthService authService;

  const MotosTweeterApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    Route<dynamic> buildRoute(RouteSettings settings, Widget child) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => child,
      );
    }

    return MaterialApp(
      title: 'Moto Tweeter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A18),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF7A18), width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      onGenerateRoute: (settings) {
        final isLoggedIn = authService.isAuthenticated();

        switch (settings.name) {
          case '/home':
            if (!isLoggedIn) {
              return buildRoute(
                const RouteSettings(name: '/login'),
                const LoginScreen(),
              );
            }
            return buildRoute(settings, const HomeScreen());
          case '/login':
          case '/':
          default:
            if (isLoggedIn && settings.name != '/login') {
              return buildRoute(
                const RouteSettings(name: '/home'),
                const HomeScreen(),
              );
            }
            return buildRoute(
              const RouteSettings(name: '/login'),
              const LoginScreen(),
            );
        }
      },
      home: authService.isAuthenticated()
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
