import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../admin/domain/entities/paged_list.dart';
import '../../../admin/presentation/cubit/admin_list_cubit.dart';
import '../../../media/domain/entities/media.dart';
import '../../../media/domain/repositories/media_picker.dart';
import '../../domain/entities/support.dart';
import '../../domain/usecases/support_usecases.dart';

/// The support email and the categories (`GET /support/config`); null until read. A failure leaves it null, so the
/// pages fall back to the built-in email and every category.
@injectable
class SupportConfigCubit extends Cubit<SupportConfig?> {
  SupportConfigCubit(this._get) : super(null);

  final GetSupportConfig _get;

  Future<void> load() async {
    final result = await _get();
    if (!isClosed && result.valueOrNull != null) emit(result.valueOrNull);
  }
}

enum SupportListStatus { loading, ready, failure }

/// My tickets in one tab (active or closed), latest activity first, 20 a page.
class MyTicketsState extends Equatable {
  const MyTicketsState({
    this.status = SupportListStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.moreFailure,
  });

  final SupportListStatus status;
  final List<SupportTicketSummary> items;
  final String? nextCursor;
  final bool loadingMore;
  final Failure? failure;
  final Failure? moreFailure;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [status, items, nextCursor, loadingMore, failure, moreFailure];
}

@injectable
class MyTicketsCubit extends Cubit<MyTicketsState> {
  MyTicketsCubit(this._get, @factoryParam this.filter) : super(const MyTicketsState());

  final GetMyTickets _get;
  final MyTicketsFilter filter;
  int _generation = 0;

  Future<Failure?> load() async {
    final generation = ++_generation;
    final result = await _get(filter);
    if (isClosed || generation != _generation) return null;
    switch (result) {
      case Ok(value: final page):
        emit(MyTicketsState(status: SupportListStatus.ready, items: page.items, nextCursor: page.nextCursor));
        return null;
      case Err(:final failure):
        if (state.items.isEmpty) emit(MyTicketsState(status: SupportListStatus.failure, failure: failure));
        return failure;
    }
  }

  Future<Failure?> refresh() => load();

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (state.status != SupportListStatus.ready || cursor == null || state.loadingMore) return;
    final generation = _generation;
    emit(MyTicketsState(status: state.status, items: state.items, nextCursor: cursor, loadingMore: true));
    final result = await _get(filter, cursor: cursor);
    if (isClosed || generation != _generation) return;
    emit(result.fold(
      (failure) => MyTicketsState(status: state.status, items: state.items, nextCursor: cursor, moreFailure: failure),
      (page) => MyTicketsState(
        status: state.status,
        items: [
          ...state.items,
          for (final item in page.items)
            if (!state.items.any((shown) => shown.id == item.id)) item,
        ],
        nextCursor: page.nextCursor,
      ),
    ));
  }
}

/// The new-ticket form (F35): a category, a subject (5–120), a message (10–2000) and up to 3 screenshots.
class NewTicketState extends Equatable {
  const NewTicketState({
    this.category,
    this.subject = '',
    this.message = '',
    this.screenshots = const [],
    this.sending = false,
    this.showErrors = false,
    this.failure,
    this.created,
  });

  final SupportCategory? category;
  final String subject;
  final String message;
  final List<PickedMediaFile> screenshots;
  final bool sending;

  /// After a first try to send: the fields say what is missing.
  final bool showErrors;
  final Failure? failure;

  /// The ticket once sent.
  final SupportTicket? created;

  bool get categoryValid => category != null;
  bool get subjectValid => _between(subject.trim().length, SupportLimits.subjectMin, SupportLimits.subjectMax);
  bool get messageValid => _between(message.trim().length, SupportLimits.firstMessageMin, SupportLimits.messageMax);
  bool get isValid => categoryValid && subjectValid && messageValid;
  bool get canAddScreenshot => screenshots.length < SupportLimits.maxScreenshots && !sending;

  static bool _between(int value, int min, int max) => value >= min && value <= max;

  NewTicketState copyWith({
    SupportCategory? category,
    String? subject,
    String? message,
    List<PickedMediaFile>? screenshots,
    bool? sending,
    bool? showErrors,
    Failure? Function()? failure,
    SupportTicket? created,
  }) =>
      NewTicketState(
        category: category ?? this.category,
        subject: subject ?? this.subject,
        message: message ?? this.message,
        screenshots: screenshots ?? this.screenshots,
        sending: sending ?? this.sending,
        showErrors: showErrors ?? this.showErrors,
        failure: failure != null ? failure() : this.failure,
        created: created ?? this.created,
      );

  @override
  List<Object?> get props => [category, subject, message, screenshots, sending, showErrors, failure, created];
}

@injectable
class NewTicketCubit extends Cubit<NewTicketState> {
  NewTicketCubit(this._create, this._picker) : super(const NewTicketState());

  final CreateSupportTicket _create;
  final MediaPicker _picker;

  void setCategory(SupportCategory category) => emit(state.copyWith(category: category, failure: () => null));

  void setSubject(String subject) => emit(state.copyWith(subject: subject, failure: () => null));

  void setMessage(String message) => emit(state.copyWith(message: message, failure: () => null));

  /// Picks images from the gallery, up to the 3 allowed.
  Future<void> pickScreenshots() async {
    if (!state.canAddScreenshot) return;
    final picked = await _picker.pickImages(limit: SupportLimits.maxScreenshots - state.screenshots.length);
    if (isClosed || picked.isEmpty) return;
    emit(state.copyWith(
      screenshots: [...state.screenshots, ...picked].take(SupportLimits.maxScreenshots).toList(),
      failure: () => null,
    ));
  }

  void removeScreenshot(int index) {
    if (index < 0 || index >= state.screenshots.length || state.sending) return;
    emit(state.copyWith(screenshots: [...state.screenshots]..removeAt(index)));
  }

  /// Sends it; [screen] is the route the ticket came from. Null when it was sent (`state.created`).
  Future<Failure?> submit({String? screen}) async {
    if (state.sending) return const Failure(FailureCodes.requestCancelled);
    if (!state.isValid) {
      emit(state.copyWith(showErrors: true));
      return const Failure(FailureCodes.validationFailed);
    }
    emit(state.copyWith(sending: true, showErrors: true, failure: () => null));
    final result = await _create(
      category: state.category!,
      subject: state.subject,
      message: state.message,
      screenshots: state.screenshots,
      screen: screen,
    );
    if (isClosed) return result.failureOrNull;
    emit(result.fold(
      (failure) => state.copyWith(sending: false, failure: () => failure),
      (ticket) => state.copyWith(sending: false, created: ticket),
    ));
    return result.failureOrNull;
  }
}

/// A conversation's page, for the member ([SupportTicket]) or in the console ([AdminTicket]).
enum TicketPageStatus { loading, ready, failure }

/// What a ticket page is doing.
enum TicketCommand { reply, note, close, reopen, category }

class SupportTicketState extends Equatable {
  const SupportTicketState({this.status = TicketPageStatus.loading, this.ticket, this.failure, this.busy});

  final TicketPageStatus status;
  final SupportTicket? ticket;
  final Failure? failure;
  final TicketCommand? busy;

  @override
  List<Object?> get props => [status, ticket, failure, busy];
}

/// The member's ticket (F35): the conversation, reply with screenshots, close, reopen within 30 days.
@injectable
class SupportTicketCubit extends Cubit<SupportTicketState> {
  SupportTicketCubit(this._commands, @factoryParam this.ticketId) : super(const SupportTicketState());

  final MyTicketCommands _commands;
  final String ticketId;

  Future<Failure?> load() async {
    final result = await _commands.get(ticketId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (state.ticket == null) emit(SupportTicketState(status: TicketPageStatus.failure, failure: failure));
        return failure;
      },
      (ticket) {
        emit(SupportTicketState(status: TicketPageStatus.ready, ticket: ticket, busy: state.busy));
        return null;
      },
    );
  }

  /// Sends a message (1–2000, up to 3 screenshots); the conversation is read again. Null when it was sent.
  Future<Failure?> reply(String message, {List<PickedMediaFile> screenshots = const []}) {
    final text = message.trim();
    if (text.isEmpty || text.length > SupportLimits.messageMax) return Future.value(const Failure(FailureCodes.validationFailed));
    return _run(TicketCommand.reply, () => _commands.reply(ticketId, text, screenshots: screenshots));
  }

  Future<Failure?> closeTicket() => _run(TicketCommand.close, () => _commands.close(ticketId));

  Future<Failure?> reopenTicket() => _run(TicketCommand.reopen, () => _commands.reopen(ticketId));

  Future<Failure?> _run<T>(TicketCommand command, Future<Result<T>> Function() call) async {
    if (state.busy != null || state.ticket == null) return const Failure(FailureCodes.requestCancelled);
    emit(SupportTicketState(status: state.status, ticket: state.ticket, busy: command));
    final result = await call();
    final failure = result.failureOrNull;
    // A closed ticket or an expired reopen: the page shows the ticket as it is now.
    if (!isClosed) await load();
    if (!isClosed) emit(SupportTicketState(status: state.status, ticket: state.ticket, failure: state.failure));
    return failure;
  }
}

/// The console's ticket queue (F35): a status tab, a category, a search; 50 a page.
@injectable
class AdminTicketsCubit extends AdminListCubit<AdminTicketRow, AdminTicketQuery> {
  AdminTicketsCubit(this._get, @factoryParam AdminTicketQuery? query) : super(query ?? const AdminTicketQuery());

  final GetAdminTickets _get;

  @override
  Future<Result<PagedList<AdminTicketRow>>> fetch(AdminTicketQuery query, int page) => _get(query, page: page);

  @override
  Object idOf(AdminTicketRow item) => item.id;
}

class AdminTicketState extends Equatable {
  const AdminTicketState({this.status = TicketPageStatus.loading, this.ticket, this.failure, this.busy});

  final TicketPageStatus status;
  final AdminTicket? ticket;
  final Failure? failure;
  final TicketCommand? busy;

  @override
  List<Object?> get props => [status, ticket, failure, busy];
}

/// A ticket in the console (F35): reply, add an internal note, change the category, close and reopen.
@injectable
class AdminTicketCubit extends Cubit<AdminTicketState> {
  AdminTicketCubit(this._commands, @factoryParam this.ticketId) : super(const AdminTicketState());

  final AdminTicketCommands _commands;
  final String ticketId;

  Future<Failure?> load() async {
    final result = await _commands.get(ticketId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (state.ticket == null) emit(AdminTicketState(status: TicketPageStatus.failure, failure: failure));
        return failure;
      },
      (ticket) {
        emit(AdminTicketState(status: TicketPageStatus.ready, ticket: ticket, busy: state.busy));
        return null;
      },
    );
  }

  /// A reply the member sees (the ticket becomes Answered), or an internal note only admins see ([internal]).
  Future<Failure?> post(String body, {required bool internal}) {
    final text = body.trim();
    if (text.isEmpty || text.length > SupportLimits.messageMax) return Future.value(const Failure(FailureCodes.validationFailed));
    return _run(internal ? TicketCommand.note : TicketCommand.reply, () async {
      final result = await _commands.post(ticketId, text, internal: internal);
      if (result.isOk) await load();
      return result;
    });
  }

  Future<Failure?> setCategory(SupportCategory category) {
    if (state.ticket?.row.category == category) return Future.value();
    return _run(TicketCommand.category, () => _update(category: category));
  }

  Future<Failure?> closeTicket() => _run(TicketCommand.close, () => _update(status: SupportStatus.closed));

  Future<Failure?> reopenTicket() => _run(TicketCommand.reopen, () => _update(status: SupportStatus.open));

  Future<Result<AdminTicket>> _update({SupportStatus? status, SupportCategory? category}) async {
    final result = await _commands.update(ticketId, status: status, category: category);
    final ticket = result.valueOrNull;
    if (!isClosed && ticket != null) emit(AdminTicketState(status: TicketPageStatus.ready, ticket: ticket, busy: state.busy));
    return result;
  }

  Future<Failure?> _run<T>(TicketCommand command, Future<Result<T>> Function() call) async {
    if (state.busy != null || state.ticket == null) return const Failure(FailureCodes.requestCancelled);
    emit(AdminTicketState(status: state.status, ticket: state.ticket, busy: command));
    final result = await call();
    final failure = result.failureOrNull;
    if (failure?.code == FailureCodes.supportTicketClosed && !isClosed) await load();
    if (!isClosed) emit(AdminTicketState(status: state.status, ticket: state.ticket));
    return failure;
  }
}

/// Screenshots of tickets in memory, read once each with the session (never on disk). A failed read is asked again
/// next time.
@lazySingleton
class SupportAttachmentCache {
  SupportAttachmentCache(this._load);

  final LoadSupportAttachment _load;

  static const maxEntries = 30;

  final _entries = <String, Future<Result<Uint8List>>>{};

  Future<Result<Uint8List>> get(String attachmentId) {
    final cached = _entries.remove(attachmentId);
    final future = cached ?? _load(attachmentId);
    _entries[attachmentId] = future;
    if (_entries.length > maxEntries) _entries.remove(_entries.keys.first);
    if (cached == null) {
      future.then((result) {
        if (!result.isOk && identical(_entries[attachmentId], future)) _entries.remove(attachmentId);
      });
    }
    return future;
  }

  /// Forget everything (signing out).
  void clear() => _entries.clear();
}
