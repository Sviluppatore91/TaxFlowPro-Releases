import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_flow_pro/providers/app_theme_provider.dart';
import 'package:tax_flow_pro/screens/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen should display essential widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppThemeProvider(),
        child: MaterialApp(
          home: const DashboardScreen(),
        ),
      ),
    );
    
    // We just want to check if the dashboard renders properly without crashing.
    // Use pump instead of pumpAndSettle because there might be infinite animations (like loading indicators)
    await tester.pump(const Duration(seconds: 1));
    
    // Check if the dashboard renders a scaffold
    expect(find.byType(Scaffold), findsWidgets);
  });
}
