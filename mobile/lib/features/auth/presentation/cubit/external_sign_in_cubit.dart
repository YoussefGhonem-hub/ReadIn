import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/current_locale.dart';
import '../../../../core/phone/countries.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../domain/entities/external_credential.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'form_support.dart';

class ExternalSignInState extends Equatable {
  const ExternalSignInState({
    this.providers = const [],
    this.status = FormStatus.idle,
    this.busy,
    this.failure,
    this.notLinked,
    this.linkErrors = const {},
    this.linkFailure,
  });

  /// The buttons to show (server config ∩ this device).
  final List<ExternalProvider> providers;
  final FormStatus status;

  /// The provider whose sign in is running: its button shows the progress.
  final ExternalProvider? busy;

  /// Shown under the buttons.
  final Failure? failure;

  /// `auth.external_not_linked`: the identity waiting for "create a new account" or "I already have an account".
  final ExternalCredential? notLinked;

  /// The "I already have an account" form.
  final Map<String, String> linkErrors;
  final Failure? linkFailure;

  bool get submitting => status == FormStatus.submitting;

  ExternalSignInState copyWith({
    List<ExternalProvider>? providers,
    FormStatus? status,
    ExternalProvider? Function()? busy,
    Failure? Function()? failure,
    ExternalCredential? Function()? notLinked,
    Map<String, String>? linkErrors,
    Failure? Function()? linkFailure,
  }) =>
      ExternalSignInState(
        providers: providers ?? this.providers,
        status: status ?? this.status,
        busy: busy != null ? busy() : this.busy,
        failure: failure != null ? failure() : this.failure,
        notLinked: notLinked != null ? notLinked() : this.notLinked,
        linkErrors: linkErrors ?? this.linkErrors,
        linkFailure: linkFailure != null ? linkFailure() : this.linkFailure,
      );

  @override
  List<Object?> get props => [providers, status, busy, failure, notLinked, linkErrors, linkFailure];
}

/// "Continue with Google / Apple" (SPEC §9.2, ADR 0012): the provider's sheet, then `POST /auth/external`. A new
/// identity asks "create a new account" or "I already have an account" (phone + password). On success the session
/// changes and the router applies the guards.
@injectable
class ExternalSignInCubit extends Cubit<ExternalSignInState> {
  ExternalSignInCubit(this._providers, this._obtain, this._signIn, this._locale, this._countries)
      : super(const ExternalSignInState());

  final GetExternalProviders _providers;
  final ObtainExternalCredential _obtain;
  final SignInWithExternal _signIn;
  final CurrentLocale _locale;
  final PhoneCountryMemory _countries;

  Future<void> load() async {
    final providers = await _providers();
    if (!isClosed) emit(state.copyWith(providers: providers));
  }

  /// Closing the provider's sheet changes nothing.
  Future<void> start(ExternalProvider provider) async {
    if (state.submitting) return;
    emit(state.copyWith(
      status: FormStatus.submitting,
      busy: () => provider,
      failure: () => null,
      notLinked: () => null,
      linkErrors: const {},
      linkFailure: () => null,
    ));
    final obtained = await _obtain(provider);
    if (isClosed) return;
    final credential = obtained.valueOrNull;
    if (credential == null) return emit(_idle(failure: obtained.failureOrNull));

    final result = await _signIn(credential, uiLanguage: _locale.languageCode);
    if (isClosed) return;
    switch (result.failureOrNull) {
      case null:
        emit(state.copyWith(status: FormStatus.success, busy: () => null));
      case Failure(code: FailureCodes.authExternalNotLinked):
        emit(_idle().copyWith(notLinked: () => credential));
      case final failure:
        emit(_idle(failure: failure));
    }
  }

  /// The not-linked sheet was closed without a choice.
  void dismissNotLinked() => emit(state.copyWith(notLinked: () => null));

  /// "اعمل حساب جديد": the account starts without a phone, password or PIN, then Complete profile.
  Future<void> createAccount() async {
    final credential = state.notLinked;
    if (credential == null || state.submitting) return;
    emit(state.copyWith(status: FormStatus.submitting, busy: () => credential.provider, failure: () => null));
    final result = await _signIn(credential, uiLanguage: _locale.languageCode, createAccount: true);
    if (isClosed) return;
    emit(result.failureOrNull == null
        ? state.copyWith(status: FormStatus.success, busy: () => null)
        : _idle(failure: result.failureOrNull).copyWith(notLinked: () => null));
  }

  /// "عندي حساب برقم تليفون": the phone sign in links the identity, then signs in.
  Future<void> link({required String? phoneE164, required bool phoneEmpty, required String password}) async {
    final credential = state.notLinked;
    if (credential == null || state.submitting) return;
    final errors = Validate.collect({
      Fields.phone: Validate.phone(empty: phoneEmpty, e164: phoneE164),
      Fields.password: Validate.required(password),
    });
    if (errors.isNotEmpty) return emit(state.copyWith(linkErrors: errors, linkFailure: () => null));

    emit(state.copyWith(status: FormStatus.submitting, linkErrors: const {}, linkFailure: () => null));
    final result = await _signIn(
      credential,
      uiLanguage: _locale.languageCode,
      link: (phoneNumber: phoneE164!, password: password),
    );
    if (isClosed) return;
    if (result.failureOrNull case final failure?) {
      final split = failure.toFormErrors(
        fieldNames: const {'link.phoneNumber': Fields.phone, 'link.password': Fields.password},
      );
      return emit(state.copyWith(status: FormStatus.idle, linkErrors: split.fields, linkFailure: () => split.general));
    }
    if (PhoneNumbers.split(phoneE164) case final parts?) await _countries.remember(parts.iso2);
    emit(state.copyWith(status: FormStatus.success));
  }

  ExternalSignInState _idle({Failure? failure}) =>
      state.copyWith(status: FormStatus.idle, busy: () => null, failure: () => failure);
}
