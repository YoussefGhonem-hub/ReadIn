import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/shared/widgets/inputs/country_picker.dart';
import 'package:readin/shared/widgets/inputs/password_field.dart';
import 'package:readin/shared/widgets/inputs/phone_field.dart';
import 'package:readin/shared/widgets/inputs/pin_input.dart';

import '../../../helpers/test_app.dart';

Widget host(Widget child, {Locale locale = AppLocales.ar}) =>
    testApp(Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)), variant: Variant(locale, Brightness.light));

void main() {
  group('PhoneField', () {
    testWidgets('formats as you type, strips the trunk prefix and converts Arabic-Indic digits', (tester) async {
      final controller = PhoneFieldController(iso2: 'EG');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PhoneField(controller: controller)));

      await tester.enterText(find.byType(TextField), '٠١٠٠١٢٣٤٥٦٧');
      expect(controller.text.text, '10 01234567');
      expect(controller.e164, '+201001234567');

      await tester.enterText(find.byType(TextField), '0100');
      expect(controller.e164, isNull); // incomplete
    });

    testWidgets('a pasted international number switches the country', (tester) async {
      final controller = PhoneFieldController(iso2: 'EG');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PhoneField(controller: controller)));

      await tester.enterText(find.byType(TextField), '+966 50 123 4567');
      await tester.pump();

      expect(controller.country.iso2, 'SA');
      expect(controller.e164, '+966501234567');
      expect(find.text('+966'), findsOneWidget);
    });

    testWidgets('is always LTR: the country code sits left of the number in Arabic', (tester) async {
      final controller = PhoneFieldController(e164: '+12025550110');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PhoneField(controller: controller)));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.ltr);
      expect(field.keyboardType, TextInputType.phone);
      expect(controller.country.iso2, 'US');
      expect(tester.getCenter(find.text('+1')).dx, lessThan(tester.getCenter(find.byType(TextField)).dx));
      expect(controller.text.text, '(202) 555-0110');
    });

    testWidgets('the picker searches by Arabic name, English name and dial code', (tester) async {
      final controller = PhoneFieldController(iso2: 'EG');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PhoneField(controller: controller)));
      await tester.enterText(find.byType(TextField), '0501234567');

      await tester.tap(find.text('+20'));
      await tester.pumpAndSettle();
      expect(find.byType(CountryPickerSheet), findsOneWidget);

      final search = find.descendant(of: find.byType(CountryPickerSheet), matching: find.byType(TextField));
      await tester.enterText(search, 'الكويت');
      await tester.pump();
      expect(find.widgetWithText(CountryTile, 'الكويت'), findsOneWidget);

      await tester.enterText(search, '+971');
      await tester.pump();
      expect(find.byType(CountryTile), findsOneWidget);
      await tester.tap(find.byType(CountryTile));
      await tester.pumpAndSettle();

      expect(controller.country.iso2, 'AE');
      expect(controller.e164, '+971501234567'); // the typed digits are kept and re-validated
    });
  });

  group('PinInput', () {
    testWidgets('one box per digit; converts digits, ignores letters, stops at the length', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? completed;
      await tester.pumpWidget(host(PinInput(controller: controller, label: 'PIN', length: 4, onCompleted: (pin) => completed = pin)));

      await tester.enterText(find.byType(TextField), '٤a٨۳1 9');

      expect(controller.text, '4831');
      expect(completed, '4831');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.number);
      expect(field.textDirection, TextDirection.ltr);
    });

    testWidgets('is masked until shown', (tester) async {
      final controller = TextEditingController(text: '4831');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PinInput(controller: controller, label: 'PIN'), locale: AppLocales.en));

      expect(find.text('•'), findsNWidgets(4));
      expect(find.text('4'), findsNothing);
      await tester.tap(find.byTooltip('Show PIN'));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('•'), findsNothing);
    });

    testWidgets('pasting a whole PIN fills every box', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PinInput(controller: controller, label: 'PIN', length: 6)));
      expect(PinInputFormatter(6).formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: 'PIN: ٤٨٣١٩٢')).text, '483192');
      await tester.enterText(find.byType(TextField), '483192');
      await tester.pump();
      expect(find.text('•'), findsNWidgets(6));
    });

    testWidgets('announces its label and progress', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: '48');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PinInput(controller: controller, label: 'Recovery PIN'), locale: AppLocales.en));
      expect(find.bySemanticsLabel(RegExp('Recovery PIN, 2 of 4 digits entered')), findsOneWidget);
      handle.dispose();
    });
  });

  group('PasswordField', () {
    testWidgets('shows and hides, stays LTR and asks password managers for a new password', (tester) async {
      final controller = TextEditingController(text: 'secret');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(PasswordField(controller: controller, isNew: true), locale: AppLocales.en));

      TextField field() => tester.widget<TextField>(find.byType(TextField));
      expect(field().obscureText, isTrue);
      expect(field().textDirection, TextDirection.ltr);
      expect(field().autofillHints, [AutofillHints.newPassword]);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });

    testWidgets('the rules checklist and strength meter follow what is typed', (tester) async {
      final password = TextEditingController();
      final confirm = TextEditingController();
      addTearDown(password.dispose);
      addTearDown(confirm.dispose);
      await tester.pumpWidget(host(NewPasswordFields(password: password, confirm: confirm), locale: AppLocales.en));

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'reading');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget); // a letter
      await tester.enterText(find.byType(TextField).first, 'reading4life');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
      expect(find.text('Good'), findsOneWidget);
    });
  });

  test('the dial code list covers the pinned countries', () {
    expect([for (final iso2 in Countries.pinned) Countries.byIso2(iso2)?.dialCode], everyElement(isNotNull));
  });
}
