import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/app_update/domain/entities/app_version.dart';

void main() {
  group('isBelowMinimum', () {
    // (installed version, its build number, the policy's minimum, update required?)
    const cases = <(String, String, String?, bool)>[
      // major.minor.patch, compared as numbers
      ('0.1.0', '1', '1.2.0', true),
      ('1.1.9', '100', '1.2.0', true),
      ('1.2.0', '1', '1.2.0', false),
      ('1.2.1', '1', '1.2.0', false),
      ('2.0.0', '1', '1.99.99', false),
      ('1.9.0', '1', '1.10.0', true),
      ('1.10.0', '1', '1.9.0', false),
      // missing parts are 0
      ('1.2', '1', '1.2.0', false),
      ('1.2.0', '1', '1.2', false),
      ('1.1.0', '1', '1.2', true),
      ('1.0.0', '1', '1', false),
      ('0.9.9', '1', '1', true),
      ('2', '1', '1.5.0', false),
      // the build counts only when the releases are equal and the minimum names one
      ('1.2.0', '5', '1.2.0+6', true),
      ('1.2.0', '6', '1.2.0+6', false),
      ('1.2.0', '7', '1.2.0+6', false),
      ('1.2.1', '1', '1.2.0+50', false),
      ('1.1.9', '99', '1.2.0+1', true),
      ('1.2.0', '9', '1.2+10', true),
      ('1.2.0+4', '', '1.2.0+6', true), // no build number: the version's own
      // anything unparsable means not required
      ('1.2.0', '5', null, false),
      ('1.2.0', '5', '', false),
      ('1.2.0', '5', 'v1.3.0', false),
      ('1.2.0', '5', '1.3.0-beta', false),
      ('1.2.0', '5', '1.3.0.1', false),
      ('1.2.0', '5', '1.3.', false),
      ('1.2.0', '5', ' 1.3.0', false),
      ('1.2.0', '5', '1.3.0+', false),
      ('1.2.0', '5', '1..3', false),
      ('1.2.0', '5', '99999999999999999999.0.0', false),
      ('beta', '5', '1.3.0', false),
      ('', '5', '1.3.0', false),
      ('1.2.0', '', '1.2.0+6', false),
      ('1.2.0', 'abc', '1.2.0+6', false),
    ];

    for (final (version, build, minimum, mustUpdate) in cases) {
      test('$version+$build against ${minimum ?? 'no minimum'}: ${mustUpdate ? 'update' : 'fine'}', () {
        expect(isBelowMinimum(version: version, buildNumber: build, minimum: minimum), mustUpdate);
      });
    }
  });

  test('tryParse fills the missing parts with 0 and keeps the build', () {
    expect(AppVersion.tryParse('1'), const AppVersion(1));
    expect(AppVersion.tryParse('1.2'), const AppVersion(1, 2));
    expect(AppVersion.tryParse('1.2.3'), const AppVersion(1, 2, 3));
    expect(AppVersion.tryParse('1.2.3+45'), const AppVersion(1, 2, 3, 45));
    expect(AppVersion.tryParse('10.0+7'), const AppVersion(10, 0, 0, 7));
    expect(AppVersion.tryParse('1.2.3+45').toString(), '1.2.3+45');
    for (final text in [null, '', '1.2.3.4', 'a.b', '+1', '1.2.3+', '1.2.3+x', '1,2']) {
      expect(AppVersion.tryParse(text), isNull, reason: text);
    }
  });
}
