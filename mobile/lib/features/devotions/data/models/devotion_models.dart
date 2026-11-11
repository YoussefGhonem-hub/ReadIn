import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/devotions.dart';

part 'devotion_models.freezed.dart';
part 'devotion_models.g.dart';

/// `PersonalDuaDto` (F38).
@freezed
abstract class PersonalDuaModel with _$PersonalDuaModel {
  const PersonalDuaModel._();

  const factory PersonalDuaModel({
    required String id,
    String? title,
    required String text,
    @Default(1) int repeat,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PersonalDuaModel;

  factory PersonalDuaModel.fromJson(Map<String, dynamic> json) => _$PersonalDuaModelFromJson(json);

  PersonalDua toEntity() =>
      PersonalDua(id: id, title: title, text: text, repeat: repeat, createdAt: createdAt, updatedAt: updatedAt);
}

/// The body of `POST /me/duas` and `PATCH /me/duas/{id}`: every field every time (an empty title clears it).
class DuaBody {
  const DuaBody({this.title, required this.text, this.repeat = 1});

  factory DuaBody.of(DuaDraft draft) => DuaBody(title: draft.title, text: draft.text, repeat: draft.repeat);

  final String? title;
  final String text;
  final int repeat;

  Map<String, dynamic> toJson() => {'title': title, 'text': text, 'repeat': repeat};
}
