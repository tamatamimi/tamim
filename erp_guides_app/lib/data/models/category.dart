/// An ERP module/domain that groups guides (Finance, HR, Inventory…).
class Category {
  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.sortOrder,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final int sortOrder;

  String name(bool isArabic) => isArabic ? nameAr : nameEn;

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int,
        nameAr: map['name_ar'] as String,
        nameEn: map['name_en'] as String,
        icon: map['icon'] as String,
        sortOrder: map['sort_order'] as int,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'icon': icon,
        'sort_order': sortOrder,
      };
}
