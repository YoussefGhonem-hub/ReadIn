import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/categories/domain/entities/writer_category.dart';
import 'package:readin/features/categories/domain/services/category_names.dart';

/// The category name rules the app checks before sending (docs/api/contract-v1.md, "Writer categories (F31)" →
/// "Names"), the same as the API's.
void main() {
  group('clean', () {
    test('trims, collapses whitespace and drops invisible format and control characters', () {
      expect(CategoryNames.clean('  نصايح   Backend  '), 'نصايح Backend');
      expect(CategoryNames.clean('EF\u200F Core\u2066'), 'EF Core');
      expect(CategoryNames.clean('Career\t&\nهندسة'), 'Career & هندسة');
      expect(CategoryNames.clean('a\u0007b'), 'ab');
    });

    test('keeps a leading #, unlike a tag, and writes Arabic-Indic digits as 0–9', () {
      expect(CategoryNames.clean('#C# tips'), '#C# tips');
      expect(CategoryNames.clean('نصايح ٢٠٢٦'), 'نصايح 2026');
      expect(CategoryNames.clean('دروس ۳'), 'دروس 3');
    });
  });

  group('validate', () {
    test('1–40 characters with a letter or digit', () {
      expect(CategoryNames.validate('A'), isNull);
      expect(CategoryNames.validate('7'), isNull);
      expect(CategoryNames.validate('🚀 Rust'), isNull);
      expect(CategoryNames.validate('x' * 40), isNull);
      expect(CategoryNames.validate(''), CategoryNameError.empty);
      expect(CategoryNames.validate('x' * 41), CategoryNameError.tooLong);
    });

    test('punctuation, emoji or tatweel alone has no letter', () {
      expect(CategoryNames.validate('!!!'), CategoryNameError.noLetter);
      expect(CategoryNames.validate('🚀🚀'), CategoryNameError.noLetter);
      expect(CategoryNames.validate('ــــ'), CategoryNameError.noLetter);
    });
  });

  group('same name', () {
    test('ignores case and the Arabic spelling (§22), keeps punctuation', () {
      expect(CategoryNames.same('AI', 'ai'), isTrue);
      expect(CategoryNames.same('أدوات', 'ادوات'), isTrue);
      expect(CategoryNames.same('مكتبة', 'مكتبه'), isTrue);
      expect(CategoryNames.same('نصايح  Backend', 'نصايح backend'), isTrue);
      expect(CategoryNames.same('C#', 'C'), isFalse);
    });

    test('isTaken skips the category being renamed', () {
      const categories = [
        WriterCategory(id: 'c-1', slug: 'ai', name: 'AI'),
        WriterCategory(id: 'c-2', slug: 'ef-core', name: 'EF Core'),
      ];
      expect(CategoryNames.isTaken(categories, 'ai'), isTrue);
      expect(CategoryNames.isTaken(categories, 'ai', exceptId: 'c-1'), isFalse, reason: 'another spelling of its own name');
      expect(CategoryNames.isTaken(categories, 'ef core', exceptId: 'c-1'), isTrue);
      expect(CategoryNames.isTaken(categories, 'Flutter'), isFalse);
    });
  });
}
