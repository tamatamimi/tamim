/// Minimal, dependency-free bilingual string table (AR/EN).
///
/// Kept as a simple key → [ar, en] map so it is trivial to extend and audit.
/// For a larger catalogue, migrate to ARB + `flutter gen-l10n`.
class AppStrings {
  const AppStrings(this.isArabic);

  final bool isArabic;

  static const Map<String, List<String>> _values = {
    'appTitle': ['أدلة نظام ERP', 'ERP Guides'],
    'homeSubtitle': [
      'مستودع أدلة الاستخدام والتوثيق',
      'User guides & documentation hub',
    ],
    'categories': ['التصنيفات', 'Categories'],
    'recentGuides': ['أحدث الأدلة', 'Recent guides'],
    'search': ['بحث', 'Search'],
    'searchHint': ['ابحث في الأدلة والوسوم…', 'Search guides and tags…'],
    'noResults': ['لا توجد نتائج', 'No results found'],
    'startTyping': ['اكتب للبحث في الأدلة', 'Type to search the guides'],
    'guides': ['الأدلة', 'Guides'],
    'noGuides': ['لا توجد أدلة في هذا التصنيف', 'No guides in this category'],
    'type': ['النوع', 'Type'],
    'tags': ['الوسوم', 'Tags'],
    'lastUpdated': ['آخر تحديث', 'Last updated'],
    'relatedType': ['أدلة من نفس النوع', 'Guides of the same type'],
    'toggleLanguage': ['English', 'العربية'],
    'toggleTheme': ['المظهر', 'Theme'],
    'all': ['الكل', 'All'],
    'guideCount': ['دليل', 'guides'],
  };

  String t(String key) {
    final value = _values[key];
    if (value == null) return key;
    return isArabic ? value[0] : value[1];
  }
}
