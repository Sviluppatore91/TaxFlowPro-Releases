import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_flow_pro/providers/app_theme_provider.dart';
import 'package:tax_flow_pro/main.dart'; // or import login screen

void main() {
  testWidgets('LoginScreen should display username and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppThemeProvider(),
        child: const ContabileApp(),
      ),
    );
    
    // ContabileApp by default boots to SplashScreen or LoginScreen.
    // If it boots to SplashScreen, wait for it to finish.
    await tester.pumpAndSettle();

    // Now we should be at LoginScreen.
    // Look for text fields and button.
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Accedi'), findsWidgets);
  });
}
