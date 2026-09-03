import 'guide_type.dart';
import 'media.dart';

/// A single documentation item. Content is stored as Markdown per language,
/// which cleanly renders written guides, procedures, and text descriptions of
/// diagrams / use cases. An optional media attachment ([mediaType] +
/// [mediaSource]) carries an image, video, or PDF for visual guides.
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
    required this.mediaType,
    required this.mediaSource,
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
  final MediaType? mediaType;
  final String? mediaSource; // asset path, file path, or URL
  final String updatedAt; // ISO-8601 date

  String title(bool isArabic) => isArabic ? titleAr : titleEn;
  String summary(bool isArabic) => isArabic ? summaryAr : summaryEn;
  String content(bool isArabic) => isArabic ? contentAr : contentEn;

  bool get hasMedia => mediaType != null && (mediaSource?.isNotEmpty ?? false);

  static List<String> _splitTags(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

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
        mediaType: MediaTypeX.fromKey(json['media_type'] as String?),
        mediaSource: json['media_source'] as String?,
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
        tags: _splitTags(map['tags'] as String),
        mediaType: MediaTypeX.fromKey(map['media_type'] as String?),
        mediaSource: map['media_source'] as String?,
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
        'media_type': mediaType?.key,
        'media_source': mediaSource,
        'updated_at': updatedAt,
      };
}
