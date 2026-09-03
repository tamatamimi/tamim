import 'package:erp_guides_app/core/localization/app_strings.dart';
import 'package:erp_guides_app/data/models/guide.dart';
import 'package:erp_guides_app/data/models/guide_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStrings', () {
    test('returns Arabic and English variants', () {
      expect(const AppStrings(true).t('search'), 'بحث');
      expect(const AppStrings(false).t('search'), 'Search');
    });

    test('falls back to the key when missing', () {
      expect(const AppStrings(true).t('__missing__'), '__missing__');
    });
  });

  group('GuideType', () {
    test('round-trips through its key', () {
      for (final type in GuideType.values) {
        expect(GuideTypeX.fromKey(type.key), type);
      }
    });

    test('unknown key defaults to written', () {
      expect(GuideTypeX.fromKey('nope'), GuideType.written);
    });
  });

  group('Guide mapping', () {
    test('fromMap/toMap preserves fields and parses tags', () {
      final map = {
        'id': 7,
        'category_id': 2,
        'type': 'useCase',
        'title_ar': 'عنوان',
        'title_en': 'Title',
        'summary_ar': 'ملخص',
        'summary_en': 'Summary',
        'content_ar': 'محتوى',
        'content_en': 'Content',
        'tags': 'a, b ,c',
        'image_asset': null,
        'updated_at': '2026-09-01',
      };
      final guide = Guide.fromMap(map);
      expect(guide.type, GuideType.useCase);
      expect(guide.tags, ['a', 'b', 'c']);
      expect(guide.title(true), 'عنوان');
      expect(guide.title(false), 'Title');
      expect(guide.toMap()['tags'], 'a,b,c');
    });
  });
}
