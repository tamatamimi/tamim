import 'guide_type.dart';

/// A single documentation item. Content is stored as Markdown per language,
/// which cleanly renders written guides, procedures, and text descriptions of
/// diagrams / use cases. `imageAsset` optionally points to a diagram or
/// screenshot bundled under assets/images/.
class Guide {
  const Guide({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.contentAr,
    required this.contentEn,
    required this.tags,
    required this.imageAsset,
    required this.updatedAt,
  });

  final int id;
  final int categoryId;
  final GuideType type;
  final String titleAr;
  final String titleEn;
  final String summaryAr;
  final String summaryEn;
  final String contentAr;
  final String contentEn;
  final List<String> tags;
  final String? imageAsset;
  final String updatedAt; // ISO-8601 date

  String title(bool isArabic) => isArabic ? titleAr : titleEn;
  String summary(bool isArabic) => isArabic ? summaryAr : summaryEn;
  String content(bool isArabic) => isArabic ? contentAr : contentEn;

  factory Guide.fromJson(Map<String, dynamic> json) => Guide(
        id: json['id'] as int,
        categoryId: json['category_id'] as int,
        type: GuideTypeX.fromKey(json['type'] as String),
        titleAr: json['title_ar'] as String,
        titleEn: json['title_en'] as String,
        summaryAr: json['summary_ar'] as String,
        summaryEn: json['summary_en'] as String,
        contentAr: json['content_ar'] as String,
        contentEn: json['content_en'] as String,
        tags: (json['tags'] as List<dynamic>)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        imageAsset: json['image_asset'] as String?,
        updatedAt: json['updated_at'] as String,
      );

  factory Guide.fromMap(Map<String, Object?> map) => Guide(
        id: map['id'] as int,
        categoryId: map['category_id'] as int,
        type: GuideTypeX.fromKey(map['type'] as String),
        titleAr: map['title_ar'] as String,
        titleEn: map['title_en'] as String,
        summaryAr: map['summary_ar'] as String,
        summaryEn: map['summary_en'] as String,
        contentAr: map['content_ar'] as String,
        contentEn: map['content_en'] as String,
        tags: (map['tags'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        imageAsset: map['image_asset'] as String?,
        updatedAt: map['updated_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'type': type.key,
        'title_ar': titleAr,
        'title_en': titleEn,
        'summary_ar': summaryAr,
        'summary_en': summaryEn,
        'content_ar': contentAr,
        'content_en': contentEn,
        'tags': tags.join(','),
        'image_asset': imageAsset,
        'updated_at': updatedAt,
      };
}
