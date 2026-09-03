import 'package:flutter/material.dart';

import '../../data/models/guide_type.dart';

/// Small colored pill showing the guide's documentation type.
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type, required this.isArabic});

  final GuideType type;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = type.color(scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            type.label(isArabic),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
