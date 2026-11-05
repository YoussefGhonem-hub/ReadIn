// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'highlight_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HighlightModel {

 String get id; String get blockId; int get startOffset; int get endOffset; String get text; DateTime get createdAt;
/// Create a copy of HighlightModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HighlightModelCopyWith<HighlightModel> get copyWith => _$HighlightModelCopyWithImpl<HighlightModel>(this as HighlightModel, _$identity);

  /// Serializes this HighlightModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighlightModel&&(identical(other.id, id) || other.id == id)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,blockId,startOffset,endOffset,text,createdAt);

@override
String toString() {
  return 'HighlightModel(id: $id, blockId: $blockId, startOffset: $startOffset, endOffset: $endOffset, text: $text, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $HighlightModelCopyWith<$Res>  {
  factory $HighlightModelCopyWith(HighlightModel value, $Res Function(HighlightModel) _then) = _$HighlightModelCopyWithImpl;
@useResult
$Res call({
 String id, String blockId, int startOffset, int endOffset, String text, DateTime createdAt
});




}
/// @nodoc
class _$HighlightModelCopyWithImpl<$Res>
    implements $HighlightModelCopyWith<$Res> {
  _$HighlightModelCopyWithImpl(this._self, this._then);

  final HighlightModel _self;
  final $Res Function(HighlightModel) _then;

/// Create a copy of HighlightModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? blockId = null,Object? startOffset = null,Object? endOffset = null,Object? text = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [HighlightModel].
extension HighlightModelPatterns on HighlightModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HighlightModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HighlightModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HighlightModel value)  $default,){
final _that = this;
switch (_that) {
case _HighlightModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HighlightModel value)?  $default,){
final _that = this;
switch (_that) {
case _HighlightModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String blockId,  int startOffset,  int endOffset,  String text,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HighlightModel() when $default != null:
return $default(_that.id,_that.blockId,_that.startOffset,_that.endOffset,_that.text,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String blockId,  int startOffset,  int endOffset,  String text,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _HighlightModel():
return $default(_that.id,_that.blockId,_that.startOffset,_that.endOffset,_that.text,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String blockId,  int startOffset,  int endOffset,  String text,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HighlightModel() when $default != null:
return $default(_that.id,_that.blockId,_that.startOffset,_that.endOffset,_that.text,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HighlightModel extends HighlightModel {
  const _HighlightModel({required this.id, required this.blockId, required this.startOffset, required this.endOffset, required this.text, required this.createdAt}): super._();
  factory _HighlightModel.fromJson(Map<String, dynamic> json) => _$HighlightModelFromJson(json);

@override final  String id;
@override final  String blockId;
@override final  int startOffset;
@override final  int endOffset;
@override final  String text;
@override final  DateTime createdAt;

/// Create a copy of HighlightModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HighlightModelCopyWith<_HighlightModel> get copyWith => __$HighlightModelCopyWithImpl<_HighlightModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HighlightModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HighlightModel&&(identical(other.id, id) || other.id == id)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,blockId,startOffset,endOffset,text,createdAt);

@override
String toString() {
  return 'HighlightModel(id: $id, blockId: $blockId, startOffset: $startOffset, endOffset: $endOffset, text: $text, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HighlightModelCopyWith<$Res> implements $HighlightModelCopyWith<$Res> {
  factory _$HighlightModelCopyWith(_HighlightModel value, $Res Function(_HighlightModel) _then) = __$HighlightModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String blockId, int startOffset, int endOffset, String text, DateTime createdAt
});




}
/// @nodoc
class __$HighlightModelCopyWithImpl<$Res>
    implements _$HighlightModelCopyWith<$Res> {
  __$HighlightModelCopyWithImpl(this._self, this._then);

  final _HighlightModel _self;
  final $Res Function(_HighlightModel) _then;

/// Create a copy of HighlightModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? blockId = null,Object? startOffset = null,Object? endOffset = null,Object? text = null,Object? createdAt = null,}) {
  return _then(_HighlightModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$PopularHighlightModel {

 String get blockId; int get startOffset; int get endOffset; String get text; int get count;
/// Create a copy of PopularHighlightModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PopularHighlightModelCopyWith<PopularHighlightModel> get copyWith => _$PopularHighlightModelCopyWithImpl<PopularHighlightModel>(this as PopularHighlightModel, _$identity);

  /// Serializes this PopularHighlightModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PopularHighlightModel&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset)&&(identical(other.text, text) || other.text == text)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blockId,startOffset,endOffset,text,count);

@override
String toString() {
  return 'PopularHighlightModel(blockId: $blockId, startOffset: $startOffset, endOffset: $endOffset, text: $text, count: $count)';
}


}

/// @nodoc
abstract mixin class $PopularHighlightModelCopyWith<$Res>  {
  factory $PopularHighlightModelCopyWith(PopularHighlightModel value, $Res Function(PopularHighlightModel) _then) = _$PopularHighlightModelCopyWithImpl;
@useResult
$Res call({
 String blockId, int startOffset, int endOffset, String text, int count
});




}
/// @nodoc
class _$PopularHighlightModelCopyWithImpl<$Res>
    implements $PopularHighlightModelCopyWith<$Res> {
  _$PopularHighlightModelCopyWithImpl(this._self, this._then);

  final PopularHighlightModel _self;
  final $Res Function(PopularHighlightModel) _then;

/// Create a copy of PopularHighlightModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? blockId = null,Object? startOffset = null,Object? endOffset = null,Object? text = null,Object? count = null,}) {
  return _then(_self.copyWith(
blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PopularHighlightModel].
extension PopularHighlightModelPatterns on PopularHighlightModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PopularHighlightModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PopularHighlightModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PopularHighlightModel value)  $default,){
final _that = this;
switch (_that) {
case _PopularHighlightModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PopularHighlightModel value)?  $default,){
final _that = this;
switch (_that) {
case _PopularHighlightModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String blockId,  int startOffset,  int endOffset,  String text,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PopularHighlightModel() when $default != null:
return $default(_that.blockId,_that.startOffset,_that.endOffset,_that.text,_that.count);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String blockId,  int startOffset,  int endOffset,  String text,  int count)  $default,) {final _that = this;
switch (_that) {
case _PopularHighlightModel():
return $default(_that.blockId,_that.startOffset,_that.endOffset,_that.text,_that.count);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String blockId,  int startOffset,  int endOffset,  String text,  int count)?  $default,) {final _that = this;
switch (_that) {
case _PopularHighlightModel() when $default != null:
return $default(_that.blockId,_that.startOffset,_that.endOffset,_that.text,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PopularHighlightModel extends PopularHighlightModel {
  const _PopularHighlightModel({required this.blockId, required this.startOffset, required this.endOffset, required this.text, this.count = 0}): super._();
  factory _PopularHighlightModel.fromJson(Map<String, dynamic> json) => _$PopularHighlightModelFromJson(json);

@override final  String blockId;
@override final  int startOffset;
@override final  int endOffset;
@override final  String text;
@override@JsonKey() final  int count;

/// Create a copy of PopularHighlightModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PopularHighlightModelCopyWith<_PopularHighlightModel> get copyWith => __$PopularHighlightModelCopyWithImpl<_PopularHighlightModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PopularHighlightModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PopularHighlightModel&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset)&&(identical(other.text, text) || other.text == text)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,blockId,startOffset,endOffset,text,count);

@override
String toString() {
  return 'PopularHighlightModel(blockId: $blockId, startOffset: $startOffset, endOffset: $endOffset, text: $text, count: $count)';
}


}

/// @nodoc
abstract mixin class _$PopularHighlightModelCopyWith<$Res> implements $PopularHighlightModelCopyWith<$Res> {
  factory _$PopularHighlightModelCopyWith(_PopularHighlightModel value, $Res Function(_PopularHighlightModel) _then) = __$PopularHighlightModelCopyWithImpl;
@override @useResult
$Res call({
 String blockId, int startOffset, int endOffset, String text, int count
});




}
/// @nodoc
class __$PopularHighlightModelCopyWithImpl<$Res>
    implements _$PopularHighlightModelCopyWith<$Res> {
  __$PopularHighlightModelCopyWithImpl(this._self, this._then);

  final _PopularHighlightModel _self;
  final $Res Function(_PopularHighlightModel) _then;

/// Create a copy of PopularHighlightModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? blockId = null,Object? startOffset = null,Object? endOffset = null,Object? text = null,Object? count = null,}) {
  return _then(_PopularHighlightModel(
blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ArticleHighlightsModel {

 String get articleId; String get language; List<HighlightModel> get mine; List<PopularHighlightModel> get popular;
/// Create a copy of ArticleHighlightsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleHighlightsModelCopyWith<ArticleHighlightsModel> get copyWith => _$ArticleHighlightsModelCopyWithImpl<ArticleHighlightsModel>(this as ArticleHighlightsModel, _$identity);

  /// Serializes this ArticleHighlightsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleHighlightsModel&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.mine, mine)&&const DeepCollectionEquality().equals(other.popular, popular));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,articleId,language,const DeepCollectionEquality().hash(mine),const DeepCollectionEquality().hash(popular));

@override
String toString() {
  return 'ArticleHighlightsModel(articleId: $articleId, language: $language, mine: $mine, popular: $popular)';
}


}

/// @nodoc
abstract mixin class $ArticleHighlightsModelCopyWith<$Res>  {
  factory $ArticleHighlightsModelCopyWith(ArticleHighlightsModel value, $Res Function(ArticleHighlightsModel) _then) = _$ArticleHighlightsModelCopyWithImpl;
@useResult
$Res call({
 String articleId, String language, List<HighlightModel> mine, List<PopularHighlightModel> popular
});




}
/// @nodoc
class _$ArticleHighlightsModelCopyWithImpl<$Res>
    implements $ArticleHighlightsModelCopyWith<$Res> {
  _$ArticleHighlightsModelCopyWithImpl(this._self, this._then);

  final ArticleHighlightsModel _self;
  final $Res Function(ArticleHighlightsModel) _then;

/// Create a copy of ArticleHighlightsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? articleId = null,Object? language = null,Object? mine = null,Object? popular = null,}) {
  return _then(_self.copyWith(
articleId: null == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,mine: null == mine ? _self.mine : mine // ignore: cast_nullable_to_non_nullable
as List<HighlightModel>,popular: null == popular ? _self.popular : popular // ignore: cast_nullable_to_non_nullable
as List<PopularHighlightModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleHighlightsModel].
extension ArticleHighlightsModelPatterns on ArticleHighlightsModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleHighlightsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleHighlightsModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleHighlightsModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleHighlightsModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleHighlightsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleHighlightsModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String articleId,  String language,  List<HighlightModel> mine,  List<PopularHighlightModel> popular)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleHighlightsModel() when $default != null:
return $default(_that.articleId,_that.language,_that.mine,_that.popular);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String articleId,  String language,  List<HighlightModel> mine,  List<PopularHighlightModel> popular)  $default,) {final _that = this;
switch (_that) {
case _ArticleHighlightsModel():
return $default(_that.articleId,_that.language,_that.mine,_that.popular);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String articleId,  String language,  List<HighlightModel> mine,  List<PopularHighlightModel> popular)?  $default,) {final _that = this;
switch (_that) {
case _ArticleHighlightsModel() when $default != null:
return $default(_that.articleId,_that.language,_that.mine,_that.popular);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleHighlightsModel extends ArticleHighlightsModel {
  const _ArticleHighlightsModel({required this.articleId, required this.language, final  List<HighlightModel> mine = const <HighlightModel>[], final  List<PopularHighlightModel> popular = const <PopularHighlightModel>[]}): _mine = mine,_popular = popular,super._();
  factory _ArticleHighlightsModel.fromJson(Map<String, dynamic> json) => _$ArticleHighlightsModelFromJson(json);

@override final  String articleId;
@override final  String language;
 final  List<HighlightModel> _mine;
@override@JsonKey() List<HighlightModel> get mine {
  if (_mine is EqualUnmodifiableListView) return _mine;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mine);
}

 final  List<PopularHighlightModel> _popular;
@override@JsonKey() List<PopularHighlightModel> get popular {
  if (_popular is EqualUnmodifiableListView) return _popular;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_popular);
}


/// Create a copy of ArticleHighlightsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleHighlightsModelCopyWith<_ArticleHighlightsModel> get copyWith => __$ArticleHighlightsModelCopyWithImpl<_ArticleHighlightsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleHighlightsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleHighlightsModel&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other._mine, _mine)&&const DeepCollectionEquality().equals(other._popular, _popular));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,articleId,language,const DeepCollectionEquality().hash(_mine),const DeepCollectionEquality().hash(_popular));

@override
String toString() {
  return 'ArticleHighlightsModel(articleId: $articleId, language: $language, mine: $mine, popular: $popular)';
}


}

/// @nodoc
abstract mixin class _$ArticleHighlightsModelCopyWith<$Res> implements $ArticleHighlightsModelCopyWith<$Res> {
  factory _$ArticleHighlightsModelCopyWith(_ArticleHighlightsModel value, $Res Function(_ArticleHighlightsModel) _then) = __$ArticleHighlightsModelCopyWithImpl;
@override @useResult
$Res call({
 String articleId, String language, List<HighlightModel> mine, List<PopularHighlightModel> popular
});




}
/// @nodoc
class __$ArticleHighlightsModelCopyWithImpl<$Res>
    implements _$ArticleHighlightsModelCopyWith<$Res> {
  __$ArticleHighlightsModelCopyWithImpl(this._self, this._then);

  final _ArticleHighlightsModel _self;
  final $Res Function(_ArticleHighlightsModel) _then;

/// Create a copy of ArticleHighlightsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? articleId = null,Object? language = null,Object? mine = null,Object? popular = null,}) {
  return _then(_ArticleHighlightsModel(
articleId: null == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,mine: null == mine ? _self._mine : mine // ignore: cast_nullable_to_non_nullable
as List<HighlightModel>,popular: null == popular ? _self._popular : popular // ignore: cast_nullable_to_non_nullable
as List<PopularHighlightModel>,
  ));
}


}


/// @nodoc
mixin _$CreateHighlightRequest {

 String get language; String get blockId; int get startOffset; int get endOffset; String get text;
/// Create a copy of CreateHighlightRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateHighlightRequestCopyWith<CreateHighlightRequest> get copyWith => _$CreateHighlightRequestCopyWithImpl<CreateHighlightRequest>(this as CreateHighlightRequest, _$identity);

  /// Serializes this CreateHighlightRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateHighlightRequest&&(identical(other.language, language) || other.language == language)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,blockId,startOffset,endOffset,text);

@override
String toString() {
  return 'CreateHighlightRequest(language: $language, blockId: $blockId, startOffset: $startOffset, endOffset: $endOffset, text: $text)';
}


}

/// @nodoc
abstract mixin class $CreateHighlightRequestCopyWith<$Res>  {
  factory $CreateHighlightRequestCopyWith(CreateHighlightRequest value, $Res Function(CreateHighlightRequest) _then) = _$CreateHighlightRequestCopyWithImpl;
@useResult
$Res call({
 String language, String blockId, int startOffset, int endOffset, String text
});




}
/// @nodoc
class _$CreateHighlightRequestCopyWithImpl<$Res>
    implements $CreateHighlightRequestCopyWith<$Res> {
  _$CreateHighlightRequestCopyWithImpl(this._self, this._then);

  final CreateHighlightRequest _self;
  final $Res Function(CreateHighlightRequest) _then;

/// Create a copy of CreateHighlightRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? blockId = null,Object? startOffset = null,Object? endOffset = null,Object? text = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateHighlightRequest].
extension CreateHighlightRequestPatterns on CreateHighlightRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateHighlightRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateHighlightRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateHighlightRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreateHighlightRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateHighlightRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreateHighlightRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  String blockId,  int startOffset,  int endOffset,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateHighlightRequest() when $default != null:
return $default(_that.language,_that.blockId,_that.startOffset,_that.endOffset,_that.text);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  String blockId,  int startOffset,  int endOffset,  String text)  $default,) {final _that = this;
switch (_that) {
case _CreateHighlightRequest():
return $default(_that.language,_that.blockId,_that.startOffset,_that.endOffset,_that.text);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  String blockId,  int startOffset,  int endOffset,  String text)?  $default,) {final _that = this;
switch (_that) {
case _CreateHighlightRequest() when $default != null:
return $default(_that.language,_that.blockId,_that.startOffset,_that.endOffset,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateHighlightRequest implements CreateHighlightRequest {
  const _CreateHighlightRequest({required this.language, required this.blockId, required this.startOffset, required this.endOffset, required this.text});
  factory _CreateHighlightRequest.fromJson(Map<String, dynamic> json) => _$CreateHighlightRequestFromJson(json);

@override final  String language;
@override final  String blockId;
@override final  int startOffset;
@override final  int endOffset;
@override final  String text;

/// Create a copy of CreateHighlightRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateHighlightRequestCopyWith<_CreateHighlightRequest> get copyWith => __$CreateHighlightRequestCopyWithImpl<_CreateHighlightRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateHighlightRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateHighlightRequest&&(identical(other.language, language) || other.language == language)&&(identical(other.blockId, blockId) || other.blockId == blockId)&&(identical(other.startOffset, startOffset) || other.startOffset == startOffset)&&(identical(other.endOffset, endOffset) || other.endOffset == endOffset)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,blockId,startOffset,endOffset,text);

@override
String toString() {
  return 'CreateHighlightRequest(language: $language, blockId: $blockId, startOffset: $startOffset, endOffset: $endOffset, text: $text)';
}


}

/// @nodoc
abstract mixin class _$CreateHighlightRequestCopyWith<$Res> implements $CreateHighlightRequestCopyWith<$Res> {
  factory _$CreateHighlightRequestCopyWith(_CreateHighlightRequest value, $Res Function(_CreateHighlightRequest) _then) = __$CreateHighlightRequestCopyWithImpl;
@override @useResult
$Res call({
 String language, String blockId, int startOffset, int endOffset, String text
});




}
/// @nodoc
class __$CreateHighlightRequestCopyWithImpl<$Res>
    implements _$CreateHighlightRequestCopyWith<$Res> {
  __$CreateHighlightRequestCopyWithImpl(this._self, this._then);

  final _CreateHighlightRequest _self;
  final $Res Function(_CreateHighlightRequest) _then;

/// Create a copy of CreateHighlightRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? blockId = null,Object? startOffset = null,Object? endOffset = null,Object? text = null,}) {
  return _then(_CreateHighlightRequest(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,blockId: null == blockId ? _self.blockId : blockId // ignore: cast_nullable_to_non_nullable
as String,startOffset: null == startOffset ? _self.startOffset : startOffset // ignore: cast_nullable_to_non_nullable
as int,endOffset: null == endOffset ? _self.endOffset : endOffset // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$HighlightCreatedModel {

 HighlightModel get highlight; List<String> get replacedIds;
/// Create a copy of HighlightCreatedModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HighlightCreatedModelCopyWith<HighlightCreatedModel> get copyWith => _$HighlightCreatedModelCopyWithImpl<HighlightCreatedModel>(this as HighlightCreatedModel, _$identity);

  /// Serializes this HighlightCreatedModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighlightCreatedModel&&(identical(other.highlight, highlight) || other.highlight == highlight)&&const DeepCollectionEquality().equals(other.replacedIds, replacedIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,highlight,const DeepCollectionEquality().hash(replacedIds));

@override
String toString() {
  return 'HighlightCreatedModel(highlight: $highlight, replacedIds: $replacedIds)';
}


}

/// @nodoc
abstract mixin class $HighlightCreatedModelCopyWith<$Res>  {
  factory $HighlightCreatedModelCopyWith(HighlightCreatedModel value, $Res Function(HighlightCreatedModel) _then) = _$HighlightCreatedModelCopyWithImpl;
@useResult
$Res call({
 HighlightModel highlight, List<String> replacedIds
});


$HighlightModelCopyWith<$Res> get highlight;

}
/// @nodoc
class _$HighlightCreatedModelCopyWithImpl<$Res>
    implements $HighlightCreatedModelCopyWith<$Res> {
  _$HighlightCreatedModelCopyWithImpl(this._self, this._then);

  final HighlightCreatedModel _self;
  final $Res Function(HighlightCreatedModel) _then;

/// Create a copy of HighlightCreatedModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? highlight = null,Object? replacedIds = null,}) {
  return _then(_self.copyWith(
highlight: null == highlight ? _self.highlight : highlight // ignore: cast_nullable_to_non_nullable
as HighlightModel,replacedIds: null == replacedIds ? _self.replacedIds : replacedIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of HighlightCreatedModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HighlightModelCopyWith<$Res> get highlight {
  
  return $HighlightModelCopyWith<$Res>(_self.highlight, (value) {
    return _then(_self.copyWith(highlight: value));
  });
}
}


/// Adds pattern-matching-related methods to [HighlightCreatedModel].
extension HighlightCreatedModelPatterns on HighlightCreatedModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HighlightCreatedModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HighlightCreatedModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HighlightCreatedModel value)  $default,){
final _that = this;
switch (_that) {
case _HighlightCreatedModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HighlightCreatedModel value)?  $default,){
final _that = this;
switch (_that) {
case _HighlightCreatedModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HighlightModel highlight,  List<String> replacedIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HighlightCreatedModel() when $default != null:
return $default(_that.highlight,_that.replacedIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HighlightModel highlight,  List<String> replacedIds)  $default,) {final _that = this;
switch (_that) {
case _HighlightCreatedModel():
return $default(_that.highlight,_that.replacedIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HighlightModel highlight,  List<String> replacedIds)?  $default,) {final _that = this;
switch (_that) {
case _HighlightCreatedModel() when $default != null:
return $default(_that.highlight,_that.replacedIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HighlightCreatedModel extends HighlightCreatedModel {
  const _HighlightCreatedModel({required this.highlight, final  List<String> replacedIds = const <String>[]}): _replacedIds = replacedIds,super._();
  factory _HighlightCreatedModel.fromJson(Map<String, dynamic> json) => _$HighlightCreatedModelFromJson(json);

@override final  HighlightModel highlight;
 final  List<String> _replacedIds;
@override@JsonKey() List<String> get replacedIds {
  if (_replacedIds is EqualUnmodifiableListView) return _replacedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replacedIds);
}


/// Create a copy of HighlightCreatedModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HighlightCreatedModelCopyWith<_HighlightCreatedModel> get copyWith => __$HighlightCreatedModelCopyWithImpl<_HighlightCreatedModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HighlightCreatedModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HighlightCreatedModel&&(identical(other.highlight, highlight) || other.highlight == highlight)&&const DeepCollectionEquality().equals(other._replacedIds, _replacedIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,highlight,const DeepCollectionEquality().hash(_replacedIds));

@override
String toString() {
  return 'HighlightCreatedModel(highlight: $highlight, replacedIds: $replacedIds)';
}


}

/// @nodoc
abstract mixin class _$HighlightCreatedModelCopyWith<$Res> implements $HighlightCreatedModelCopyWith<$Res> {
  factory _$HighlightCreatedModelCopyWith(_HighlightCreatedModel value, $Res Function(_HighlightCreatedModel) _then) = __$HighlightCreatedModelCopyWithImpl;
@override @useResult
$Res call({
 HighlightModel highlight, List<String> replacedIds
});


@override $HighlightModelCopyWith<$Res> get highlight;

}
/// @nodoc
class __$HighlightCreatedModelCopyWithImpl<$Res>
    implements _$HighlightCreatedModelCopyWith<$Res> {
  __$HighlightCreatedModelCopyWithImpl(this._self, this._then);

  final _HighlightCreatedModel _self;
  final $Res Function(_HighlightCreatedModel) _then;

/// Create a copy of HighlightCreatedModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? highlight = null,Object? replacedIds = null,}) {
  return _then(_HighlightCreatedModel(
highlight: null == highlight ? _self.highlight : highlight // ignore: cast_nullable_to_non_nullable
as HighlightModel,replacedIds: null == replacedIds ? _self._replacedIds : replacedIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of HighlightCreatedModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HighlightModelCopyWith<$Res> get highlight {
  
  return $HighlightModelCopyWith<$Res>(_self.highlight, (value) {
    return _then(_self.copyWith(highlight: value));
  });
}
}


/// @nodoc
mixin _$HighlightArticleModel {

 String get id; String get slug; String get language; String get title; AuthorModel? get author;
/// Create a copy of HighlightArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HighlightArticleModelCopyWith<HighlightArticleModel> get copyWith => _$HighlightArticleModelCopyWithImpl<HighlightArticleModel>(this as HighlightArticleModel, _$identity);

  /// Serializes this HighlightArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighlightArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,language,title,author);

@override
String toString() {
  return 'HighlightArticleModel(id: $id, slug: $slug, language: $language, title: $title, author: $author)';
}


}

/// @nodoc
abstract mixin class $HighlightArticleModelCopyWith<$Res>  {
  factory $HighlightArticleModelCopyWith(HighlightArticleModel value, $Res Function(HighlightArticleModel) _then) = _$HighlightArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String language, String title, AuthorModel? author
});


$AuthorModelCopyWith<$Res>? get author;

}
/// @nodoc
class _$HighlightArticleModelCopyWithImpl<$Res>
    implements $HighlightArticleModelCopyWith<$Res> {
  _$HighlightArticleModelCopyWithImpl(this._self, this._then);

  final HighlightArticleModel _self;
  final $Res Function(HighlightArticleModel) _then;

/// Create a copy of HighlightArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? author = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,
  ));
}
/// Create a copy of HighlightArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $AuthorModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [HighlightArticleModel].
extension HighlightArticleModelPatterns on HighlightArticleModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HighlightArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HighlightArticleModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HighlightArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _HighlightArticleModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HighlightArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _HighlightArticleModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  AuthorModel? author)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HighlightArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.author);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String language,  String title,  AuthorModel? author)  $default,) {final _that = this;
switch (_that) {
case _HighlightArticleModel():
return $default(_that.id,_that.slug,_that.language,_that.title,_that.author);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String language,  String title,  AuthorModel? author)?  $default,) {final _that = this;
switch (_that) {
case _HighlightArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.language,_that.title,_that.author);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HighlightArticleModel extends HighlightArticleModel {
  const _HighlightArticleModel({required this.id, required this.slug, required this.language, required this.title, this.author}): super._();
  factory _HighlightArticleModel.fromJson(Map<String, dynamic> json) => _$HighlightArticleModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String language;
@override final  String title;
@override final  AuthorModel? author;

/// Create a copy of HighlightArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HighlightArticleModelCopyWith<_HighlightArticleModel> get copyWith => __$HighlightArticleModelCopyWithImpl<_HighlightArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HighlightArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HighlightArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,language,title,author);

@override
String toString() {
  return 'HighlightArticleModel(id: $id, slug: $slug, language: $language, title: $title, author: $author)';
}


}

/// @nodoc
abstract mixin class _$HighlightArticleModelCopyWith<$Res> implements $HighlightArticleModelCopyWith<$Res> {
  factory _$HighlightArticleModelCopyWith(_HighlightArticleModel value, $Res Function(_HighlightArticleModel) _then) = __$HighlightArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String language, String title, AuthorModel? author
});


@override $AuthorModelCopyWith<$Res>? get author;

}
/// @nodoc
class __$HighlightArticleModelCopyWithImpl<$Res>
    implements _$HighlightArticleModelCopyWith<$Res> {
  __$HighlightArticleModelCopyWithImpl(this._self, this._then);

  final _HighlightArticleModel _self;
  final $Res Function(_HighlightArticleModel) _then;

/// Create a copy of HighlightArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? language = null,Object? title = null,Object? author = freezed,}) {
  return _then(_HighlightArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,
  ));
}

/// Create a copy of HighlightArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $AuthorModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$HighlightGroupModel {

 HighlightArticleModel get article; List<HighlightModel> get highlights; DateTime get latestAt;
/// Create a copy of HighlightGroupModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HighlightGroupModelCopyWith<HighlightGroupModel> get copyWith => _$HighlightGroupModelCopyWithImpl<HighlightGroupModel>(this as HighlightGroupModel, _$identity);

  /// Serializes this HighlightGroupModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighlightGroupModel&&(identical(other.article, article) || other.article == article)&&const DeepCollectionEquality().equals(other.highlights, highlights)&&(identical(other.latestAt, latestAt) || other.latestAt == latestAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,const DeepCollectionEquality().hash(highlights),latestAt);

@override
String toString() {
  return 'HighlightGroupModel(article: $article, highlights: $highlights, latestAt: $latestAt)';
}


}

/// @nodoc
abstract mixin class $HighlightGroupModelCopyWith<$Res>  {
  factory $HighlightGroupModelCopyWith(HighlightGroupModel value, $Res Function(HighlightGroupModel) _then) = _$HighlightGroupModelCopyWithImpl;
@useResult
$Res call({
 HighlightArticleModel article, List<HighlightModel> highlights, DateTime latestAt
});


$HighlightArticleModelCopyWith<$Res> get article;

}
/// @nodoc
class _$HighlightGroupModelCopyWithImpl<$Res>
    implements $HighlightGroupModelCopyWith<$Res> {
  _$HighlightGroupModelCopyWithImpl(this._self, this._then);

  final HighlightGroupModel _self;
  final $Res Function(HighlightGroupModel) _then;

/// Create a copy of HighlightGroupModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? article = null,Object? highlights = null,Object? latestAt = null,}) {
  return _then(_self.copyWith(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as HighlightArticleModel,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<HighlightModel>,latestAt: null == latestAt ? _self.latestAt : latestAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of HighlightGroupModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HighlightArticleModelCopyWith<$Res> get article {
  
  return $HighlightArticleModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [HighlightGroupModel].
extension HighlightGroupModelPatterns on HighlightGroupModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HighlightGroupModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HighlightGroupModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HighlightGroupModel value)  $default,){
final _that = this;
switch (_that) {
case _HighlightGroupModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HighlightGroupModel value)?  $default,){
final _that = this;
switch (_that) {
case _HighlightGroupModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HighlightArticleModel article,  List<HighlightModel> highlights,  DateTime latestAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HighlightGroupModel() when $default != null:
return $default(_that.article,_that.highlights,_that.latestAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HighlightArticleModel article,  List<HighlightModel> highlights,  DateTime latestAt)  $default,) {final _that = this;
switch (_that) {
case _HighlightGroupModel():
return $default(_that.article,_that.highlights,_that.latestAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HighlightArticleModel article,  List<HighlightModel> highlights,  DateTime latestAt)?  $default,) {final _that = this;
switch (_that) {
case _HighlightGroupModel() when $default != null:
return $default(_that.article,_that.highlights,_that.latestAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HighlightGroupModel extends HighlightGroupModel {
  const _HighlightGroupModel({required this.article, final  List<HighlightModel> highlights = const <HighlightModel>[], required this.latestAt}): _highlights = highlights,super._();
  factory _HighlightGroupModel.fromJson(Map<String, dynamic> json) => _$HighlightGroupModelFromJson(json);

@override final  HighlightArticleModel article;
 final  List<HighlightModel> _highlights;
@override@JsonKey() List<HighlightModel> get highlights {
  if (_highlights is EqualUnmodifiableListView) return _highlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_highlights);
}

@override final  DateTime latestAt;

/// Create a copy of HighlightGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HighlightGroupModelCopyWith<_HighlightGroupModel> get copyWith => __$HighlightGroupModelCopyWithImpl<_HighlightGroupModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HighlightGroupModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HighlightGroupModel&&(identical(other.article, article) || other.article == article)&&const DeepCollectionEquality().equals(other._highlights, _highlights)&&(identical(other.latestAt, latestAt) || other.latestAt == latestAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,const DeepCollectionEquality().hash(_highlights),latestAt);

@override
String toString() {
  return 'HighlightGroupModel(article: $article, highlights: $highlights, latestAt: $latestAt)';
}


}

/// @nodoc
abstract mixin class _$HighlightGroupModelCopyWith<$Res> implements $HighlightGroupModelCopyWith<$Res> {
  factory _$HighlightGroupModelCopyWith(_HighlightGroupModel value, $Res Function(_HighlightGroupModel) _then) = __$HighlightGroupModelCopyWithImpl;
@override @useResult
$Res call({
 HighlightArticleModel article, List<HighlightModel> highlights, DateTime latestAt
});


@override $HighlightArticleModelCopyWith<$Res> get article;

}
/// @nodoc
class __$HighlightGroupModelCopyWithImpl<$Res>
    implements _$HighlightGroupModelCopyWith<$Res> {
  __$HighlightGroupModelCopyWithImpl(this._self, this._then);

  final _HighlightGroupModel _self;
  final $Res Function(_HighlightGroupModel) _then;

/// Create a copy of HighlightGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? article = null,Object? highlights = null,Object? latestAt = null,}) {
  return _then(_HighlightGroupModel(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as HighlightArticleModel,highlights: null == highlights ? _self._highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<HighlightModel>,latestAt: null == latestAt ? _self.latestAt : latestAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of HighlightGroupModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HighlightArticleModelCopyWith<$Res> get article {
  
  return $HighlightArticleModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// @nodoc
mixin _$HighlightGroupPageModel {

 List<HighlightGroupModel> get items; String? get nextCursor;
/// Create a copy of HighlightGroupPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HighlightGroupPageModelCopyWith<HighlightGroupPageModel> get copyWith => _$HighlightGroupPageModelCopyWithImpl<HighlightGroupPageModel>(this as HighlightGroupPageModel, _$identity);

  /// Serializes this HighlightGroupPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighlightGroupPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'HighlightGroupPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $HighlightGroupPageModelCopyWith<$Res>  {
  factory $HighlightGroupPageModelCopyWith(HighlightGroupPageModel value, $Res Function(HighlightGroupPageModel) _then) = _$HighlightGroupPageModelCopyWithImpl;
@useResult
$Res call({
 List<HighlightGroupModel> items, String? nextCursor
});




}
/// @nodoc
class _$HighlightGroupPageModelCopyWithImpl<$Res>
    implements $HighlightGroupPageModelCopyWith<$Res> {
  _$HighlightGroupPageModelCopyWithImpl(this._self, this._then);

  final HighlightGroupPageModel _self;
  final $Res Function(HighlightGroupPageModel) _then;

/// Create a copy of HighlightGroupPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<HighlightGroupModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HighlightGroupPageModel].
extension HighlightGroupPageModelPatterns on HighlightGroupPageModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HighlightGroupPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HighlightGroupPageModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HighlightGroupPageModel value)  $default,){
final _that = this;
switch (_that) {
case _HighlightGroupPageModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HighlightGroupPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _HighlightGroupPageModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HighlightGroupModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HighlightGroupPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HighlightGroupModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _HighlightGroupPageModel():
return $default(_that.items,_that.nextCursor);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HighlightGroupModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _HighlightGroupPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HighlightGroupPageModel implements HighlightGroupPageModel {
  const _HighlightGroupPageModel({final  List<HighlightGroupModel> items = const <HighlightGroupModel>[], this.nextCursor}): _items = items;
  factory _HighlightGroupPageModel.fromJson(Map<String, dynamic> json) => _$HighlightGroupPageModelFromJson(json);

 final  List<HighlightGroupModel> _items;
@override@JsonKey() List<HighlightGroupModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of HighlightGroupPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HighlightGroupPageModelCopyWith<_HighlightGroupPageModel> get copyWith => __$HighlightGroupPageModelCopyWithImpl<_HighlightGroupPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HighlightGroupPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HighlightGroupPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'HighlightGroupPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$HighlightGroupPageModelCopyWith<$Res> implements $HighlightGroupPageModelCopyWith<$Res> {
  factory _$HighlightGroupPageModelCopyWith(_HighlightGroupPageModel value, $Res Function(_HighlightGroupPageModel) _then) = __$HighlightGroupPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<HighlightGroupModel> items, String? nextCursor
});




}
/// @nodoc
class __$HighlightGroupPageModelCopyWithImpl<$Res>
    implements _$HighlightGroupPageModelCopyWith<$Res> {
  __$HighlightGroupPageModelCopyWithImpl(this._self, this._then);

  final _HighlightGroupPageModel _self;
  final $Res Function(_HighlightGroupPageModel) _then;

/// Create a copy of HighlightGroupPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_HighlightGroupPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<HighlightGroupModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
