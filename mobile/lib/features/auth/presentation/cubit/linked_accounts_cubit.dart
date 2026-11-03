import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/entities/me.dart';
import '../../domain/usecases/auth_usecases.dart';

/// A link or unlink that went through, for its confirmation message.
typedef LinkedAccountChange = ({ExternalProvider provider, bool linked});

class LinkedAccountsState extends Equatable {
  const LinkedAccountsState({this.providers = const [], this.busy, this.failure, this.awaitingPassword, this.change});

  /// Providers this server and device can link.
  final List<ExternalProvider> providers;

  /// The provider being linked or unlinked.
  final ExternalProvider? busy;
  final Failure? failure;

  /// Linking with a password: the provider's token is waiting for the password dialog.
  final ExternalProvider? awaitingPassword;
  final LinkedAccountChange? change;

  @override
  List<Object?> get props => [providers, busy, failure, awaitingPassword, change];
}

/// Settings → Account → "الحسابات المربوطة" (F18, ADR 0012). Linking asks for the password, or for a fresh token of an
/// already linked provider when the account has no password; the last way to sign in can't be unlinked.
@injectable
class LinkedAccountsCubit extends Cubit<LinkedAccountsState> {
  LinkedAccountsCubit(this._providers, this._obtain, this._confirmWith, this._link, this._unlink)
      : super(const LinkedAccountsState());

  final GetExternalProviders _providers;
  final ObtainExternalCredential _obtain;
  final ConfirmWithLinkedProvider _confirmWith;
  final LinkExternalLogin _link;
  final UnlinkExternalLogin _unlink;

  ExternalCredential? _pending;

  bool get _busy => state.busy != null || state.awaitingPassword != null;

  Future<void> load() async {
    final providers = await _providers();
    if (!isClosed) emit(LinkedAccountsState(providers: providers));
  }

  /// The provider's sheet, then the password dialog ([Me.hasPassword]) or a linked provider's sheet.
  Future<void> link(ExternalProvider provider, Me me) async {
    if (_busy) return;
    emit(LinkedAccountsState(providers: state.providers, busy: provider));
    final obtained = await _obtain(provider);
    if (isClosed) return;
    final credential = obtained.valueOrNull;
    if (credential == null) return _done(failure: obtained.failureOrNull);

    if (me.hasPassword) {
      _pending = credential;
      return emit(LinkedAccountsState(providers: state.providers, awaitingPassword: provider));
    }
    final confirmation = await _confirmWith(me);
    if (isClosed) return;
    final external = confirmation.valueOrNull;
    if (external == null) return _done(failure: confirmation.failureOrNull);
    await _send(credential, () => _link(credential, external: external));
  }

  /// The password dialog's answer; null when it was cancelled.
  Future<void> confirmWithPassword(String? password) async {
    final credential = _pending;
    _pending = null;
    if (credential == null || state.awaitingPassword == null) return;
    if (password == null || password.isEmpty) return _done();
    emit(LinkedAccountsState(providers: state.providers, busy: credential.provider));
    await _send(credential, () => _link(credential, password: password));
  }

  Future<void> unlink(ExternalProvider provider) async {
    if (_busy) return;
    emit(LinkedAccountsState(providers: state.providers, busy: provider));
    final result = await _unlink(provider);
    if (isClosed) return;
    _done(failure: result.failureOrNull, change: result.isOk ? (provider: provider, linked: false) : null);
  }

  Future<void> _send(ExternalCredential credential, Future<Result<Me>> Function() call) async {
    final result = await call();
    if (isClosed) return;
    _done(failure: result.failureOrNull, change: result.isOk ? (provider: credential.provider, linked: true) : null);
  }

  void _done({Failure? failure, LinkedAccountChange? change}) =>
      emit(LinkedAccountsState(providers: state.providers, failure: failure, change: change));
}
