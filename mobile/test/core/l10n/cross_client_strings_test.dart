import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/failure_messages.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';

/// Error codes both clients translate the same way (wording from the API's ErrorMessages.cs), plurals, and the
/// greeting's hours.
void main() {
  late AppLocalizations ar;
  late AppLocalizations en;

  setUpAll(() async {
    ar = await AppLocalizations.delegate.load(AppLocales.ar);
    en = await AppLocalizations.delegate.load(AppLocales.en);
  });

  test('the editor codes the API added read the same as on the web', () {
    const expected = {
      FailureCodes.articleNoContent: ('المقال فارغ. اكتب شيئًا أولًا.', 'The article is empty. Write something first.'),
      FailureCodes.articleInvalidTransition: (
        'لا يمكن تنفيذ هذا الإجراء والمقال في حالته الحالية.',
        "You can't do that while the article is in this state.",
      ),
      FailureCodes.articleSlugTaken: ('هذا الرابط مستخدم لمقال آخر.', 'That link is already used by another article.'),
      // F32: "الوسوم" everywhere; the old code keeps its message.
      FailureCodes.articleTagsMaxFive: ('الحد الأقصى 5 وسوم للمقال الواحد.', 'An article can have at most 5 tags.'),
      FailureCodes.articleTooManyTags: ('الحد الأقصى 5 وسوم للمقال الواحد.', 'An article can have at most 5 tags.'),
      FailureCodes.tagNotFound: ('هذا الوسم غير موجود.', 'Tag not found.'),
      // The symbols in an LTR isolate, so they keep their order in Arabic (SPEC §14).
      FailureCodes.tagInvalid: (
        'يجب أن يتكون الوسم من 2 إلى 30 حرفًا: حروف وأرقام ومسافات و \u2066- _ . + #\u2069 فقط.',
        'A tag has 2–30 characters: letters, digits, spaces and - _ . + # only.',
      ),
      FailureCodes.tagLimit: (
        'أنشأت وسومًا جديدة كثيرة اليوم. اختر من الوسوم الموجودة، أو حاول مرة أخرى لاحقًا.',
        "You've created a lot of new tags today. Pick existing tags, or try again later.",
      ),
      FailureCodes.tagHidden: ('هذا الوسم غير متاح. اختر وسمًا آخر.', "This tag isn't available. Choose another one."),
      // F31: writer categories.
      FailureCodes.categoryNotFound: ('هذه الفئة غير موجودة.', 'Category not found.'),
      FailureCodes.categoryNotOwner: ('هذه الفئة ليست لك.', "This category isn't yours."),
      FailureCodes.categoryLimit: ('وصلت إلى الحد الأقصى لعدد الفئات (50).', 'You can have at most 50 categories.'),
      FailureCodes.categoryNameTaken: ('لديك فئة بالاسم نفسه بالفعل.', 'You already have a category with this name.'),
      FailureCodes.categoryNameInvalid: (
        'يجب أن يتكون اسم الفئة من 1 إلى 40 حرفًا، وأن يتضمن حرفًا أو رقمًا واحدًا على الأقل.',
        'A category name has 1–40 characters, with at least one letter or digit.',
      ),
      FailureCodes.articleLanguageInvalid: ('لغة المقال هذه غير مدعومة.', "That article language isn't supported."),
      FailureCodes.articleContentLanguageMismatch: (
        'لغة المحتوى لا تطابق لغة المقال.',
        "The content's language doesn't match the article's language.",
      ),
    };
    for (final MapEntry(key: code, value: (arabic, english)) in expected.entries) {
      expect(localizeErrorCode(ar, code), arabic, reason: code);
      expect(localizeErrorCode(en, code), english, reason: code);
    }
  });

  test('no other code the clients must translate falls back to the generic error', () {
    const codes = [
      'concurrency.conflict',
      'topic.not_in_field',
      'topic.not_found',
      'user.interests.unknown',
      'user.interests.min_three',
      'article.not_owner',
      'article.status_invalid',
      'request.too_large',
      'request.unsupported_media_type',
      'request.invalid',
      'route.not_found',
      'report.status_invalid',
    ];
    for (final code in codes) {
      expect(localizeErrorCode(en, code), isNot(en.errServer), reason: code);
      expect(localizeErrorCode(ar, code), isNot(ar.errServer), reason: code);
    }
    expect(localizeErrorCode(en, 'concurrency.conflict'), 'Someone else changed this. Refresh and try again.');
  });

  // The roles change (SPEC §10): removing a Verified badge the user doesn't have (`DELETE /admin/users/{id}/verification`).
  test('verification.not_verified reads the same as on the web', () {
    expect(FailureCodes.verificationNotVerified, 'verification.not_verified');
    expect(localizeErrorCode(ar, FailureCodes.verificationNotVerified), 'هذا المستخدم غير موثّق.');
    expect(localizeErrorCode(en, FailureCodes.verificationNotVerified), "This user isn't verified.");
    expect(localizeFailure(en, const Failure(FailureCodes.verificationNotVerified, statusCode: 409)), "This user isn't verified.");
  });

  // ... and the official @readin account keeps its badge.
  test('verification.system_account reads the same as on the web', () {
    expect(FailureCodes.verificationSystemAccount, 'verification.system_account');
    expect(localizeErrorCode(ar, FailureCodes.verificationSystemAccount), 'هذا هو حساب ReadIn الرسمي، وشارة توثيقه ثابتة.');
    expect(localizeErrorCode(en, FailureCodes.verificationSystemAccount), "This is ReadIn's official account; its badge stays.");
  });

  test('day counts are plurals', () {
    expect(en.streakSemantics(1), 'Reading streak: 1 day');
    expect(en.streakSemantics(4), 'Reading streak: 4 days');
    expect(ar.streakSemantics(1), 'سلسلة القراءة: يوم واحد');
    expect(ar.streakSemantics(3), 'سلسلة القراءة: 3 أيام');
    expect(ar.streakSemantics(12), 'سلسلة القراءة: 12 يومًا');
    expect(ar.readingMilestoneTitle(5), '5 أيام على التوالي!');
    expect(ar.readingMilestoneTitle(50), '50 يومًا على التوالي!');
    expect(en.readingStreakNotReadTodaySemantics(1), startsWith('Reading streak: 1 day.'));
  });

  test('the article language toggle says العربية + EN, as on the web', () {
    expect(en.langToggleArEg, 'العربية + EN');
    expect(ar.langToggleArEg, 'العربية + EN');
  });

  test('the greeting says good morning from 5 AM until noon, as on the web', () {
    DateTime at(int hour) => DateTime(2026, 11, 4, hour);
    expect(greetsMorning(at(4)), isFalse);
    expect(greetsMorning(at(5)), isTrue);
    expect(greetsMorning(at(11)), isTrue);
    expect(greetsMorning(at(12)), isFalse);
    expect(greetsMorning(at(16)), isFalse);
  });
}
