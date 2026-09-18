import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';

class GradientScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final bool useSafeArea;

  const GradientScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Sfondo fisso "Lens Flare" Bimbomixer style
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.5),
                radius: 1.5,
                colors: [
                  theme.primaryColor.withValues(alpha: 0.15), // Accent glow from top left
                  theme.scaffoldBackgroundColor, // Deep dark base
                  Colors.black, // Darker edges
                ],
              ),
            ),
          ),
          // Layer 2: contenuto
          useSafeArea ? SafeArea(child: body ?? const SizedBox.shrink()) : (body ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}
