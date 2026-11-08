/**
 * The texts of the public legal pages (F37): the Terms of Use and the Community Guidelines, in Modern Standard Arabic
 * and English (SPEC §14.4). Plain data, rendered by legal.page.ts; a text change here is a new terms version only when
 * `Legal:TermsVersion` changes on the server too.
 */
export interface LegalSection {
  heading: string;
  paragraphs?: string[];
  items?: string[];
}

export interface LegalText {
  title: string;
  updated: string;
  intro: string;
  sections: LegalSection[];
}

export type LegalPageId = 'terms' | 'guidelines';

export const SUPPORT_EMAIL_PLACEHOLDER = '{email}';

export const LEGAL_TEXTS: Record<LegalPageId, Record<'ar' | 'en', LegalText>> = {
  terms: {
    ar: {
      title: 'شروط الاستخدام',
      updated: 'آخر تحديث: 8 نوفمبر 2026',
      intro:
        'تنظّم هذه الشروط استخدامك لتطبيقات ReadIn (أندرويد وiOS والويب). بإنشاء حساب أو باستخدام ReadIn فأنت توافق عليها وعلى قواعد المجتمع. لا تسامح مطلقًا مع المحتوى المسيء أو المستخدمين المسيئين.',
      sections: [
        {
          heading: '1. من يمكنه استخدام ReadIn',
          paragraphs: ['يجب أن يكون عمرك 13 عامًا أو أكثر لإنشاء حساب. ويمكن لأي شخص تصفّح المقالات وقراءتها دون حساب.'],
        },
        {
          heading: '2. حسابك',
          items: [
            'احتفظ بكلمة المرور ورمز الاسترداد (PIN) لنفسك؛ فأنت مسؤول عمّا يحدث من خلال حسابك.',
            'أدخل رقم هاتفك بشكل صحيح. لا نرسل رسائل SMS للتحقق من الرقم، لذلك قد تفقد حسابك إذا كان الرقم خطأ ونسيت كلمة المرور ورمز الاسترداد.',
            'إذا اشتبهت في أن أحدًا دخل حسابك، فغيّر كلمة المرور واستخدم «تسجيل الخروج من كل الأجهزة» وراسلنا.',
          ],
        },
        {
          heading: '3. محتواك',
          items: [
            'ما تكتبه ملكك. وعندما تنشر مقالًا أو تعليقًا، تمنح ReadIn إذنًا بحفظه وعرضه ومشاركته داخل التطبيق والموقع، بما في ذلك روابط المشاركة وبطاقات الاقتباس، لكي تعمل الخدمة.',
            'ينتهي هذا الإذن عندما تحذف المحتوى. وإذا حذفت حسابك، تبقى مقالاتك وتعليقاتك المنشورة باسم «مستخدم محذوف» دون اسمك؛ فاحذفها أولًا إذا أردت إزالتها.',
            'انشر فقط ما تملك حق نشره، والتزم بقواعد المجتمع.',
          ],
        },
        {
          heading: '4. لا تسامح مع المحتوى المسيء',
          items: [
            'يُمنع خطاب الكراهية والتحرش والتهديد والمحتوى الجنسي والعنف والرسائل المزعجة والاحتيال وانتحال الشخصية ونشر بيانات الآخرين الخاصة وانتهاك حقوق النشر والمعلومات الطبية أو المالية المضللة. التفاصيل في قواعد المجتمع.',
            'يفحص ReadIn النصوص التي تُنشر علنًا (العناوين والمقالات والتعليقات والأسماء والسير الذاتية وغيرها)، فيرفض النص المخالف بوضوح، ويرسل النص المشتبه به إلى فريق الإشراف للمراجعة.',
            'يحق لنا إزالة أي محتوى مخالف وإيقاف أي حساب يخالف هذه الشروط، دون إشعار مسبق.',
          ],
        },
        {
          heading: '5. الإبلاغ والحظر',
          items: [
            'يمكنك الإبلاغ عن أي مقال أو تعليق أو رد أو حساب أو إعادة نشر من قائمة «⋯»، ويختفي المحتوى الذي أبلغت عنه من أمامك فورًا.',
            'يمكنك حظر أي مستخدم، فلا يرى أحدكما مقالات الآخر أو تعليقاته، ولا يمكن لأي منكما متابعة الآخر أو الإشارة إليه أو التعليق على محتواه. ولا يتلقى المحظور إشعارًا بذلك.',
            'يراجع فريق الإشراف البلاغات خلال 24 ساعة، فيزيل المحتوى المخالف، ويوجّه التحذيرات، ويوقف الحسابات مؤقتًا أو نهائيًا.',
          ],
        },
        {
          heading: '6. المحتوى للمعرفة فقط',
          paragraphs: [
            'يكتب المقالات كُتّاب من المجتمع، ولا نراجعها قبل نشرها، لذلك قد تحتوي على أخطاء. والمحتوى للمعرفة العامة، وليس بديلًا عن استشارة مختص (طبي أو قانوني أو مالي أو غيره).',
          ],
        },
        {
          heading: '7. الخدمة كما هي',
          paragraphs: [
            'نقدّم ReadIn «كما هو». وقد نغيّر الخصائص أو نوقفها، وقد تتوقف الخدمة أحيانًا. وفي الحدود التي يسمح بها القانون، لا نتحمل مسؤولية الخسائر الناتجة عن استخدام التطبيق أو الاعتماد على محتواه.',
          ],
        },
        {
          heading: '8. إنهاء الاستخدام',
          paragraphs: ['يمكنك حذف حسابك في أي وقت من الإعدادات. ويمكننا إيقاف حسابك إذا خالفت هذه الشروط أو قواعد المجتمع.'],
        },
        {
          heading: '9. التغييرات على هذه الشروط',
          paragraphs: [
            'عندما نغيّر هذه الشروط نحدّث هذه الصفحة وتاريخ «آخر تحديث». وعند تغيير مهم، نطلب منك الموافقة على النسخة الجديدة داخل التطبيق قبل متابعة استخدامه.',
          ],
        },
        {
          heading: '10. تواصل معنا',
          paragraphs: ['فريق ReadIn: {email}. اقرأ أيضًا قواعد المجتمع وسياسة الخصوصية.'],
        },
      ],
    },
    en: {
      title: 'Terms of Use',
      updated: 'Last updated: November 8, 2026',
      intro:
        'These terms cover your use of the ReadIn apps (Android, iOS and web). By creating an account or using ReadIn, you agree to them and to the Community Guidelines. There is zero tolerance for objectionable content or abusive users.',
      sections: [
        {
          heading: '1. Who can use ReadIn',
          paragraphs: ['You must be 13 or older to create an account. Anyone can browse and read articles without one.'],
        },
        {
          heading: '2. Your account',
          items: [
            "Keep your password and recovery PIN to yourself. You're responsible for what happens through your account.",
            "Enter your phone number correctly. We don't send SMS to check it, so if the number is wrong and you forget both your password and your PIN, you may lose the account.",
            'If you think someone else got into your account, change your password, use "Sign out of all devices", and email us.',
          ],
        },
        {
          heading: '3. Your content',
          items: [
            'What you write is yours. When you publish an article or a comment, you give ReadIn permission to store, display and share it in the app and on the website, including share links and quote cards, so the service can work.',
            'This permission ends when you delete the content. If you delete your account, your published articles and comments stay up under "Deleted user", without your name; delete them first if you want them gone.',
            'Only post what you have the right to post, and follow the Community Guidelines.',
          ],
        },
        {
          heading: '4. Zero tolerance for objectionable content',
          items: [
            "Hate speech, harassment and threats, sexual content, violence, spam and scams, impersonation, sharing other people's private data, copyright infringement, and medical or financial misinformation are not allowed. The Community Guidelines have the details.",
            'ReadIn checks the text people publish (titles, articles, comments, names, bios and more): text that clearly breaks the rules is refused, and text that may break them goes to our moderators.',
            'We may remove content that breaks these terms and suspend accounts that break them, without notice.',
          ],
        },
        {
          heading: '5. Reporting and blocking',
          items: [
            "You can report any article, comment, reply, account or repost from its \"⋯\" menu, and what you reported is hidden for you at once.",
            "You can block anyone: you won't see each other's articles or comments, and neither of you can follow, mention or comment on the other's content. They aren't notified.",
            'Our moderators review reports within 24 hours: they remove content that breaks the rules, give warnings, and suspend accounts for a while or for good.',
          ],
        },
        {
          heading: '6. Content is for information',
          paragraphs: [
            "Articles are written by community writers. We don't review them before they're published, so they can contain mistakes. Content is general information, not a substitute for advice from a qualified professional (medical, legal, financial or otherwise).",
          ],
        },
        {
          heading: '7. The service as it is',
          paragraphs: [
            "We provide ReadIn \"as is\". We may change or remove features, and the service may sometimes be unavailable. As far as the law allows, we aren't responsible for losses caused by using the app or relying on its content.",
          ],
        },
        {
          heading: '8. Ending your use',
          paragraphs: ['You can delete your account at any time from Settings. We can suspend your account if you break these terms or the Community Guidelines.'],
        },
        {
          heading: '9. Changes to these terms',
          paragraphs: [
            'When we change these terms, we update this page and the "last updated" date. For a significant change, we ask you to accept the new version in the app before you go on using it.',
          ],
        },
        {
          heading: '10. Contact',
          paragraphs: ['The ReadIn team: {email}. See also the Community Guidelines and the Privacy Policy.'],
        },
      ],
    },
  },
  guidelines: {
    ar: {
      title: 'قواعد المجتمع',
      updated: 'آخر تحديث: 8 نوفمبر 2026',
      intro:
        'ReadIn مكان للتعلّم والقراءة والكتابة باحترام. تنطبق هذه القواعد على كل ما يُنشر: المقالات والتعليقات والردود وإعادات النشر والأسماء والسير الذاتية والصور. لا تسامح مطلقًا مع المحتوى المسيء أو المستخدمين المسيئين.',
      sections: [
        {
          heading: 'ما لا يُسمح به',
          items: [
            'خطاب الكراهية: مهاجمة الناس أو التحقير منهم بسبب الدين أو العرق أو الأصل أو الجنس أو الإعاقة أو غيرها.',
            'التحرش والتهديد: الإساءة إلى شخص أو ملاحقته أو تهديده أو التحريض عليه.',
            'المحتوى الجنسي: أي محتوى جنسي صريح، وأي محتوى جنسي يتعلق بالقُصّر مطلقًا.',
            'العنف: الدعوة إلى العنف أو تمجيده أو نشر مشاهد عنيفة صادمة.',
            'الرسائل المزعجة والاحتيال: الإعلانات المتكررة، والروابط المضللة، وطلب المال أو البيانات بالخداع.',
            'انتحال الشخصية: التظاهر بأنك شخص آخر أو جهة أخرى.',
            'نشر البيانات الخاصة: نشر أرقام الهواتف أو العناوين أو الصور أو أي بيانات خاصة بالآخرين دون إذنهم.',
            'انتهاك حقوق النشر: نسخ محتوى غيرك ونشره دون إذن.',
            'المعلومات الطبية أو المالية المضللة: نشر معلومات خاطئة قد تضر بصحة الناس أو أموالهم.',
          ],
        },
        {
          heading: 'كيف نطبّق هذه القواعد',
          items: [
            'يفحص فلتر المحتوى النصوص قبل نشرها، فيرفض النص المخالف بوضوح، ويرسل المشتبه به إلى فريق الإشراف.',
            'يمكن لأي عضو الإبلاغ عن أي محتوى أو حساب من قائمة «⋯»، ويختفي ما أبلغ عنه من أمامه فورًا.',
            'يراجع فريق الإشراف كل بلاغ خلال 24 ساعة.',
          ],
        },
        {
          heading: 'العواقب',
          items: [
            'إزالة المحتوى المخالف.',
            'تحذير يصل إلى صاحب الحساب.',
            'إيقاف الحساب مؤقتًا.',
            'الحظر النهائي من ReadIn عند المخالفات الجسيمة أو المتكررة.',
          ],
        },
        {
          heading: 'حماية نفسك',
          items: [
            'يمكنك كتم أي كاتب لتتوقف عن رؤية مقالاته، أو حظره لقطع أي تواصل بينكما في الاتجاهين.',
            'إذا رأيت ما يعرّض أحدًا لخطر حقيقي، فأبلغ عنه فورًا وراسلنا على {email}.',
          ],
        },
      ],
    },
    en: {
      title: 'Community Guidelines',
      updated: 'Last updated: November 8, 2026',
      intro:
        'ReadIn is a place to learn, read and write with respect. These guidelines apply to everything people publish: articles, comments, replies, reposts, names, bios and images. There is zero tolerance for objectionable content or abusive users.',
      sections: [
        {
          heading: "What isn't allowed",
          items: [
            'Hate speech: attacking or demeaning people for their religion, race, origin, gender, disability or any other trait.',
            'Harassment and threats: abusing, stalking, threatening or inciting against anyone.',
            'Sexual content: any explicit sexual content, and never any sexual content involving minors.',
            'Violence: calling for or glorifying violence, or posting shocking violent material.',
            'Spam and scams: repeated ads, misleading links, and tricking people out of money or data.',
            'Impersonation: pretending to be another person or organization.',
            "Private data: posting other people's phone numbers, addresses, photos or other private details without their permission.",
            "Copyright infringement: copying and posting other people's work without permission.",
            "Medical or financial misinformation: false information that can harm people's health or money.",
          ],
        },
        {
          heading: 'How we enforce them',
          items: [
            'A content filter checks text before it is published: text that clearly breaks the rules is refused, and text that may break them goes to our moderators.',
            'Any member can report content or an account from its "⋯" menu, and what they reported is hidden for them at once.',
            'Our moderators review every report within 24 hours.',
          ],
        },
        {
          heading: 'Consequences',
          items: ['The content is removed.', 'The account owner gets a warning.', 'The account is suspended for a while.', 'A permanent ban from ReadIn for serious or repeated violations.'],
        },
        {
          heading: 'Protecting yourself',
          items: [
            "Mute a writer to stop seeing their articles, or block them to cut all contact between you, both ways.",
            'If you see something that puts someone in real danger, report it at once and email us at {email}.',
          ],
        },
      ],
    },
  },
};
