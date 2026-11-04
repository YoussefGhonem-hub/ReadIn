import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/entities/me.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'form_support.dart';

/// What happens (deleted, kept, final) → confirm it's you and the last confirmation.
enum DeleteAccountStep { review, confirm }

class DeleteAccountState extends Equatable {
  const DeleteAccountState({
    this.step = DeleteAccountStep.review,
    this.hasPassword = true,
    this.providers = const [],
    this.status = FormStatus.idle,
    this.understood = false,
    this.confirmedWith,
    this.busyProvider,
    this.passwordError,
    this.failure,
    this.confirming = false,
  });

  final DeleteAccountStep step;

  /// Confirmed with the password; otherwise with a linked Google / Apple account.
  final bool hasPassword;

  /// The Google / Apple accounts that can confirm it's you on this device.
  final List<ExternalProvider> providers;

  /// `submitting` while `DELETE /me` runs, `success` once the account is gone.
  final FormStatus status;

  /// "I understand, delete my account": enables the red button.
  final bool understood;

  /// The provider that just confirmed it's you. Its credential stays in the cubit, out of the state.
  final ExternalProvider? confirmedWith;

  /// The provider whose sheet is open.
  final ExternalProvider? busyProvider;

  /// An error code for the password field (required, wrong password).
  final String? passwordError;

  /// Why the account wasn't deleted; nothing was.
  final Failure? failure;

  /// The final "Delete your account forever?" dialog is open.
  final bool confirming;

  bool get submitting => status == FormStatus.submitting;
  bool get busy => submitting || busyProvider != null;
  bool get deleted => status == FormStatus.success;

  /// Whether the red button can be used: the box is ticked and there is a way to confirm it's you.
  bool get canDelete => understood && !busy && (hasPassword || confirmedWith != null);

  /// The same request can just be sent again: nothing was deleted and the cause is temporary (Apple unreachable,
  /// offline, a timeout, a server error). Never sent by itself: the person taps Retry.
  bool get canRetry {
    final failure = this.failure;
    return failure != null && (_temporary.contains(failure.code) || (failure.statusCode ?? 0) >= 500);
  }

  static const _temporary = {
    FailureCodes.accountDeletionUnavailable,
    FailureCodes.networkOffline,
    FailureCodes.networkTimeout,
    FailureCodes.serverError,
  };

  /// The session had already ended (`401` other than a Google / Apple token the API couldn't verify): sign in again.
  bool get sessionEnded => failure?.statusCode == 401 && failure?.code != FailureCodes.authExternalInvalid;

  DeleteAccountState copyWith({
    DeleteAccountStep? step,
    bool? hasPassword,
    List<ExternalProvider>? providers,
    FormStatus? status,
    bool? understood,
    ExternalProvider? Function()? confirmedWith,
    ExternalProvider? Function()? busyProvider,
    String? Function()? passwordError,
    Failure? Function()? failure,
    bool? confirming,
  }) =>
      DeleteAccountState(
        step: step ?? this.step,
        hasPassword: hasPassword ?? this.hasPassword,
        providers: providers ?? this.providers,
        status: status ?? this.status,
        understood: understood ?? this.understood,
        confirmedWith: confirmedWith != null ? confirmedWith() : this.confirmedWith,
        busyProvider: busyProvider != null ? busyProvider() : this.busyProvider,
        passwordError: passwordError != null ? passwordError() : this.passwordError,
        failure: failure != null ? failure() : this.failure,
        confirming: confirming ?? this.confirming,
      );

  @override
  List<Object?> get props =>
      [step, hasPassword, providers, status, understood, confirmedWith, busyProvider, passwordError, failure, confirming];
}

/// Codes that mean the Google / Apple confirmation can't be used again: confirm once more.
const _rejectedConfirmations = {
  FailureCodes.authExternalMismatch,
  FailureCodes.authExternalInvalid,
  FailureCodes.authConfirmationRequired,
};

/// Delete account (SPEC F01, App Store 5.1.1(v)): immediate and final. The person reads what happens, confirms it's them
/// with the password or a fresh Google / Apple sign in (never the session alone), ticks "I understand" and confirms a
/// last dialog. When the server needs Apple to revoke its token, Apple's sheet opens by itself. A failure deletes
/// nothing and is never sent again by itself: Retry is the person's choice.
@injectable
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit(this._delete, this._confirmWith) : super(const DeleteAccountState());

  final DeleteAccount _delete;
  final ConfirmWithLinkedProvider _confirmWith;

  // Kept out of the state on purpose (never logged or compared).
  String _password = '';
  ExternalCredential? _credential;

  /// Without a password every linked account this device can show confirms it; with one, Apple too when it's linked, as
  /// a fresh Apple sign in also lets the server revoke ReadIn's access at Apple. Unknown account (offline): the password.
  void load(Me? me) {
    final linked = me == null ? const <ExternalProvider>[] : _confirmWith.providersFor(me);
    final hasPassword = me?.hasPassword ?? true;
    emit(state.copyWith(
      hasPassword: hasPassword,
      providers: hasPassword ? [for (final provider in linked) if (provider == ExternalProvider.apple) provider] : linked,
    ));
  }

  /// "Continue" after reading what happens.
  void proceed() => emit(state.copyWith(step: DeleteAccountStep.confirm));

  /// Back to what happens; forgets the confirmation.
  void back() {
    if (state.busy || state.step == DeleteAccountStep.review) return;
    _credential = null;
    emit(DeleteAccountState(hasPassword: state.hasPassword, providers: state.providers));
  }

  void setUnderstood(bool understood) {
    if (state.busy) return;
    emit(state.copyWith(understood: understood));
  }

  /// "Confirm with Google / Apple": the provider's sheet. Closing it changes nothing.
  Future<void> confirmWith(ExternalProvider provider) async {
    if (state.busy) return;
    emit(state.copyWith(busyProvider: () => provider, failure: () => null, passwordError: () => null));
    final result = await _confirmWith.using(provider);
    if (isClosed) return;
    final credential = result.valueOrNull;
    if (credential != null) _credential = credential;
    emit(state.copyWith(
      busyProvider: () => null,
      confirmedWith: credential == null ? null : () => credential.provider,
      failure: () => result.failureOrNull,
    ));
  }

  /// The red button: checks the confirmation, then opens the final dialog.
  void review({required String password}) {
    if (!state.understood || state.busy) return;
    if (_credential == null) {
      if (!state.hasPassword) {
        return emit(state.copyWith(failure: () => const Failure(FailureCodes.authConfirmationRequired)));
      }
      if (Validate.required(password) case final error?) {
        return emit(state.copyWith(passwordError: () => error, failure: () => null));
      }
    }
    _password = password;
    emit(state.copyWith(confirming: true, passwordError: () => null, failure: () => null));
  }

  void cancelConfirmation() => emit(state.copyWith(confirming: false));

  /// "Delete forever". True once the account is deleted (this device has forgotten it, the session has ended).
  Future<bool> confirm() async {
    if (!state.confirming) return false;
    emit(state.copyWith(confirming: false));
    return _send();
  }

  /// Retry after a temporary failure: the same request again, with the same confirmation.
  Future<bool> retry() async {
    if (!state.canRetry || state.busy) return false;
    return _send();
  }

  Future<bool> _send() async {
    emit(state.copyWith(status: FormStatus.submitting, failure: () => null, passwordError: () => null));
    final credential = _credential;
    final result = credential != null ? await _delete(external: credential) : await _delete(password: _password);
    final failure = result.failureOrNull;
    if (failure == null) {
      _password = '';
      _credential = null;
      if (!isClosed) emit(state.copyWith(status: FormStatus.success));
      return true;
    }
    if (isClosed) return false;
    if (failure.code == FailureCodes.authAppleConfirmationRequired) return _confirmWithApple(failure);
    _fail(failure);
    return false;
  }

  /// `auth.apple_confirmation_required`: the server has no Apple token to revoke. Apple's sheet opens by itself, and a
  /// fresh Apple confirmation (with its authorization code) is sent instead. Not possible on this device: the iPhone
  /// app, or email.
  Future<bool> _confirmWithApple(Failure failure) async {
    if (!_confirmWith.supports(ExternalProvider.apple)) {
      _fail(const Failure(FailureCodes.authAppleUnavailable));
      return false;
    }
    if (_credential?.provider == ExternalProvider.apple) {
      _fail(failure); // a fresh Apple confirmation was just sent: don't ask in a loop
      return false;
    }
    emit(state.copyWith(status: FormStatus.idle, busyProvider: () => ExternalProvider.apple));
    final result = await _confirmWith.using(ExternalProvider.apple);
    if (isClosed) return false;
    final credential = result.valueOrNull;
    if (credential == null) {
      // Closed: say why Apple is needed; "Confirm with Apple" stays available.
      emit(state.copyWith(
        busyProvider: () => null,
        providers: state.providers.contains(ExternalProvider.apple) ? null : [...state.providers, ExternalProvider.apple],
        failure: () => result.failureOrNull ?? failure,
      ));
      return false;
    }
    _credential = credential;
    emit(state.copyWith(busyProvider: () => null, confirmedWith: () => ExternalProvider.apple));
    return _send();
  }

  void _fail(Failure failure) {
    final rejected = _rejectedConfirmations.contains(failure.code);
    if (rejected) _credential = null;
    final wrongPassword = failure.code == FailureCodes.authWrongPassword;
    emit(state.copyWith(
      status: FormStatus.idle,
      confirmedWith: rejected ? () => null : null,
      passwordError: () => wrongPassword ? failure.code : null,
      failure: () => wrongPassword ? null : failure,
    ));
  }
}
