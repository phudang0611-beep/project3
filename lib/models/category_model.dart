import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.study:
        return 'Study';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.gear:
        return 'Gear';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.study:
        return Icons.menu_book;
      case ExpenseCategory.travel:
        return Icons.directions_bus;
      case ExpenseCategory.gear:
        return Icons.devices_other;
      case ExpenseCategory.entertainment:
        return Icons.movie;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B); // Coral red
      case ExpenseCategory.study:
        return const Color(0xFF4D96FF); // Sky blue
      case ExpenseCategory.travel:
        return const Color(0xFF6BCB77); // Mint green
      case ExpenseCategory.gear:
        return const Color(0xFFFFD93D); // Warm yellow
      case ExpenseCategory.entertainment:
        return const Color(0xFF9D4EDD); // Purple
    }
  }

  static ExpenseCategory fromString(String? name) {
    if (name == null) return ExpenseCategory.food;
    final lower = name.toLowerCase().trim();
    for (final cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == lower || cat.displayName.toLowerCase() == lower) {
        return cat;
      }
    }
    return ExpenseCategory.food;
  }
}
