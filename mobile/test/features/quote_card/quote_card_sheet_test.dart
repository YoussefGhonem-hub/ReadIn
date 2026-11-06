import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/config/app_links.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/highlights/domain/usecases/highlight_usecases.dart';
import 'package:readin/features/highlights/presentation/cubit/article_highlights_cubit.dart';
import 'package:readin/features/highlights/presentation/widgets/reader_highlights.dart';
import 'package:readin/features/quote_card/domain/entities/quote_card.dart';
import 'package:readin/features/quote_card/presentation/cubit/quote_card_cubit.dart';
import 'package:readin/features/quote_card/presentation/widgets/quote_card_sheet.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/highlight_fakes.dart';
import '../../helpers/quote_card_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class _MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

const _member = Me(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  permissions: ['highlights.create'],
);

/// A member whose role can't highlight: Share quote needs only `articles.read`.
const _reader = Me(id: 'u-2', displayName: 'Mona', username: 'mona', onboardingCompleted: true);

const _range = HighlightRange(blockId: 'p1', startOffset: 42, endOffset: 52, text: 'Dependency');

/// The quote card (SPEC F24) on mobile: **شارك اقتباس** / **Share quote** in the reader's selection toolbar (guests
/// too, allowed blocks only, not on a hidden article, 400 characters at most), and the sheet: the API's card for each
/// theme and format, Share, Save and Copy link, and errors with "Try again". Not while highlights are hidden.
void main() {
  final fixtures = readSharedJson('rdoc/highlight-fixtures.json');
  final document = RDocDocument.fromJson((fixtures['documents'] as Map<String, dynamic>)['ar'] as Map<String, dynamic>);
  final article = ArticleDetails(card: sampleCard(1), availableLanguages: const ['ar-EG'], content: document);

  late FakeQuoteCardRepository repository;
  late RecordingShare share;
  late RecordingSaver saver;

  setUp(() {
    repository = FakeQuoteCardRepository();
    share = RecordingShare();
    saver = RecordingSaver();
    getIt.registerFactory<QuoteCardCubit>(() => quoteCardCubit(repository, share: share, saver: saver));
  });

  tearDown(getIt.reset);

  group('the selection toolbar', () {
    Future<void> pumpReader(
      WidgetTester tester, {
      Me? me = _member,
      ArticleDetails? details,
      Variant variant = const Variant(AppLocales.ar, Brightness.light),
      VoidCallback? onTextChanged,
      AppSettings settings = const AppSettings(),
    }) async {
      final settingsCubit = _MockSettingsCubit();
      whenListen(settingsCubit, const Stream<AppSettings>.empty(), initialState: settings);
      final session = MockSessionCubit();
      whenListen(
        session,
        const Stream<SessionState>.empty(),
        initialState: me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me),
      );
      final highlights = FakeHighlightsRepository();
      final cubit = ArticleHighlightsCubit(GetArticleHighlights(highlights), EditHighlights(highlights));
      addTearDown(cubit.close);
      final a = details ?? article;
      usePhoneSurface(tester, size: const Size(390, 2400));
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<SettingsCubit>.value(value: settingsCubit),
            BlocProvider<ArticleHighlightsCubit>.value(value: cubit),
          ],
          child: Scaffold(
            body: ReaderHighlights(article: a, onTextChanged: onTextChanged, child: ReaderBody(article: a, bodyFontSize: 17)),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();
      await tester.pump();
    }

    Finder unit(String blockId) {
      final b = document.blocks.firstWhere((x) => x.id == blockId);
      return find.descendant(
        of: find.descendant(of: find.byKey(ValueKey('rdoc-${b.type}-${b.id}')), matching: find.byType(RHighlightUnit)),
        matching: find.byType(RichText),
      );
    }

    Offset at(WidgetTester tester, Finder rich, int plain) {
      final paragraph = tester.renderObject<RenderParagraph>(rich.first);
      final offset = renderedOffsetsOf(paragraph.text.toPlainText())[plain];
      final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: offset, extentOffset: offset + 1));
      return paragraph.localToGlobal(boxes.first.toRect().center);
    }

    Future<AppLocalizations> selectWord(WidgetTester tester, Variant variant) async {
      await tester.longPressAt(at(tester, unit('p1'), 45)); // "Dependency" (plain 42–52)
      await tester.pumpAndSettle();
      return AppLocalizations.delegate.load(variant.locale);
    }

    for (final variant in Variant.all) {
      testWidgets('Share quote next to Highlight opens the sheet on the selection, in the app theme ${variant.name}', (tester) async {
        await pumpReader(tester, variant: variant);
        final l10n = await selectWord(tester, variant);
        expect(find.text(l10n.highlightAction), findsOneWidget);
        expect(find.text(l10n.quoteCardAction), findsOneWidget);

        await tester.tap(find.text(l10n.quoteCardAction));
        await tester.pumpAndSettle();
        expect(find.byType(QuoteCardSheet), findsOneWidget);
        // The sheet's title says the same as the toolbar's action (one wording, as on web).
        expect(l10n.quoteCardTitle, l10n.quoteCardAction);
        expect(find.descendant(of: find.byType(QuoteCardSheet), matching: find.text(l10n.quoteCardTitle)), findsOneWidget);
        // The toolbar closed and the selection cleared: the action is left only as the sheet's title.
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
        expect(find.text(l10n.quoteCardAction), findsOneWidget);
        expect(repository.requests.single, QuoteCardRequest(
          articleId: 'art-1',
          language: 'ar-EG',
          range: _range,
          theme: variant.brightness == Brightness.dark ? QuoteCardTheme.dark : QuoteCardTheme.light,
          format: QuoteCardFormat.square,
        ));
        expect(find.byKey(const ValueKey('quote-card-preview')), findsOneWidget);
      });
    }

    testWidgets('a guest gets it too, with no sign-in prompt', (tester) async {
      await pumpReader(tester, me: null);
      final l10n = await selectWord(tester, const Variant(AppLocales.ar, Brightness.light));
      await tester.tap(find.text(l10n.quoteCardAction));
      await tester.pumpAndSettle();
      expect(find.text(l10n.signInPromptTitle), findsNothing);
      expect(find.byType(QuoteCardSheet), findsOneWidget);
      expect(repository.requests, hasLength(1));
    });

    testWidgets('while highlights are hidden there is no Share quote (no selection toolbar at all), as on web', (tester) async {
      await pumpReader(tester, settings: const AppSettings(showHighlights: false));
      final l10n = await AppLocalizations.delegate.load(const Variant(AppLocales.ar, Brightness.light).locale);
      final p1 = find.byKey(const ValueKey('rdoc-paragraph-p1'));
      expect(p1, findsOneWidget);
      expect(find.descendant(of: p1, matching: find.byType(SelectionArea)), findsNothing);
      await tester.longPress(p1);
      await tester.pumpAndSettle();
      expect(find.text(l10n.quoteCardAction), findsNothing);
      expect(find.text(l10n.highlightAction), findsNothing);
      expect(find.byType(QuoteCardSheet), findsNothing);
      expect(repository.requests, isEmpty);
    });

    testWidgets('a member who cannot highlight still gets Share quote', (tester) async {
      await pumpReader(tester, me: _reader);
      final l10n = await selectWord(tester, const Variant(AppLocales.ar, Brightness.light));
      expect(find.text(l10n.highlightAction), findsNothing);
      expect(find.text(l10n.quoteCardAction), findsOneWidget);
    });

    testWidgets('not on an article hidden by moderators', (tester) async {
      await pumpReader(
        tester,
        details: ArticleDetails(
          card: sampleCard(1),
          availableLanguages: const ['ar-EG'],
          content: document,
          moderation: ArticleModeration(hiddenAt: DateTime.utc(2026, 11, 5)),
        ),
      );
      final l10n = await selectWord(tester, const Variant(AppLocales.ar, Brightness.light));
      expect(find.text(l10n.highlightAction), findsOneWidget);
      expect(find.text(l10n.quoteCardAction), findsNothing);
    });

    testWidgets('never in a code, table or steps block: they have no selection toolbar', (tester) async {
      await pumpReader(tester);
      for (final id in ['k1', 't1', 'st1']) {
        final b = document.blocks.firstWhere((x) => x.id == id);
        expect(find.descendant(of: find.byKey(ValueKey('rdoc-${b.type}-${b.id}')), matching: find.byType(SelectionArea)), findsNothing,
            reason: id);
      }
    });

    testWidgets('more than 400 characters: the too_long message, no call and no sheet', (tester) async {
      await pumpReader(tester);
      final highlights = tester.widget<RDocHighlights>(find.byType(RDocHighlights));
      final range = HighlightRange(blockId: 'p1', startOffset: 0, endOffset: 401, text: 'x' * 401);
      highlights.onShareQuote!(tester.element(find.byType(RDocHighlights)), HighlightSelection(HighlightSelectionStatus.ok, range));
      await tester.pump();
      expect(find.text('الاقتباس لازم يكون 400 حرف أو أقل. اختار جزء أصغر.'), findsOneWidget);
      expect(repository.requests, isEmpty);
      expect(find.byType(QuoteCardSheet), findsNothing);

      // Exactly 400 opens the sheet.
      final most = HighlightRange(blockId: 'p1', startOffset: 0, endOffset: 400, text: 'x' * 400);
      highlights.onShareQuote!(tester.element(find.byType(RDocHighlights)), HighlightSelection(HighlightSelectionStatus.ok, most));
      await tester.pumpAndSettle();
      expect(find.byType(QuoteCardSheet), findsOneWidget);
      expect(repository.requests.single.range, most);
    });

    testWidgets('the text changed meanwhile: the message, and the reader loads the article again', (tester) async {
      var changed = 0;
      repository.answer = (_) => const Err(Failure(FailureCodes.quoteTextMismatch, statusCode: 400));
      await pumpReader(tester, onTextChanged: () => changed++);
      final l10n = await selectWord(tester, const Variant(AppLocales.ar, Brightness.light));
      await tester.tap(find.text(l10n.quoteCardAction));
      await tester.pumpAndSettle();
      expect(find.text('النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.'), findsOneWidget);
      expect(find.byKey(const ValueKey('quote-card-retry')), findsNothing);
      expect(changed, 1);
    });
  });

  group('the sheet', () {
    Future<AppLocalizations> openSheet(
      WidgetTester tester, {
      Variant variant = const Variant(AppLocales.en, Brightness.light),
      bool settle = true,
    }) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => unawaited(showQuoteCardSheet(context, article: sampleCard(1, language: 'en'), range: _range)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.tap(find.text('open'));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      return AppLocalizations.delegate.load(variant.locale);
    }

    FilledButton shareButton(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(const ValueKey('quote-card-share')));
    OutlinedButton saveButton(WidgetTester tester) => tester.widget<OutlinedButton>(find.byKey(const ValueKey('quote-card-save')));

    for (final variant in Variant.all) {
      testWidgets('switching the theme and the format asks for each new card once ${variant.name}', (tester) async {
        final l10n = await openSheet(tester, variant: variant);
        final start = variant.brightness == Brightness.dark ? QuoteCardTheme.dark : QuoteCardTheme.light;
        final other = start == QuoteCardTheme.dark ? QuoteCardTheme.light : QuoteCardTheme.dark;
        expect(find.byKey(ValueKey('quote-card-image-${start.name}-square')), findsOneWidget);

        await tester.tap(find.text(l10n.quoteCardLandscape));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('quote-card-image-${start.name}-landscape')), findsOneWidget);
        // The preview takes the landscape card's shape.
        final size = tester.getSize(find.byKey(const ValueKey('quote-card-preview')));
        expect(size.width / size.height, closeTo(1200 / 630, 0.02));

        await tester.tap(find.text(start == QuoteCardTheme.dark ? l10n.themeLight : l10n.themeDark));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('quote-card-image-${other.name}-landscape')), findsOneWidget);

        await tester.tap(find.text(l10n.quoteCardSquare));
        await tester.pumpAndSettle();
        await tester.tap(find.text(start == QuoteCardTheme.dark ? l10n.themeDark : l10n.themeLight));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('quote-card-image-${start.name}-square')), findsOneWidget);
        expect([for (final r in repository.requests) (r.theme, r.format)], [
          (start, QuoteCardFormat.square),
          (start, QuoteCardFormat.landscape),
          (other, QuoteCardFormat.landscape),
          (other, QuoteCardFormat.square),
        ]);
        expect(repository.requests.map((r) => r.language).toSet(), {'en'});
      });
    }

    testWidgets('Share sends the card on screen with the article link; Save keeps it', (tester) async {
      final l10n = await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('quote-card-share')));
      await tester.pumpAndSettle();
      final call = share.shared.single;
      expect(call.path, '/tmp/quote-card/readin-quote-light-square.png');
      expect(call.mimeType, 'image/png');
      expect(call.text, AppLinks.article('article-1', language: 'en'));
      expect(call.subject, sampleCard(1, language: 'en').title);
      expect(call.origin, isNotNull);
      expect(repository.files.single.fileName, 'readin-quote-light-square.png');

      await tester.tap(find.byKey(const ValueKey('quote-card-save')));
      await tester.pumpAndSettle();
      expect(saver.saved.single.fileName, 'readin-quote-light-square.png');
      expect(saver.saved.single.bytes, tinyPng);
      expect(find.text(l10n.quoteCardSaved), findsOneWidget);
      // Both used the bytes already shown.
      expect(repository.requests, hasLength(1));
    });

    testWidgets('a share sheet or a save that fails says so', (tester) async {
      final l10n = await openSheet(tester);
      share.fail = true;
      await tester.tap(find.byKey(const ValueKey('quote-card-share')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.quoteCardShareFailed), findsOneWidget);
      saver.fail = true;
      await tester.tap(find.byKey(const ValueKey('quote-card-save')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.quoteCardSaveFailed), findsOneWidget);
      expect(find.text(l10n.quoteCardShareFailed), findsNothing);
    });

    testWidgets('while the card is drawn: a box of its shape with a spinner, Share and Save off', (tester) async {
      repository.gate = Completer<void>();
      final l10n = await openSheet(tester, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.quoteCardPreparing), findsOneWidget);
      final size = tester.getSize(find.byKey(const ValueKey('quote-card-preview')));
      expect(size.width, closeTo(size.height, 0.5));
      expect(shareButton(tester).onPressed, isNull);
      expect(saveButton(tester).onPressed, isNull);

      repository.gate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(shareButton(tester).onPressed, isNotNull);
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('busy: the message with "Try again", which asks again and shows the card', (tester) async {
      repository.answer = (_) => const Err(Failure(FailureCodes.quoteBusy, statusCode: 503));
      final l10n = await openSheet(tester);
      expect(find.text('Many cards are being prepared right now. Try again in a moment.'), findsOneWidget);
      expect(shareButton(tester).onPressed, isNull);

      repository.answer = null;
      await tester.tap(find.byKey(const ValueKey('quote-card-retry')));
      await tester.pumpAndSettle();
      expect(repository.requests, hasLength(2));
      expect(find.byKey(const ValueKey('quote-card-image-light-square')), findsOneWidget);
      expect(find.text(l10n.errQuoteCardBusy), findsNothing);
      expect(shareButton(tester).onPressed, isNotNull);
    });

    testWidgets('offline: "you need an internet connection", with "Try again"', (tester) async {
      repository.answer = (_) => const Err(Failure(FailureCodes.networkOffline));
      await openSheet(tester, variant: const Variant(AppLocales.ar, Brightness.light));
      expect(find.text('محتاج إنترنت عشان تعمل كارت اقتباس.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('حاول تاني'), findsOneWidget);
    });

    testWidgets('refusals without "Try again": hidden, not found', (tester) async {
      repository.answer = (r) => Err(Failure(switch (r.format) {
            QuoteCardFormat.square => FailureCodes.quoteHidden,
            QuoteCardFormat.landscape => FailureCodes.articleNotFound,
          }));
      final l10n = await openSheet(tester);
      expect(find.text(l10n.errQuoteCardHidden), findsOneWidget);
      expect(find.byKey(const ValueKey('quote-card-retry')), findsNothing);
      await tester.tap(find.text(l10n.quoteCardLandscape));
      await tester.pumpAndSettle();
      expect(find.text(l10n.errQuoteCardNotFound), findsOneWidget);
      expect(find.byKey(const ValueKey('quote-card-retry')), findsNothing);
    });

    testWidgets('the controls have their ar/en names for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await openSheet(tester);
      // The picture says its quote, as the web's alt does.
      expect(find.bySemanticsLabel(l10n.quoteCardPreview(_range.text)), findsOneWidget);
      expect(l10n.quoteCardPreview(_range.text), 'Quote card: Dependency');
      expect(find.bySemanticsLabel(RegExp(l10n.quoteCardThemeLabel)), findsWidgets);
      expect(find.bySemanticsLabel(RegExp(l10n.quoteCardFormatLabel)), findsWidgets);
      expect(find.widgetWithText(FilledButton, l10n.quoteCardShare), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, l10n.quoteCardSave), findsOneWidget);
      expect(find.widgetWithText(TextButton, l10n.quoteCardCopyLink), findsOneWidget);
      handle.dispose();
    });

    for (final variant in Variant.all) {
      testWidgets('Copy link puts the article link on the clipboard and says so, without waiting for the card ${variant.name}',
          (tester) async {
        final copied = <String?>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map<Object?, Object?>)['text'] as String?);
          return null;
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
        repository.gate = Completer<void>();
        final l10n = await openSheet(tester, variant: variant, settle: false);
        expect(shareButton(tester).onPressed, isNull, reason: 'the card is still being drawn');

        await tester.ensureVisible(find.byKey(const ValueKey('quote-card-copy-link')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('quote-card-copy-link')));
        await tester.pump();
        await tester.pump();
        expect(copied, [AppLinks.article('article-1', language: 'en')]);
        expect(find.text(l10n.quoteCardLinkCopied), findsOneWidget);
        expect(l10n.quoteCardLinkCopied, variant.locale.languageCode == 'ar' ? 'اتنسخ اللينك' : 'Link copied');
        expect(repository.requests, hasLength(1), reason: 'copying asks the API nothing');

        repository.gate!.complete();
        await tester.pumpAndSettle();
      });
    }
  });
}
