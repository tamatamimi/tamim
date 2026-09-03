import 'package:flutter/material.dart';

/// Maps a stored icon key (string in the DB) to a Material icon.
/// Keeping icons as strings keeps the data layer UI-agnostic.
IconData appIcon(String key) {
  switch (key) {
    case 'finance':
      return Icons.account_balance_outlined;
    case 'procurement':
      return Icons.shopping_cart_outlined;
    case 'hr':
      return Icons.groups_outlined;
    case 'inventory':
      return Icons.inventory_2_outlined;
    case 'settings':
      return Icons.settings_outlined;
    case 'reports':
      return Icons.insert_chart_outlined;
    default:
      return Icons.folder_outlined;
  }
}
