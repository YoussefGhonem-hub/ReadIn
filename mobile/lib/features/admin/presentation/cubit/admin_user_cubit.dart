import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/usecases/admin_usecases.dart';

enum AdminPageStatus { loading, ready, failure }

/// The account actions of a user's page that aren't moderation (warn, suspend and hide run through the moderation
/// flows).
enum AdminUserCommand { revealPhone, logoutAll, resetPassword, removeBadge }

class AdminUserState extends Equatable {
  const AdminUserState({this.status = AdminPageStatus.loading, this.user, this.failure, this.phone, this.busy});

  final AdminPageStatus status;
  final AdminUser? user;
  final Failure? failure;

  /// The full phone number once revealed (audited); it stays until the page closes.
  final String? phone;

  /// The command in flight; its button shows progress and the others wait.
  final AdminUserCommand? busy;

  AdminUserState copyWith({
    AdminPageStatus? status,
    AdminUser? user,
    Failure? Function()? failure,
    String? Function()? phone,
    AdminUserCommand? Function()? busy,
  }) =>
      AdminUserState(
        status: status ?? this.status,
        user: user ?? this.user,
        failure: failure != null ? failure() : this.failure,
        phone: phone != null ? phone() : this.phone,
        busy: busy != null ? busy() : this.busy,
      );

  @override
  List<Object?> get props => [status, user, failure, phone, busy];
}

/// A user's console page (F23).
@injectable
class AdminUserCubit extends Cubit<AdminUserState> {
  AdminUserCubit(this._get, this._commands, @factoryParam this.userId) : super(const AdminUserState());

  final GetAdminUser _get;
  final AdminUserCommands _commands;
  final String userId;

  /// The page; a reload after an action keeps what is shown when it fails, and returns why.
  Future<Failure?> load() async {
    final result = await _get(userId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (state.user == null) emit(AdminUserState(status: AdminPageStatus.failure, failure: failure));
        return failure;
      },
      (user) {
        emit(state.copyWith(status: AdminPageStatus.ready, user: user, failure: () => null));
        return null;
      },
    );
  }

  /// "Show" the phone number: null when it worked.
  Future<Failure?> revealPhone() => _run(AdminUserCommand.revealPhone, () async {
        final result = await _commands.revealPhone(userId);
        if (result.isOk && !isClosed) emit(state.copyWith(phone: () => result.valueOrNull ?? ''));
        return result.failureOrNull;
      });

  /// Sign out of all devices: null when it worked.
  Future<Failure?> logoutAll() => _run(AdminUserCommand.logoutAll, () async {
        final result = await _commands.logoutAll(userId);
        if (result.isOk) await load();
        return result.failureOrNull;
      });

  /// Reset the password: the temporary password (shown once), or why it failed.
  Future<({String? password, Failure? failure})> resetPassword() async {
    String? password;
    final failure = await _run(AdminUserCommand.resetPassword, () async {
      final result = await _commands.resetPassword(userId);
      password = result.valueOrNull;
      if (result.isOk) await load();
      return result.failureOrNull;
    });
    return (password: password, failure: failure);
  }

  /// Remove the Verified badge. `409 verification.not_verified` means someone already did: the page is read again.
  Future<Failure?> removeBadge() => _run(AdminUserCommand.removeBadge, () async {
        final result = await _commands.removeBadge(userId);
        if (result.isOk || result.failureOrNull?.code == FailureCodes.verificationNotVerified) await load();
        return result.failureOrNull;
      });

  Future<Failure?> _run(AdminUserCommand command, Future<Failure?> Function() body) async {
    if (state.busy != null) return const Failure(FailureCodes.requestCancelled);
    emit(state.copyWith(busy: () => command));
    final failure = await body();
    if (!isClosed) emit(state.copyWith(busy: () => null));
    return failure;
  }
}
