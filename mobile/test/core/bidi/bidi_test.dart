import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/bidi/bidi.dart';

import '../../helpers/test_app.dart';

void main() {
  final fixtures = (readSharedJson('bidi/fixtures.json')['fixtures'] as List).cast<Map<String, dynamic>>();

  group('Bidi.detect — shared/bidi/fixtures.json', () {
    for (final f in fixtures) {
      test('${f['id']} → ${f['expectedDir']}', () {
        final expected = f['expectedDir'] == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
        expect(Bidi.detect(f['text'] as String), expected);
      });
    }

    test('text without strong characters has no direction', () {
      expect(Bidi.detect('123 — 4.5 ☕'), isNull);
    });

    test('explicit dir overrides auto detection', () {
      expect(Bidi.resolve('ltr', 'مرحبا', fallback: TextDirection.rtl), TextDirection.ltr);
      expect(Bidi.resolve('auto', '...', fallback: TextDirection.rtl), TextDirection.rtl);
    });
  });

  group('Bidi.normalizeArabic — shared fixtures', () {
    for (final f in fixtures.where((f) => f['normalized'] != null)) {
      test('${f['id']}', () {
        expect(Bidi.normalizeArabic(f['text'] as String), f['normalized']);
      });
    }
  });

  group('Bidi.isolateOppositeRuns', () {
    String iso(String s) => '${Bidi.fsi}$s${Bidi.pdi}';
    String rtl(String s) => Bidi.isolateOppositeRuns(s, TextDirection.rtl);

    test('keeps end punctuation outside the English run', () {
      expect(rtl('أنا بستخدم ASP.NET Core.'), 'أنا بستخدم ${iso('ASP.NET Core')}.');
    });

    test('isolates balanced parentheses with the run', () {
      expect(rtl('الـ lifetime (Scoped) مهم.'), 'الـ ${iso('lifetime (Scoped)')} مهم.');
    });

    test('pulls attached prefixes (.NET, @handle) into the run', () {
      expect(rtl('لـ .NET 10 و Angular 21.'), 'لـ ${iso('.NET 10')} و ${iso('Angular 21')}.');
      expect(rtl('شكراً @youssef_dev على الشرح!'), 'شكراً ${iso('@youssef_dev')} على الشرح!');
    });

    test('keeps generics and call parens with code-like runs', () {
      expect(rtl('استخدم services.AddScoped<IFoo, Foo>() هنا.'), 'استخدم ${iso('services.AddScoped<IFoo, Foo>()')} هنا.');
    });

    test('keeps C# and URLs whole', () {
      expect(rtl('بتعلم C# دلوقتي'), 'بتعلم ${iso('C#')} دلوقتي');
      expect(rtl('شوف https://learn.microsoft.com/dotnet/ للتفاصيل.'),
          'شوف ${iso('https://learn.microsoft.com/dotnet/')} للتفاصيل.');
    });

    test('isolates Arabic inside English without swallowing brackets', () {
      expect(Bidi.isolateOppositeRuns('Use DI (الحقن) everywhere.', TextDirection.ltr),
          'Use DI (${iso('الحقن')}) everywhere.');
    });

    test('leaves single-direction text untouched', () {
      expect(rtl('مقال كل يوم يفرق معاك'), 'مقال كل يوم يفرق معاك');
      expect(Bidi.isolateOppositeRuns('Read daily. Grow daily.', TextDirection.ltr), 'Read daily. Grow daily.');
    });
  });
}
