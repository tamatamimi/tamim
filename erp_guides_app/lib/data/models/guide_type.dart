import 'package:flutter/material.dart';

/// The documentation categories the user asked to organize:
/// written guides, visual guides, procedures, data-flow diagrams, use cases.
enum GuideType { written, visual, procedure, dataFlow, useCase }

extension GuideTypeX on GuideType {
  String get key => name;

  static GuideType fromKey(String key) => GuideType.values.firstWhere(
        (e) => e.name == key,
        orElse: () => GuideType.written,
      );

  String label(bool isArabic) {
    switch (this) {
      case GuideType.written:
        return isArabic ? 'دليل مكتوب' : 'Written Guide';
      case GuideType.visual:
        return isArabic ? 'دليل مرئي' : 'Visual Guide';
      case GuideType.procedure:
        return isArabic ? 'دليل إجراءات' : 'Procedure';
      case GuideType.dataFlow:
        return isArabic ? 'مخطط تدفق بيانات' : 'Data Flow Diagram';
      case GuideType.useCase:
        return isArabic ? 'حالة استخدام' : 'Use Case';
    }
  }

  IconData get icon {
    switch (this) {
      case GuideType.written:
        return Icons.description_outlined;
      case GuideType.visual:
        return Icons.play_circle_outline;
      case GuideType.procedure:
        return Icons.checklist_rtl_outlined;
      case GuideType.dataFlow:
        return Icons.schema_outlined;
      case GuideType.useCase:
        return Icons.account_tree_outlined;
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case GuideType.written:
        return scheme.primary;
      case GuideType.visual:
        return const Color(0xFFB4690E);
      case GuideType.procedure:
        return const Color(0xFF1B7A4B);
      case GuideType.dataFlow:
        return const Color(0xFF6A4CB3);
      case GuideType.useCase:
        return const Color(0xFFB5344A);
    }
  }
}
