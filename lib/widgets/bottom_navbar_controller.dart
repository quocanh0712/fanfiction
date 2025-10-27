import 'package:flutter/material.dart';

/// Controller to manage bottom navbar visibility
class BottomNavBarController extends InheritedWidget {
  final bool isVisible;
  final VoidCallback? showNavBar;
  final VoidCallback? hideNavBar;

  const BottomNavBarController({
    super.key,
    required this.isVisible,
    this.showNavBar,
    this.hideNavBar,
    required super.child,
  });

  static BottomNavBarController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BottomNavBarController>();
  }

  static BottomNavBarController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'BottomNavBarController not found in context');
    return controller!;
  }

  @override
  bool updateShouldNotify(BottomNavBarController oldWidget) {
    return isVisible != oldWidget.isVisible;
  }
}

/// Helper class to show/hide bottom navbar
class BottomNavBarHelper {
  /// Hide bottom navbar
  static void hide(BuildContext context) {
    BottomNavBarController.of(context).hideNavBar?.call();
  }

  /// Show bottom navbar
  static void show(BuildContext context) {
    BottomNavBarController.of(context).showNavBar?.call();
  }

  /// Check if bottom navbar is visible
  static bool isVisible(BuildContext context) {
    return BottomNavBarController.of(context).isVisible;
  }
}
