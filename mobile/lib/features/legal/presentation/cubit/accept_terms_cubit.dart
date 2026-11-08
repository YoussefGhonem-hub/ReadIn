import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../domain/entities/legal.dart';
import '../../domain/usecases/legal_usecases.dart';

class AcceptTermsState extends Equatable {
  const AcceptTermsState({this.legal, this.accepting = false, this.failure});

  /// `GET /legal`: what changed; null while it loads or when it failed (the screen says it generically).
  final LegalInfo? legal;
  final bool accepting;
  final Failure? failure;

  AcceptTermsState copyWith({LegalInfo? legal, bool? accepting, Failure? Function()? failure}) => AcceptTermsState(
        legal: legal ?? this.legal,
        accepting: accepting ?? this.accepting,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  List<Object?> get props => [legal, accepting, failure];
}

/// The blocking terms screen (F37): what changed, then "I agree" (`POST /me/terms/accept`). The new `MeDto` reaches the
/// session, and the router moves on to the next guard or home.
@injectable
class AcceptTermsCubit extends Cubit<AcceptTermsState> {
  AcceptTermsCubit(this._getLegal, this._accept) : super(const AcceptTermsState());

  final GetLegal _getLegal;
  final AcceptTerms _accept;

  Future<void> load() async {
    final result = await _getLegal();
    if (isClosed) return;
    if (result case Ok(:final value)) emit(state.copyWith(legal: value));
  }

  /// Null once accepted, else why not.
  Future<Failure?> accept() async {
    if (state.accepting) return null;
    emit(state.copyWith(accepting: true, failure: () => null));
    final failure = (await _accept()).failureOrNull;
    if (!isClosed) emit(state.copyWith(accepting: false, failure: () => failure));
    return failure;
  }
}
