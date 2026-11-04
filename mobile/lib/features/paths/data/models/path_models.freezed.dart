// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'path_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PathArticleRefModel {

 String get id; String get slug; String get title; String get language; int get position; int get readingTimeMinutes;
/// Create a copy of PathArticleRefModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathArticleRefModelCopyWith<PathArticleRefModel> get copyWith => _$PathArticleRefModelCopyWithImpl<PathArticleRefModel>(this as PathArticleRefModel, _$identity);

  /// Serializes this PathArticleRefModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathArticleRefModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.position, position) || other.position == position)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language,position,readingTimeMinutes);

@override
String toString() {
  return 'PathArticleRefModel(id: $id, slug: $slug, title: $title, language: $language, position: $position, readingTimeMinutes: $readingTimeMinutes)';
}


}

/// @nodoc
abstract mixin class $PathArticleRefModelCopyWith<$Res>  {
  factory $PathArticleRefModelCopyWith(PathArticleRefModel value, $Res Function(PathArticleRefModel) _then) = _$PathArticleRefModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String language, int position, int readingTimeMinutes
});




}
/// @nodoc
class _$PathArticleRefModelCopyWithImpl<$Res>
    implements $PathArticleRefModelCopyWith<$Res> {
  _$PathArticleRefModelCopyWithImpl(this._self, this._then);

  final PathArticleRefModel _self;
  final $Res Function(PathArticleRefModel) _then;

/// Create a copy of PathArticleRefModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,Object? position = null,Object? readingTimeMinutes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PathArticleRefModel].
extension PathArticleRefModelPatterns on PathArticleRefModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathArticleRefModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathArticleRefModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathArticleRefModel value)  $default,){
final _that = this;
switch (_that) {
case _PathArticleRefModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathArticleRefModel value)?  $default,){
final _that = this;
switch (_that) {
case _PathArticleRefModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language,  int position,  int readingTimeMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathArticleRefModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language,_that.position,_that.readingTimeMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language,  int position,  int readingTimeMinutes)  $default,) {final _that = this;
switch (_that) {
case _PathArticleRefModel():
return $default(_that.id,_that.slug,_that.title,_that.language,_that.position,_that.readingTimeMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String language,  int position,  int readingTimeMinutes)?  $default,) {final _that = this;
switch (_that) {
case _PathArticleRefModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language,_that.position,_that.readingTimeMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathArticleRefModel extends PathArticleRefModel {
  const _PathArticleRefModel({required this.id, required this.slug, required this.title, required this.language, required this.position, this.readingTimeMinutes = 1}): super._();
  factory _PathArticleRefModel.fromJson(Map<String, dynamic> json) => _$PathArticleRefModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;
@override final  String language;
@override final  int position;
@override@JsonKey() final  int readingTimeMinutes;

/// Create a copy of PathArticleRefModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathArticleRefModelCopyWith<_PathArticleRefModel> get copyWith => __$PathArticleRefModelCopyWithImpl<_PathArticleRefModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathArticleRefModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathArticleRefModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.position, position) || other.position == position)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language,position,readingTimeMinutes);

@override
String toString() {
  return 'PathArticleRefModel(id: $id, slug: $slug, title: $title, language: $language, position: $position, readingTimeMinutes: $readingTimeMinutes)';
}


}

/// @nodoc
abstract mixin class _$PathArticleRefModelCopyWith<$Res> implements $PathArticleRefModelCopyWith<$Res> {
  factory _$PathArticleRefModelCopyWith(_PathArticleRefModel value, $Res Function(_PathArticleRefModel) _then) = __$PathArticleRefModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String language, int position, int readingTimeMinutes
});




}
/// @nodoc
class __$PathArticleRefModelCopyWithImpl<$Res>
    implements _$PathArticleRefModelCopyWith<$Res> {
  __$PathArticleRefModelCopyWithImpl(this._self, this._then);

  final _PathArticleRefModel _self;
  final $Res Function(_PathArticleRefModel) _then;

/// Create a copy of PathArticleRefModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,Object? position = null,Object? readingTimeMinutes = null,}) {
  return _then(_PathArticleRefModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PathProgressModel {

 int get readCount; int get total; int get percent; PathArticleRefModel? get next;
/// Create a copy of PathProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathProgressModelCopyWith<PathProgressModel> get copyWith => _$PathProgressModelCopyWithImpl<PathProgressModel>(this as PathProgressModel, _$identity);

  /// Serializes this PathProgressModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathProgressModel&&(identical(other.readCount, readCount) || other.readCount == readCount)&&(identical(other.total, total) || other.total == total)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.next, next) || other.next == next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,readCount,total,percent,next);

@override
String toString() {
  return 'PathProgressModel(readCount: $readCount, total: $total, percent: $percent, next: $next)';
}


}

/// @nodoc
abstract mixin class $PathProgressModelCopyWith<$Res>  {
  factory $PathProgressModelCopyWith(PathProgressModel value, $Res Function(PathProgressModel) _then) = _$PathProgressModelCopyWithImpl;
@useResult
$Res call({
 int readCount, int total, int percent, PathArticleRefModel? next
});


$PathArticleRefModelCopyWith<$Res>? get next;

}
/// @nodoc
class _$PathProgressModelCopyWithImpl<$Res>
    implements $PathProgressModelCopyWith<$Res> {
  _$PathProgressModelCopyWithImpl(this._self, this._then);

  final PathProgressModel _self;
  final $Res Function(PathProgressModel) _then;

/// Create a copy of PathProgressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readCount = null,Object? total = null,Object? percent = null,Object? next = freezed,}) {
  return _then(_self.copyWith(
readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PathArticleRefModel?,
  ));
}
/// Create a copy of PathProgressModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathArticleRefModelCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $PathArticleRefModelCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}


/// Adds pattern-matching-related methods to [PathProgressModel].
extension PathProgressModelPatterns on PathProgressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathProgressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathProgressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathProgressModel value)  $default,){
final _that = this;
switch (_that) {
case _PathProgressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathProgressModel value)?  $default,){
final _that = this;
switch (_that) {
case _PathProgressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int readCount,  int total,  int percent,  PathArticleRefModel? next)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathProgressModel() when $default != null:
return $default(_that.readCount,_that.total,_that.percent,_that.next);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int readCount,  int total,  int percent,  PathArticleRefModel? next)  $default,) {final _that = this;
switch (_that) {
case _PathProgressModel():
return $default(_that.readCount,_that.total,_that.percent,_that.next);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int readCount,  int total,  int percent,  PathArticleRefModel? next)?  $default,) {final _that = this;
switch (_that) {
case _PathProgressModel() when $default != null:
return $default(_that.readCount,_that.total,_that.percent,_that.next);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathProgressModel extends PathProgressModel {
  const _PathProgressModel({this.readCount = 0, this.total = 0, this.percent = 0, this.next}): super._();
  factory _PathProgressModel.fromJson(Map<String, dynamic> json) => _$PathProgressModelFromJson(json);

@override@JsonKey() final  int readCount;
@override@JsonKey() final  int total;
@override@JsonKey() final  int percent;
@override final  PathArticleRefModel? next;

/// Create a copy of PathProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathProgressModelCopyWith<_PathProgressModel> get copyWith => __$PathProgressModelCopyWithImpl<_PathProgressModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathProgressModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathProgressModel&&(identical(other.readCount, readCount) || other.readCount == readCount)&&(identical(other.total, total) || other.total == total)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.next, next) || other.next == next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,readCount,total,percent,next);

@override
String toString() {
  return 'PathProgressModel(readCount: $readCount, total: $total, percent: $percent, next: $next)';
}


}

/// @nodoc
abstract mixin class _$PathProgressModelCopyWith<$Res> implements $PathProgressModelCopyWith<$Res> {
  factory _$PathProgressModelCopyWith(_PathProgressModel value, $Res Function(_PathProgressModel) _then) = __$PathProgressModelCopyWithImpl;
@override @useResult
$Res call({
 int readCount, int total, int percent, PathArticleRefModel? next
});


@override $PathArticleRefModelCopyWith<$Res>? get next;

}
/// @nodoc
class __$PathProgressModelCopyWithImpl<$Res>
    implements _$PathProgressModelCopyWith<$Res> {
  __$PathProgressModelCopyWithImpl(this._self, this._then);

  final _PathProgressModel _self;
  final $Res Function(_PathProgressModel) _then;

/// Create a copy of PathProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readCount = null,Object? total = null,Object? percent = null,Object? next = freezed,}) {
  return _then(_PathProgressModel(
readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PathArticleRefModel?,
  ));
}

/// Create a copy of PathProgressModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathArticleRefModelCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $PathArticleRefModelCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}


/// @nodoc
mixin _$PathEnrollmentModel {

 DateTime get enrolledAt; DateTime? get completedAt;
/// Create a copy of PathEnrollmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathEnrollmentModelCopyWith<PathEnrollmentModel> get copyWith => _$PathEnrollmentModelCopyWithImpl<PathEnrollmentModel>(this as PathEnrollmentModel, _$identity);

  /// Serializes this PathEnrollmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathEnrollmentModel&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrolledAt,completedAt);

@override
String toString() {
  return 'PathEnrollmentModel(enrolledAt: $enrolledAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $PathEnrollmentModelCopyWith<$Res>  {
  factory $PathEnrollmentModelCopyWith(PathEnrollmentModel value, $Res Function(PathEnrollmentModel) _then) = _$PathEnrollmentModelCopyWithImpl;
@useResult
$Res call({
 DateTime enrolledAt, DateTime? completedAt
});




}
/// @nodoc
class _$PathEnrollmentModelCopyWithImpl<$Res>
    implements $PathEnrollmentModelCopyWith<$Res> {
  _$PathEnrollmentModelCopyWithImpl(this._self, this._then);

  final PathEnrollmentModel _self;
  final $Res Function(PathEnrollmentModel) _then;

/// Create a copy of PathEnrollmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrolledAt = null,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
enrolledAt: null == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PathEnrollmentModel].
extension PathEnrollmentModelPatterns on PathEnrollmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathEnrollmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathEnrollmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathEnrollmentModel value)  $default,){
final _that = this;
switch (_that) {
case _PathEnrollmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathEnrollmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _PathEnrollmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime enrolledAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathEnrollmentModel() when $default != null:
return $default(_that.enrolledAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime enrolledAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _PathEnrollmentModel():
return $default(_that.enrolledAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime enrolledAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _PathEnrollmentModel() when $default != null:
return $default(_that.enrolledAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathEnrollmentModel extends PathEnrollmentModel {
  const _PathEnrollmentModel({required this.enrolledAt, this.completedAt}): super._();
  factory _PathEnrollmentModel.fromJson(Map<String, dynamic> json) => _$PathEnrollmentModelFromJson(json);

@override final  DateTime enrolledAt;
@override final  DateTime? completedAt;

/// Create a copy of PathEnrollmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathEnrollmentModelCopyWith<_PathEnrollmentModel> get copyWith => __$PathEnrollmentModelCopyWithImpl<_PathEnrollmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathEnrollmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathEnrollmentModel&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrolledAt,completedAt);

@override
String toString() {
  return 'PathEnrollmentModel(enrolledAt: $enrolledAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$PathEnrollmentModelCopyWith<$Res> implements $PathEnrollmentModelCopyWith<$Res> {
  factory _$PathEnrollmentModelCopyWith(_PathEnrollmentModel value, $Res Function(_PathEnrollmentModel) _then) = __$PathEnrollmentModelCopyWithImpl;
@override @useResult
$Res call({
 DateTime enrolledAt, DateTime? completedAt
});




}
/// @nodoc
class __$PathEnrollmentModelCopyWithImpl<$Res>
    implements _$PathEnrollmentModelCopyWith<$Res> {
  __$PathEnrollmentModelCopyWithImpl(this._self, this._then);

  final _PathEnrollmentModel _self;
  final $Res Function(_PathEnrollmentModel) _then;

/// Create a copy of PathEnrollmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrolledAt = null,Object? completedAt = freezed,}) {
  return _then(_PathEnrollmentModel(
enrolledAt: null == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PathCardModel {

 String get id; String get slug; String get title; String? get description; FieldRefModel get field; int get articleCount; int get readingTimeMinutes; String? get coverUrl; PathProgressModel? get progress; PathEnrollmentModel? get enrollment;
/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathCardModelCopyWith<PathCardModel> get copyWith => _$PathCardModelCopyWithImpl<PathCardModel>(this as PathCardModel, _$identity);

  /// Serializes this PathCardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.field, field) || other.field == field)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,description,field,articleCount,readingTimeMinutes,coverUrl,progress,enrollment);

@override
String toString() {
  return 'PathCardModel(id: $id, slug: $slug, title: $title, description: $description, field: $field, articleCount: $articleCount, readingTimeMinutes: $readingTimeMinutes, coverUrl: $coverUrl, progress: $progress, enrollment: $enrollment)';
}


}

/// @nodoc
abstract mixin class $PathCardModelCopyWith<$Res>  {
  factory $PathCardModelCopyWith(PathCardModel value, $Res Function(PathCardModel) _then) = _$PathCardModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String? description, FieldRefModel field, int articleCount, int readingTimeMinutes, String? coverUrl, PathProgressModel? progress, PathEnrollmentModel? enrollment
});


$FieldRefModelCopyWith<$Res> get field;$PathProgressModelCopyWith<$Res>? get progress;$PathEnrollmentModelCopyWith<$Res>? get enrollment;

}
/// @nodoc
class _$PathCardModelCopyWithImpl<$Res>
    implements $PathCardModelCopyWith<$Res> {
  _$PathCardModelCopyWithImpl(this._self, this._then);

  final PathCardModel _self;
  final $Res Function(PathCardModel) _then;

/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = freezed,Object? field = null,Object? articleCount = null,Object? readingTimeMinutes = null,Object? coverUrl = freezed,Object? progress = freezed,Object? enrollment = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as PathProgressModel?,enrollment: freezed == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as PathEnrollmentModel?,
  ));
}
/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathProgressModelCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $PathProgressModelCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathEnrollmentModelCopyWith<$Res>? get enrollment {
    if (_self.enrollment == null) {
    return null;
  }

  return $PathEnrollmentModelCopyWith<$Res>(_self.enrollment!, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}
}


/// Adds pattern-matching-related methods to [PathCardModel].
extension PathCardModelPatterns on PathCardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathCardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathCardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathCardModel value)  $default,){
final _that = this;
switch (_that) {
case _PathCardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathCardModel value)?  $default,){
final _that = this;
switch (_that) {
case _PathCardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String? description,  FieldRefModel field,  int articleCount,  int readingTimeMinutes,  String? coverUrl,  PathProgressModel? progress,  PathEnrollmentModel? enrollment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathCardModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.description,_that.field,_that.articleCount,_that.readingTimeMinutes,_that.coverUrl,_that.progress,_that.enrollment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String? description,  FieldRefModel field,  int articleCount,  int readingTimeMinutes,  String? coverUrl,  PathProgressModel? progress,  PathEnrollmentModel? enrollment)  $default,) {final _that = this;
switch (_that) {
case _PathCardModel():
return $default(_that.id,_that.slug,_that.title,_that.description,_that.field,_that.articleCount,_that.readingTimeMinutes,_that.coverUrl,_that.progress,_that.enrollment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String? description,  FieldRefModel field,  int articleCount,  int readingTimeMinutes,  String? coverUrl,  PathProgressModel? progress,  PathEnrollmentModel? enrollment)?  $default,) {final _that = this;
switch (_that) {
case _PathCardModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.description,_that.field,_that.articleCount,_that.readingTimeMinutes,_that.coverUrl,_that.progress,_that.enrollment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathCardModel extends PathCardModel {
  const _PathCardModel({required this.id, required this.slug, required this.title, this.description, required this.field, this.articleCount = 0, this.readingTimeMinutes = 0, this.coverUrl, this.progress, this.enrollment}): super._();
  factory _PathCardModel.fromJson(Map<String, dynamic> json) => _$PathCardModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;
@override final  String? description;
@override final  FieldRefModel field;
@override@JsonKey() final  int articleCount;
@override@JsonKey() final  int readingTimeMinutes;
@override final  String? coverUrl;
@override final  PathProgressModel? progress;
@override final  PathEnrollmentModel? enrollment;

/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathCardModelCopyWith<_PathCardModel> get copyWith => __$PathCardModelCopyWithImpl<_PathCardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathCardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathCardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.field, field) || other.field == field)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,description,field,articleCount,readingTimeMinutes,coverUrl,progress,enrollment);

@override
String toString() {
  return 'PathCardModel(id: $id, slug: $slug, title: $title, description: $description, field: $field, articleCount: $articleCount, readingTimeMinutes: $readingTimeMinutes, coverUrl: $coverUrl, progress: $progress, enrollment: $enrollment)';
}


}

/// @nodoc
abstract mixin class _$PathCardModelCopyWith<$Res> implements $PathCardModelCopyWith<$Res> {
  factory _$PathCardModelCopyWith(_PathCardModel value, $Res Function(_PathCardModel) _then) = __$PathCardModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String? description, FieldRefModel field, int articleCount, int readingTimeMinutes, String? coverUrl, PathProgressModel? progress, PathEnrollmentModel? enrollment
});


@override $FieldRefModelCopyWith<$Res> get field;@override $PathProgressModelCopyWith<$Res>? get progress;@override $PathEnrollmentModelCopyWith<$Res>? get enrollment;

}
/// @nodoc
class __$PathCardModelCopyWithImpl<$Res>
    implements _$PathCardModelCopyWith<$Res> {
  __$PathCardModelCopyWithImpl(this._self, this._then);

  final _PathCardModel _self;
  final $Res Function(_PathCardModel) _then;

/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = freezed,Object? field = null,Object? articleCount = null,Object? readingTimeMinutes = null,Object? coverUrl = freezed,Object? progress = freezed,Object? enrollment = freezed,}) {
  return _then(_PathCardModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as PathProgressModel?,enrollment: freezed == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as PathEnrollmentModel?,
  ));
}

/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathProgressModelCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $PathProgressModelCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of PathCardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathEnrollmentModelCopyWith<$Res>? get enrollment {
    if (_self.enrollment == null) {
    return null;
  }

  return $PathEnrollmentModelCopyWith<$Res>(_self.enrollment!, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}
}


/// @nodoc
mixin _$PathItemModel {

 int get position; ArticleCardModel get article; bool get isRead;
/// Create a copy of PathItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathItemModelCopyWith<PathItemModel> get copyWith => _$PathItemModelCopyWithImpl<PathItemModel>(this as PathItemModel, _$identity);

  /// Serializes this PathItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathItemModel&&(identical(other.position, position) || other.position == position)&&(identical(other.article, article) || other.article == article)&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,article,isRead);

@override
String toString() {
  return 'PathItemModel(position: $position, article: $article, isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class $PathItemModelCopyWith<$Res>  {
  factory $PathItemModelCopyWith(PathItemModel value, $Res Function(PathItemModel) _then) = _$PathItemModelCopyWithImpl;
@useResult
$Res call({
 int position, ArticleCardModel article, bool isRead
});


$ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class _$PathItemModelCopyWithImpl<$Res>
    implements $PathItemModelCopyWith<$Res> {
  _$PathItemModelCopyWithImpl(this._self, this._then);

  final PathItemModel _self;
  final $Res Function(PathItemModel) _then;

/// Create a copy of PathItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? article = null,Object? isRead = null,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PathItemModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res> get article {
  
  return $ArticleCardModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [PathItemModel].
extension PathItemModelPatterns on PathItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathItemModel value)  $default,){
final _that = this;
switch (_that) {
case _PathItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _PathItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int position,  ArticleCardModel article,  bool isRead)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathItemModel() when $default != null:
return $default(_that.position,_that.article,_that.isRead);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int position,  ArticleCardModel article,  bool isRead)  $default,) {final _that = this;
switch (_that) {
case _PathItemModel():
return $default(_that.position,_that.article,_that.isRead);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int position,  ArticleCardModel article,  bool isRead)?  $default,) {final _that = this;
switch (_that) {
case _PathItemModel() when $default != null:
return $default(_that.position,_that.article,_that.isRead);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathItemModel extends PathItemModel {
  const _PathItemModel({required this.position, required this.article, this.isRead = false}): super._();
  factory _PathItemModel.fromJson(Map<String, dynamic> json) => _$PathItemModelFromJson(json);

@override final  int position;
@override final  ArticleCardModel article;
@override@JsonKey() final  bool isRead;

/// Create a copy of PathItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathItemModelCopyWith<_PathItemModel> get copyWith => __$PathItemModelCopyWithImpl<_PathItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathItemModel&&(identical(other.position, position) || other.position == position)&&(identical(other.article, article) || other.article == article)&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,article,isRead);

@override
String toString() {
  return 'PathItemModel(position: $position, article: $article, isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class _$PathItemModelCopyWith<$Res> implements $PathItemModelCopyWith<$Res> {
  factory _$PathItemModelCopyWith(_PathItemModel value, $Res Function(_PathItemModel) _then) = __$PathItemModelCopyWithImpl;
@override @useResult
$Res call({
 int position, ArticleCardModel article, bool isRead
});


@override $ArticleCardModelCopyWith<$Res> get article;

}
/// @nodoc
class __$PathItemModelCopyWithImpl<$Res>
    implements _$PathItemModelCopyWith<$Res> {
  __$PathItemModelCopyWithImpl(this._self, this._then);

  final _PathItemModel _self;
  final $Res Function(_PathItemModel) _then;

/// Create a copy of PathItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? article = null,Object? isRead = null,}) {
  return _then(_PathItemModel(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleCardModel,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PathItemModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res> get article {
  
  return $ArticleCardModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// @nodoc
mixin _$PathDetailsModel {

 String get id; String get slug; String get title; String? get description; FieldRefModel get field; int get articleCount; int get readingTimeMinutes; String? get coverUrl; PathProgressModel? get progress; PathEnrollmentModel? get enrollment; List<PathItemModel> get items;
/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathDetailsModelCopyWith<PathDetailsModel> get copyWith => _$PathDetailsModelCopyWithImpl<PathDetailsModel>(this as PathDetailsModel, _$identity);

  /// Serializes this PathDetailsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathDetailsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.field, field) || other.field == field)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,description,field,articleCount,readingTimeMinutes,coverUrl,progress,enrollment,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'PathDetailsModel(id: $id, slug: $slug, title: $title, description: $description, field: $field, articleCount: $articleCount, readingTimeMinutes: $readingTimeMinutes, coverUrl: $coverUrl, progress: $progress, enrollment: $enrollment, items: $items)';
}


}

/// @nodoc
abstract mixin class $PathDetailsModelCopyWith<$Res>  {
  factory $PathDetailsModelCopyWith(PathDetailsModel value, $Res Function(PathDetailsModel) _then) = _$PathDetailsModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String? description, FieldRefModel field, int articleCount, int readingTimeMinutes, String? coverUrl, PathProgressModel? progress, PathEnrollmentModel? enrollment, List<PathItemModel> items
});


$FieldRefModelCopyWith<$Res> get field;$PathProgressModelCopyWith<$Res>? get progress;$PathEnrollmentModelCopyWith<$Res>? get enrollment;

}
/// @nodoc
class _$PathDetailsModelCopyWithImpl<$Res>
    implements $PathDetailsModelCopyWith<$Res> {
  _$PathDetailsModelCopyWithImpl(this._self, this._then);

  final PathDetailsModel _self;
  final $Res Function(PathDetailsModel) _then;

/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = freezed,Object? field = null,Object? articleCount = null,Object? readingTimeMinutes = null,Object? coverUrl = freezed,Object? progress = freezed,Object? enrollment = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as PathProgressModel?,enrollment: freezed == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as PathEnrollmentModel?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PathItemModel>,
  ));
}
/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathProgressModelCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $PathProgressModelCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathEnrollmentModelCopyWith<$Res>? get enrollment {
    if (_self.enrollment == null) {
    return null;
  }

  return $PathEnrollmentModelCopyWith<$Res>(_self.enrollment!, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}
}


/// Adds pattern-matching-related methods to [PathDetailsModel].
extension PathDetailsModelPatterns on PathDetailsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathDetailsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathDetailsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathDetailsModel value)  $default,){
final _that = this;
switch (_that) {
case _PathDetailsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathDetailsModel value)?  $default,){
final _that = this;
switch (_that) {
case _PathDetailsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String? description,  FieldRefModel field,  int articleCount,  int readingTimeMinutes,  String? coverUrl,  PathProgressModel? progress,  PathEnrollmentModel? enrollment,  List<PathItemModel> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathDetailsModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.description,_that.field,_that.articleCount,_that.readingTimeMinutes,_that.coverUrl,_that.progress,_that.enrollment,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String? description,  FieldRefModel field,  int articleCount,  int readingTimeMinutes,  String? coverUrl,  PathProgressModel? progress,  PathEnrollmentModel? enrollment,  List<PathItemModel> items)  $default,) {final _that = this;
switch (_that) {
case _PathDetailsModel():
return $default(_that.id,_that.slug,_that.title,_that.description,_that.field,_that.articleCount,_that.readingTimeMinutes,_that.coverUrl,_that.progress,_that.enrollment,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String? description,  FieldRefModel field,  int articleCount,  int readingTimeMinutes,  String? coverUrl,  PathProgressModel? progress,  PathEnrollmentModel? enrollment,  List<PathItemModel> items)?  $default,) {final _that = this;
switch (_that) {
case _PathDetailsModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.description,_that.field,_that.articleCount,_that.readingTimeMinutes,_that.coverUrl,_that.progress,_that.enrollment,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathDetailsModel extends PathDetailsModel {
  const _PathDetailsModel({required this.id, required this.slug, required this.title, this.description, required this.field, this.articleCount = 0, this.readingTimeMinutes = 0, this.coverUrl, this.progress, this.enrollment, final  List<PathItemModel> items = const <PathItemModel>[]}): _items = items,super._();
  factory _PathDetailsModel.fromJson(Map<String, dynamic> json) => _$PathDetailsModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;
@override final  String? description;
@override final  FieldRefModel field;
@override@JsonKey() final  int articleCount;
@override@JsonKey() final  int readingTimeMinutes;
@override final  String? coverUrl;
@override final  PathProgressModel? progress;
@override final  PathEnrollmentModel? enrollment;
 final  List<PathItemModel> _items;
@override@JsonKey() List<PathItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathDetailsModelCopyWith<_PathDetailsModel> get copyWith => __$PathDetailsModelCopyWithImpl<_PathDetailsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathDetailsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathDetailsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.field, field) || other.field == field)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount)&&(identical(other.readingTimeMinutes, readingTimeMinutes) || other.readingTimeMinutes == readingTimeMinutes)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,description,field,articleCount,readingTimeMinutes,coverUrl,progress,enrollment,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'PathDetailsModel(id: $id, slug: $slug, title: $title, description: $description, field: $field, articleCount: $articleCount, readingTimeMinutes: $readingTimeMinutes, coverUrl: $coverUrl, progress: $progress, enrollment: $enrollment, items: $items)';
}


}

/// @nodoc
abstract mixin class _$PathDetailsModelCopyWith<$Res> implements $PathDetailsModelCopyWith<$Res> {
  factory _$PathDetailsModelCopyWith(_PathDetailsModel value, $Res Function(_PathDetailsModel) _then) = __$PathDetailsModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String? description, FieldRefModel field, int articleCount, int readingTimeMinutes, String? coverUrl, PathProgressModel? progress, PathEnrollmentModel? enrollment, List<PathItemModel> items
});


@override $FieldRefModelCopyWith<$Res> get field;@override $PathProgressModelCopyWith<$Res>? get progress;@override $PathEnrollmentModelCopyWith<$Res>? get enrollment;

}
/// @nodoc
class __$PathDetailsModelCopyWithImpl<$Res>
    implements _$PathDetailsModelCopyWith<$Res> {
  __$PathDetailsModelCopyWithImpl(this._self, this._then);

  final _PathDetailsModel _self;
  final $Res Function(_PathDetailsModel) _then;

/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = freezed,Object? field = null,Object? articleCount = null,Object? readingTimeMinutes = null,Object? coverUrl = freezed,Object? progress = freezed,Object? enrollment = freezed,Object? items = null,}) {
  return _then(_PathDetailsModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,readingTimeMinutes: null == readingTimeMinutes ? _self.readingTimeMinutes : readingTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as PathProgressModel?,enrollment: freezed == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as PathEnrollmentModel?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PathItemModel>,
  ));
}

/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathProgressModelCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $PathProgressModelCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of PathDetailsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathEnrollmentModelCopyWith<$Res>? get enrollment {
    if (_self.enrollment == null) {
    return null;
  }

  return $PathEnrollmentModelCopyWith<$Res>(_self.enrollment!, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}
}


/// @nodoc
mixin _$ArticlePathModel {

 PathCardModel get path; int get position; int get total; PathArticleRefModel? get previous; ArticleCardModel? get next;
/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticlePathModelCopyWith<ArticlePathModel> get copyWith => _$ArticlePathModelCopyWithImpl<ArticlePathModel>(this as ArticlePathModel, _$identity);

  /// Serializes this ArticlePathModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticlePathModel&&(identical(other.path, path) || other.path == path)&&(identical(other.position, position) || other.position == position)&&(identical(other.total, total) || other.total == total)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,position,total,previous,next);

@override
String toString() {
  return 'ArticlePathModel(path: $path, position: $position, total: $total, previous: $previous, next: $next)';
}


}

/// @nodoc
abstract mixin class $ArticlePathModelCopyWith<$Res>  {
  factory $ArticlePathModelCopyWith(ArticlePathModel value, $Res Function(ArticlePathModel) _then) = _$ArticlePathModelCopyWithImpl;
@useResult
$Res call({
 PathCardModel path, int position, int total, PathArticleRefModel? previous, ArticleCardModel? next
});


$PathCardModelCopyWith<$Res> get path;$PathArticleRefModelCopyWith<$Res>? get previous;$ArticleCardModelCopyWith<$Res>? get next;

}
/// @nodoc
class _$ArticlePathModelCopyWithImpl<$Res>
    implements $ArticlePathModelCopyWith<$Res> {
  _$ArticlePathModelCopyWithImpl(this._self, this._then);

  final ArticlePathModel _self;
  final $Res Function(ArticlePathModel) _then;

/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? position = null,Object? total = null,Object? previous = freezed,Object? next = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as PathCardModel,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as PathArticleRefModel?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as ArticleCardModel?,
  ));
}
/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathCardModelCopyWith<$Res> get path {
  
  return $PathCardModelCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathArticleRefModelCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $PathArticleRefModelCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $ArticleCardModelCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticlePathModel].
extension ArticlePathModelPatterns on ArticlePathModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticlePathModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticlePathModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticlePathModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticlePathModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticlePathModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticlePathModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PathCardModel path,  int position,  int total,  PathArticleRefModel? previous,  ArticleCardModel? next)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticlePathModel() when $default != null:
return $default(_that.path,_that.position,_that.total,_that.previous,_that.next);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PathCardModel path,  int position,  int total,  PathArticleRefModel? previous,  ArticleCardModel? next)  $default,) {final _that = this;
switch (_that) {
case _ArticlePathModel():
return $default(_that.path,_that.position,_that.total,_that.previous,_that.next);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PathCardModel path,  int position,  int total,  PathArticleRefModel? previous,  ArticleCardModel? next)?  $default,) {final _that = this;
switch (_that) {
case _ArticlePathModel() when $default != null:
return $default(_that.path,_that.position,_that.total,_that.previous,_that.next);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticlePathModel extends ArticlePathModel {
  const _ArticlePathModel({required this.path, required this.position, required this.total, this.previous, this.next}): super._();
  factory _ArticlePathModel.fromJson(Map<String, dynamic> json) => _$ArticlePathModelFromJson(json);

@override final  PathCardModel path;
@override final  int position;
@override final  int total;
@override final  PathArticleRefModel? previous;
@override final  ArticleCardModel? next;

/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticlePathModelCopyWith<_ArticlePathModel> get copyWith => __$ArticlePathModelCopyWithImpl<_ArticlePathModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticlePathModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticlePathModel&&(identical(other.path, path) || other.path == path)&&(identical(other.position, position) || other.position == position)&&(identical(other.total, total) || other.total == total)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,position,total,previous,next);

@override
String toString() {
  return 'ArticlePathModel(path: $path, position: $position, total: $total, previous: $previous, next: $next)';
}


}

/// @nodoc
abstract mixin class _$ArticlePathModelCopyWith<$Res> implements $ArticlePathModelCopyWith<$Res> {
  factory _$ArticlePathModelCopyWith(_ArticlePathModel value, $Res Function(_ArticlePathModel) _then) = __$ArticlePathModelCopyWithImpl;
@override @useResult
$Res call({
 PathCardModel path, int position, int total, PathArticleRefModel? previous, ArticleCardModel? next
});


@override $PathCardModelCopyWith<$Res> get path;@override $PathArticleRefModelCopyWith<$Res>? get previous;@override $ArticleCardModelCopyWith<$Res>? get next;

}
/// @nodoc
class __$ArticlePathModelCopyWithImpl<$Res>
    implements _$ArticlePathModelCopyWith<$Res> {
  __$ArticlePathModelCopyWithImpl(this._self, this._then);

  final _ArticlePathModel _self;
  final $Res Function(_ArticlePathModel) _then;

/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? position = null,Object? total = null,Object? previous = freezed,Object? next = freezed,}) {
  return _then(_ArticlePathModel(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as PathCardModel,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as PathArticleRefModel?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as ArticleCardModel?,
  ));
}

/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathCardModelCopyWith<$Res> get path {
  
  return $PathCardModelCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PathArticleRefModelCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $PathArticleRefModelCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}/// Create a copy of ArticlePathModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleCardModelCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $ArticleCardModelCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}

// dart format on
