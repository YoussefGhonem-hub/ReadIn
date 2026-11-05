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
      FailureCodes.articleNoContent: ('المقال فاضي، اكتب حاجة الأول.', 'The article is empty. Write something first.'),
      FailureCodes.articleInvalidTransition: (
        'مينفعش تعمل كده والمقال في حالته دي.',
        "You can't do that while the article is in this state.",
      ),
      FailureCodes.articleSlugTaken: ('الرابط ده مستخدم لمقال تاني.', 'That link is already used by another article.'),
      // F32: "التاجات" everywhere; the old code keeps its message.
      FailureCodes.articleTagsMaxFive: ('أقصى حاجة 5 تاجات للمقال.', 'An article can have at most 5 tags.'),
      FailureCodes.articleTooManyTags: ('أقصى حاجة 5 تاجات للمقال.', 'An article can have at most 5 tags.'),
      FailureCodes.tagNotFound: ('التاج ده مش موجود.', 'Tag not found.'),
      // The symbols in an LTR isolate, so they keep their order in Arabic (SPEC §14).
      FailureCodes.tagInvalid: (
        'التاج لازم يكون من 2 لـ 30 حرف: حروف وأرقام ومسافات و \u2066- _ . + #\u2069 بس.',
        'A tag has 2–30 characters: letters, digits, spaces and - _ . + # only.',
      ),
      FailureCodes.tagLimit: (
        'عملت تاجات جديدة كتير النهارده. اختار من التاجات الموجودة، أو جرّب تاني بعدين.',
        "You've created a lot of new tags today. Pick existing tags, or try again later.",
      ),
      FailureCodes.tagHidden: ('التاج ده مش متاح، اختار تاج تاني.', "This tag isn't available. Choose another one."),
      // F31: writer categories.
      FailureCodes.categoryNotFound: ('القسم ده مش موجود.', 'Category not found.'),
      FailureCodes.categoryNotOwner: ('القسم ده مش بتاعك.', "This category isn't yours."),
      FailureCodes.categoryLimit: ('وصلت لأقصى عدد أقسام (50).', 'You can have at most 50 categories.'),
      FailureCodes.categoryNameTaken: ('عندك قسم بنفس الاسم بالفعل.', 'You already have a category with this name.'),
      FailureCodes.categoryNameInvalid: (
        'اسم القسم لازم يكون من 1 لـ 40 حرف، وفيه حرف أو رقم على الأقل.',
        'A category name has 1–40 characters, with at least one letter or digit.',
      ),
      FailureCodes.articleLanguageInvalid: ('لغة المقال دي مش مدعومة.', "That article language isn't supported."),
      FailureCodes.articleContentLanguageMismatch: (
        'لغة المحتوى مش زي لغة المقال.',
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
    expect(localizeErrorCode(ar, FailureCodes.verificationNotVerified), 'المستخدم ده مش موثّق.');
    expect(localizeErrorCode(en, FailureCodes.verificationNotVerified), "This user isn't verified.");
    expect(localizeFailure(en, const Failure(FailureCodes.verificationNotVerified, statusCode: 409)), "This user isn't verified.");
  });

  // ... and the official @readin account keeps its badge.
  test('verification.system_account reads the same as on the web', () {
    expect(FailureCodes.verificationSystemAccount, 'verification.system_account');
    expect(localizeErrorCode(ar, FailureCodes.verificationSystemAccount), 'ده حساب ReadIn الرسمي، والتوثيق بتاعه ثابت.');
    expect(localizeErrorCode(en, FailureCodes.verificationSystemAccount), "This is ReadIn's official account; its badge stays.");
  });

  test('day counts are plurals', () {
    expect(en.streakSemantics(1), 'Reading streak: 1 day');
    expect(en.streakSemantics(4), 'Reading streak: 4 days');
    expect(ar.streakSemantics(1), 'الـ streak بتاعك: يوم واحد');
    expect(ar.streakSemantics(3), 'الـ streak بتاعك: 3 أيام');
    expect(ar.streakSemantics(12), 'الـ streak بتاعك: 12 يوم');
    expect(ar.readingMilestoneTitle(5), '5 أيام ورا بعض!');
    expect(ar.readingMilestoneTitle(50), '50 يوم ورا بعض!');
    expect(en.readingStreakNotReadTodaySemantics(1), startsWith('Reading streak: 1 day.'));
  });

  test('the article language toggle says مصري + EN, as on the web', () {
    expect(en.langToggleArEg, 'مصري + EN');
    expect(ar.langToggleArEg, 'مصري + EN');
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
