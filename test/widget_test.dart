// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_nexus/main.dart';
import 'package:anime_nexus/services/auth_service.dart';

void main() {
  testWidgets('Muestra la pantalla de login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final authService = AuthService();
    await authService.init();
    await tester.pumpWidget(AnimeNexusApp(authService: authService));
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
