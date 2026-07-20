import 'package:flutter/material.dart';

/// Defines the bottom navigation items for the app.
class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

const List<NavItem> bottomNavItems = [
  NavItem(
    label: 'Home',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/home',
  ),
  NavItem(
    label: 'Favorites',
    icon: Icons.favorite_border,
    selectedIcon: Icons.favorite,
    path: '/favorites',
  ),
  NavItem(
    label: 'History',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    path: '/history',
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
  ),
];
