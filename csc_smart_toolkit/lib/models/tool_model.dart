import 'package:flutter/material.dart';

/// Mirrors the Expo app's Tool interface from AppContext.tsx
class ToolModel {
  const ToolModel({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.category,
    required this.categoryHi,
    required this.icon,
    required this.color,
    required this.description,
    this.route,
  });

  final String id;
  final String name;
  final String nameHi;
  final String category;
  final String categoryHi;
  final IconData icon;
  final Color color;
  final String description;
  final String? route;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameHi': nameHi,
        'category': category,
        'categoryHi': categoryHi,
        'color': color.toARGB32(),
        'description': description,
        'route': route,
      };

  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        nameHi.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}
