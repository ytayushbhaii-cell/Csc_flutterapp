import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Thin navigation helper so screens don't need to import go_router directly.
class NavigationService {
  NavigationService._();

  static void goHome(BuildContext context) => context.go('/home');
  static void goFavorites(BuildContext context) => context.go('/favorites');
  static void goHistory(BuildContext context) => context.go('/history');
  static void goSettings(BuildContext context) => context.go('/settings');
  static void goSearch(BuildContext context) => context.push('/search');

  static void goTool(BuildContext context, String? route) {
    if (route != null && route.isNotEmpty) {
      context.push(route);
    }
  }
}
