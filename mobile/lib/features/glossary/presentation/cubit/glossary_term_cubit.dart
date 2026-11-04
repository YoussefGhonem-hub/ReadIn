import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/glossary_term.dart';
import '../../domain/usecases/get_glossary_term.dart';

/// [notFound]: the term isn't in the glossary yet (`404 glossary.term_not_found`), which is not an error to retry.
enum GlossaryTermStatus { loading, ready, notFound, failure }

class GlossaryTermState extends Equatable {
  const GlossaryTermState({this.status = GlossaryTermStatus.loading, this.term, this.failure});

  final GlossaryTermStatus status;
  final GlossaryTerm? term;
  final Failure? failure;

  @override
  List<Object?> get props => [status, term, failure];
}

/// The glossary sheet of one tapped term (F21).
@injectable
class GlossaryTermCubit extends Cubit<GlossaryTermState> {
  GlossaryTermCubit(this._getTerm) : super(const GlossaryTermState());

  final GetGlossaryTerm _getTerm;
  String? _slug;
  String? _language;

  /// Loads [slug] (the RDoc `termId`) for the article version [language].
  Future<void> load(String slug, {required String language}) async {
    _slug = slug;
    _language = language;
    emit(const GlossaryTermState());
    // A term node without an id can't be in the glossary.
    if (slug.trim().isEmpty) {
      emit(const GlossaryTermState(status: GlossaryTermStatus.notFound));
      return;
    }
    final result = await _getTerm(slug, language: language);
    if (isClosed) return;
    emit(result.fold(
      (failure) => _isNotFound(failure)
          ? const GlossaryTermState(status: GlossaryTermStatus.notFound)
          : GlossaryTermState(status: GlossaryTermStatus.failure, failure: failure),
      (term) => GlossaryTermState(status: GlossaryTermStatus.ready, term: term),
    ));
  }

  Future<void> retry() async {
    if (_slug != null) await load(_slug!, language: _language!);
  }

  static bool _isNotFound(Failure failure) =>
      failure.code == FailureCodes.glossaryTermNotFound || failure.statusCode == 404;
}
