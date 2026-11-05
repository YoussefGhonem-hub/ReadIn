import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/features/tags/domain/services/tag_names.dart';

/// The tag name rules (docs/api/contract-v1.md, "Tags (F32)" → "Tag names"), as the editor applies them.
void main() {
  group('clean (rule 1)', () {
    test('trims, drops leading #s and collapses whitespace', () {
      expect(TagNames.clean('  #AI  '), 'AI');
      expect(TagNames.clean(' ##C# '), 'C#');
      expect(TagNames.clean('## # C#'), '# C#', reason: 'one pass, as the API does: the #s, then a trim');
      expect(TagNames.clean('ASP.NET \t  Core\n'), 'ASP.NET Core');
      expect(TagNames.clean('  '), '');
    });

    test('removes invisible format characters and writes Arabic-Indic digits as 0-9', () {
      final lrm = String.fromCharCode(0x200E);
      final zwj = String.fromCharCode(0x200D);
      expect(TagNames.clean('${Bidi.fsi}#C++${Bidi.pdi}$lrm'), 'C++');
      expect(TagNames.clean('No${zwj}de'), 'Node');
      expect(TagNames.clean('ويب ٣'), 'ويب 3');
      expect(TagNames.clean('Web ۲'), 'Web 2');
    });
  });

  group('validate (rule 2, new tags)', () {
    test('2 to 30 characters', () {
      expect(TagNames.validate('a'), TagNameError.tooShort);
      expect(TagNames.validate('ai'), isNull);
      expect(TagNames.validate('x' * 30), isNull);
      expect(TagNames.validate('x' * 31), TagNameError.tooLong);
    });

    test('letters, marks, digits, spaces and - _ . + #, with a letter or digit', () {
      for (final ok in ['C#', '.NET', 'C++', 'node_js', 'web-3', 'الذكاء الاصطناعي', 'تَعلُّم', 'Vue 3']) {
        expect(TagNames.validate(ok), isNull, reason: ok);
      }
      for (final bad in ['CI/CD', 'Span<T>', 'a&b', '🔥 hot']) {
        expect(TagNames.validate(bad), TagNameError.invalidCharacters, reason: bad);
      }
      // Allowed characters, but nothing to read: its own message (like the web).
      for (final bad in ['--', '#+', '. .']) {
        expect(TagNames.validate(bad), TagNameError.noLetter, reason: bad);
      }
    });

    test('tatweel is no letter (it only stretches the letters around it), like the API', () {
      for (final bad in ['ــ', 'ـــ', 'ـَـ', 'ـ-ـ']) {
        expect(TagNames.validate(bad), TagNameError.noLetter, reason: bad);
      }
      expect(TagNames.validate('عـلم'), isNull);
    });
  });

  group('normalize and same (rule 3)', () {
    test('case and a leading # do not matter', () {
      expect(TagNames.same('AI', 'ai'), isTrue);
      expect(TagNames.same('#AI', 'ai'), isTrue);
      expect(TagNames.same('ASP.NET  Core', 'asp.net core'), isTrue);
      expect(TagNames.same('C#', 'C++'), isFalse);
    });

    test('Arabic normalization: diacritics, tatweel, alef forms, yeh and teh marbuta', () {
      expect(TagNames.same('الذّكاء الإصطناعي', 'الذكاء الاصطناعي'), isTrue);
      expect(TagNames.same('برمجـــة', 'برمجه'), isTrue);
      expect(TagNames.same('مستوى', 'مستوي'), isTrue);
      expect(TagNames.same('آلة', 'الة'), isTrue);
      expect(TagNames.normalize('القرآن${String.fromCharCode(0x06DA)}'), 'القران');
    });

    test('containsTag finds a tag under another spelling', () {
      expect(TagNames.containsTag(['dotnet', 'AI'], '#ai'), isTrue);
      expect(TagNames.containsTag(['dotnet'], 'dotnet core'), isFalse);
    });
  });
}
