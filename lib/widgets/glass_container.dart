import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.blur = 15.0,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeProvider>();
    
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? theme.glassBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? theme.glassBorderColor).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    Widget blurred = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: blurred,
        ),
      );
    }

    return blurred;
  }
}
