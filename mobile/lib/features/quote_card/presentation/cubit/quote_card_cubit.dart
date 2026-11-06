import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_links.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/platform/file_save_service.dart';
import '../../../../core/platform/share_service.dart';
import '../../../../shared/rdoc/highlights/rdoc_highlight_text.dart';
import '../../domain/entities/quote_card.dart';
import '../../domain/usecases/make_quote_card.dart';

/// What the sheet quotes: the version on screen and the reader's selection (the F30 range, trimmed).
class QuoteCardSource extends Equatable {
  const QuoteCardSource({
    required this.articleId,
    required this.language,
    required this.slug,
    required this.title,
    required this.range,
  });

  final String articleId;

  /// `ar-EG` | `en`.
  final String language;
  final String slug;
  final String title;
  final HighlightRange range;

  /// The F24 share link of this version, sent with the picture.
  String get link => AppLinks.article(slug, language: language);

  @override
  List<Object?> get props => [articleId, language, slug, title, range];
}

/// One theme and format: the sheet keeps a card per look, so switching back shows it again without a new call.
typedef QuoteCardLook = ({QuoteCardTheme theme, QuoteCardFormat format});

enum QuoteCardSlotStatus { loading, ready, failed }

/// The card of one look: being drawn, drawn ([image]), or refused ([failure]).
class QuoteCardSlot extends Equatable {
  const QuoteCardSlot._(this.status, {this.image, this.failure});

  static const loading = QuoteCardSlot._(QuoteCardSlotStatus.loading);

  const QuoteCardSlot.ready(QuoteCardImage image) : this._(QuoteCardSlotStatus.ready, image: image);

  const QuoteCardSlot.failed(Failure failure) : this._(QuoteCardSlotStatus.failed, failure: failure);

  final QuoteCardSlotStatus status;
  final QuoteCardImage? image;
  final Failure? failure;

  @override
  List<Object?> get props => [status, image, failure];
}

/// What the sheet says under its buttons after Share, Save or Copy link.
enum QuoteCardNotice { saved, saveFailed, shareFailed, linkCopied, copyFailed }

class QuoteCardState extends Equatable {
  const QuoteCardState({
    this.theme = QuoteCardTheme.light,
    this.format = QuoteCardFormat.square,
    this.slots = const {},
    this.sharing = false,
    this.saving = false,
    this.notice,
  });

  final QuoteCardTheme theme;
  final QuoteCardFormat format;
  final Map<QuoteCardLook, QuoteCardSlot> slots;
  final bool sharing;
  final bool saving;
  final QuoteCardNotice? notice;

  QuoteCardLook get look => (theme: theme, format: format);

  /// The card of the chosen look, or null before it is asked for.
  QuoteCardSlot? get current => slots[look];

  /// The picture on screen: Share and Save use these bytes, with no new call.
  QuoteCardImage? get image => current?.image;

  bool get busy => sharing || saving;

  /// Share and Save work once the chosen look's card is drawn, one at a time.
  bool get canExport => image != null && !busy;

  QuoteCardState copyWith({
    QuoteCardTheme? theme,
    QuoteCardFormat? format,
    Map<QuoteCardLook, QuoteCardSlot>? slots,
    bool? sharing,
    bool? saving,
    QuoteCardNotice? Function()? notice,
  }) =>
      QuoteCardState(
        theme: theme ?? this.theme,
        format: format ?? this.format,
        slots: slots ?? this.slots,
        sharing: sharing ?? this.sharing,
        saving: saving ?? this.saving,
        notice: notice == null ? this.notice : notice(),
      );

  QuoteCardState withSlot(QuoteCardLook look, QuoteCardSlot slot) => copyWith(slots: {...slots, look: slot});

  @override
  List<Object?> get props => [theme, format, slots, sharing, saving, notice];
}

/// The quote card sheet (SPEC F24): the API draws the card for the chosen theme and format (one call per look, kept in
/// memory while the sheet is open), **Share** writes the PNG to a temporary file and opens the system share sheet with
/// the article's link, **Save** opens the system "Save as" dialog, **Copy link** copies the article's link (as on web).
/// Guests too.
@injectable
class QuoteCardCubit extends Cubit<QuoteCardState> {
  QuoteCardCubit(this._make, this._prepareFile, this._share, this._saver) : super(const QuoteCardState());

  final MakeQuoteCard _make;
  final PrepareQuoteCardFile _prepareFile;
  final ShareService _share;
  final FileSaveService _saver;

  QuoteCardSource? _source;

  QuoteCardSource? get source => _source;

  /// Starts on [theme] (the app's own, by default in the sheet) and [format], and draws that card.
  Future<void> open(QuoteCardSource source, {QuoteCardTheme theme = QuoteCardTheme.light, QuoteCardFormat format = QuoteCardFormat.square}) {
    _source = source;
    emit(QuoteCardState(theme: theme, format: format));
    return _load();
  }

  /// A look already drawn (or being drawn) shows again with no new call; a refused one shows why, with "Try again".
  Future<void> setTheme(QuoteCardTheme theme) async {
    if (theme == state.theme) return;
    emit(state.copyWith(theme: theme, notice: () => null));
    await _load();
  }

  Future<void> setFormat(QuoteCardFormat format) async {
    if (format == state.format) return;
    emit(state.copyWith(format: format, notice: () => null));
    await _load();
  }

  /// "Try again" on the chosen look's failure.
  Future<void> retry() => _load(again: true);

  Future<void> _load({bool again = false}) async {
    final source = _source;
    if (source == null) return;
    final look = state.look;
    final slot = state.slots[look];
    if (slot != null && !(again && slot.status == QuoteCardSlotStatus.failed)) return;
    emit(state.withSlot(look, QuoteCardSlot.loading));
    final result = await _make(QuoteCardRequest(
      articleId: source.articleId,
      language: source.language,
      range: source.range,
      theme: look.theme,
      format: look.format,
    ));
    if (isClosed) return;
    emit(state.withSlot(look, switch (result) {
      Ok(:final value) => QuoteCardSlot.ready(value),
      Err(:final failure) => QuoteCardSlot.failed(failure),
    }));
  }

  /// The card on screen to the system share sheet, with the article's link as its text. [origin] anchors it on iPad.
  Future<void> share({Rect? origin}) async {
    final image = state.image;
    final source = _source;
    if (image == null || source == null || state.busy) return;
    emit(state.copyWith(sharing: true, notice: () => null));
    var shared = false;
    if (await _prepareFile(image) case Ok(:final value)) {
      try {
        await _share.shareFileWithText(
          value,
          mimeType: 'image/png',
          text: source.link,
          subject: source.title,
          fileName: image.fileName,
          origin: origin,
        );
        shared = true;
      } on Object {
        // No share sheet on this device: said below.
      }
    }
    if (isClosed) return;
    emit(state.copyWith(sharing: false, notice: () => shared ? null : QuoteCardNotice.shareFailed));
  }

  /// The card on screen to a file the person picks. Cancelling says nothing.
  Future<void> save() async {
    final image = state.image;
    if (image == null || state.busy) return;
    emit(state.copyWith(saving: true, notice: () => null));
    QuoteCardNotice? notice;
    try {
      if (await _saver.save(image.bytes, fileName: image.fileName, mimeType: 'image/png')) notice = QuoteCardNotice.saved;
    } on Object {
      notice = QuoteCardNotice.saveFailed;
    }
    if (isClosed) return;
    emit(state.copyWith(saving: false, notice: () => notice));
  }

  /// The article's F24 share link to the clipboard, whatever the card's state; the sheet says it was copied.
  Future<void> copyLink() async {
    final source = _source;
    if (source == null) return;
    var notice = QuoteCardNotice.linkCopied;
    try {
      await Clipboard.setData(ClipboardData(text: source.link));
    } on Object {
      notice = QuoteCardNotice.copyFailed;
    }
    if (isClosed) return;
    emit(state.copyWith(notice: () => notice));
  }
}
