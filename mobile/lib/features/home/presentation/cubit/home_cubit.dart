import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../article/domain/entities/article.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/usecases/feed_usecases.dart';

class HomeState extends Equatable {
  const HomeState({this.loading = true, this.today, this.fields = const []});

  final bool loading;

  /// Today's article (F07); null when there is no pick yet or it failed —
  /// the hero simply hides, the feed stays usable.
  final ArticleCard? today;
  final List<Field> fields;

  @override
  List<Object?> get props => [loading, today, fields];
}

/// Header data for Home (F03): Today's article + field filter chips.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getToday, this._getFields) : super(const HomeState());

  final GetTodayArticle _getToday;
  final GetFields _getFields;

  Future<void> load({bool refresh = false}) async {
    if (!refresh) emit(const HomeState());
    final (today, fields) = await (_getToday(), _getFields(refresh: refresh)).wait;
    emit(HomeState(
      loading: false,
      today: today.valueOrNull,
      fields: fields.valueOrNull ?? state.fields,
    ));
  }
}
