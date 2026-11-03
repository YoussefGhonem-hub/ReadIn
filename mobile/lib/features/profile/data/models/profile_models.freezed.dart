// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileLinksModel {

 String? get github; String? get linkedin; String? get website;
/// Create a copy of ProfileLinksModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileLinksModelCopyWith<ProfileLinksModel> get copyWith => _$ProfileLinksModelCopyWithImpl<ProfileLinksModel>(this as ProfileLinksModel, _$identity);

  /// Serializes this ProfileLinksModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileLinksModel&&(identical(other.github, github) || other.github == github)&&(identical(other.linkedin, linkedin) || other.linkedin == linkedin)&&(identical(other.website, website) || other.website == website));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,github,linkedin,website);

@override
String toString() {
  return 'ProfileLinksModel(github: $github, linkedin: $linkedin, website: $website)';
}


}

/// @nodoc
abstract mixin class $ProfileLinksModelCopyWith<$Res>  {
  factory $ProfileLinksModelCopyWith(ProfileLinksModel value, $Res Function(ProfileLinksModel) _then) = _$ProfileLinksModelCopyWithImpl;
@useResult
$Res call({
 String? github, String? linkedin, String? website
});




}
/// @nodoc
class _$ProfileLinksModelCopyWithImpl<$Res>
    implements $ProfileLinksModelCopyWith<$Res> {
  _$ProfileLinksModelCopyWithImpl(this._self, this._then);

  final ProfileLinksModel _self;
  final $Res Function(ProfileLinksModel) _then;

/// Create a copy of ProfileLinksModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? github = freezed,Object? linkedin = freezed,Object? website = freezed,}) {
  return _then(_self.copyWith(
github: freezed == github ? _self.github : github // ignore: cast_nullable_to_non_nullable
as String?,linkedin: freezed == linkedin ? _self.linkedin : linkedin // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileLinksModel].
extension ProfileLinksModelPatterns on ProfileLinksModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileLinksModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileLinksModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileLinksModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileLinksModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileLinksModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileLinksModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? github,  String? linkedin,  String? website)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileLinksModel() when $default != null:
return $default(_that.github,_that.linkedin,_that.website);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? github,  String? linkedin,  String? website)  $default,) {final _that = this;
switch (_that) {
case _ProfileLinksModel():
return $default(_that.github,_that.linkedin,_that.website);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? github,  String? linkedin,  String? website)?  $default,) {final _that = this;
switch (_that) {
case _ProfileLinksModel() when $default != null:
return $default(_that.github,_that.linkedin,_that.website);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileLinksModel extends ProfileLinksModel {
  const _ProfileLinksModel({this.github, this.linkedin, this.website}): super._();
  factory _ProfileLinksModel.fromJson(Map<String, dynamic> json) => _$ProfileLinksModelFromJson(json);

@override final  String? github;
@override final  String? linkedin;
@override final  String? website;

/// Create a copy of ProfileLinksModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileLinksModelCopyWith<_ProfileLinksModel> get copyWith => __$ProfileLinksModelCopyWithImpl<_ProfileLinksModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileLinksModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileLinksModel&&(identical(other.github, github) || other.github == github)&&(identical(other.linkedin, linkedin) || other.linkedin == linkedin)&&(identical(other.website, website) || other.website == website));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,github,linkedin,website);

@override
String toString() {
  return 'ProfileLinksModel(github: $github, linkedin: $linkedin, website: $website)';
}


}

/// @nodoc
abstract mixin class _$ProfileLinksModelCopyWith<$Res> implements $ProfileLinksModelCopyWith<$Res> {
  factory _$ProfileLinksModelCopyWith(_ProfileLinksModel value, $Res Function(_ProfileLinksModel) _then) = __$ProfileLinksModelCopyWithImpl;
@override @useResult
$Res call({
 String? github, String? linkedin, String? website
});




}
/// @nodoc
class __$ProfileLinksModelCopyWithImpl<$Res>
    implements _$ProfileLinksModelCopyWith<$Res> {
  __$ProfileLinksModelCopyWithImpl(this._self, this._then);

  final _ProfileLinksModel _self;
  final $Res Function(_ProfileLinksModel) _then;

/// Create a copy of ProfileLinksModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? github = freezed,Object? linkedin = freezed,Object? website = freezed,}) {
  return _then(_ProfileLinksModel(
github: freezed == github ? _self.github : github // ignore: cast_nullable_to_non_nullable
as String?,linkedin: freezed == linkedin ? _self.linkedin : linkedin // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ExpertiseFieldModel {

 String get id; String get slug; String get name; String get icon; String get color;
/// Create a copy of ExpertiseFieldModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpertiseFieldModelCopyWith<ExpertiseFieldModel> get copyWith => _$ExpertiseFieldModelCopyWithImpl<ExpertiseFieldModel>(this as ExpertiseFieldModel, _$identity);

  /// Serializes this ExpertiseFieldModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpertiseFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,icon,color);

@override
String toString() {
  return 'ExpertiseFieldModel(id: $id, slug: $slug, name: $name, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class $ExpertiseFieldModelCopyWith<$Res>  {
  factory $ExpertiseFieldModelCopyWith(ExpertiseFieldModel value, $Res Function(ExpertiseFieldModel) _then) = _$ExpertiseFieldModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String icon, String color
});




}
/// @nodoc
class _$ExpertiseFieldModelCopyWithImpl<$Res>
    implements $ExpertiseFieldModelCopyWith<$Res> {
  _$ExpertiseFieldModelCopyWithImpl(this._self, this._then);

  final ExpertiseFieldModel _self;
  final $Res Function(ExpertiseFieldModel) _then;

/// Create a copy of ExpertiseFieldModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? icon = null,Object? color = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpertiseFieldModel].
extension ExpertiseFieldModelPatterns on ExpertiseFieldModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpertiseFieldModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpertiseFieldModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpertiseFieldModel value)  $default,){
final _that = this;
switch (_that) {
case _ExpertiseFieldModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpertiseFieldModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExpertiseFieldModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String icon,  String color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpertiseFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String icon,  String color)  $default,) {final _that = this;
switch (_that) {
case _ExpertiseFieldModel():
return $default(_that.id,_that.slug,_that.name,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String icon,  String color)?  $default,) {final _that = this;
switch (_that) {
case _ExpertiseFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.icon,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpertiseFieldModel extends ExpertiseFieldModel {
  const _ExpertiseFieldModel({required this.id, required this.slug, required this.name, this.icon = 'book-open', this.color = 'primary'}): super._();
  factory _ExpertiseFieldModel.fromJson(Map<String, dynamic> json) => _$ExpertiseFieldModelFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String name;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;

/// Create a copy of ExpertiseFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpertiseFieldModelCopyWith<_ExpertiseFieldModel> get copyWith => __$ExpertiseFieldModelCopyWithImpl<_ExpertiseFieldModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpertiseFieldModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpertiseFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,icon,color);

@override
String toString() {
  return 'ExpertiseFieldModel(id: $id, slug: $slug, name: $name, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class _$ExpertiseFieldModelCopyWith<$Res> implements $ExpertiseFieldModelCopyWith<$Res> {
  factory _$ExpertiseFieldModelCopyWith(_ExpertiseFieldModel value, $Res Function(_ExpertiseFieldModel) _then) = __$ExpertiseFieldModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String icon, String color
});




}
/// @nodoc
class __$ExpertiseFieldModelCopyWithImpl<$Res>
    implements _$ExpertiseFieldModelCopyWith<$Res> {
  __$ExpertiseFieldModelCopyWithImpl(this._self, this._then);

  final _ExpertiseFieldModel _self;
  final $Res Function(_ExpertiseFieldModel) _then;

/// Create a copy of ExpertiseFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? icon = null,Object? color = null,}) {
  return _then(_ExpertiseFieldModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProfileStatsModel {

 int get articles; int get followers; int get following; int get totalReads;
/// Create a copy of ProfileStatsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileStatsModelCopyWith<ProfileStatsModel> get copyWith => _$ProfileStatsModelCopyWithImpl<ProfileStatsModel>(this as ProfileStatsModel, _$identity);

  /// Serializes this ProfileStatsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileStatsModel&&(identical(other.articles, articles) || other.articles == articles)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.following, following) || other.following == following)&&(identical(other.totalReads, totalReads) || other.totalReads == totalReads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,articles,followers,following,totalReads);

@override
String toString() {
  return 'ProfileStatsModel(articles: $articles, followers: $followers, following: $following, totalReads: $totalReads)';
}


}

/// @nodoc
abstract mixin class $ProfileStatsModelCopyWith<$Res>  {
  factory $ProfileStatsModelCopyWith(ProfileStatsModel value, $Res Function(ProfileStatsModel) _then) = _$ProfileStatsModelCopyWithImpl;
@useResult
$Res call({
 int articles, int followers, int following, int totalReads
});




}
/// @nodoc
class _$ProfileStatsModelCopyWithImpl<$Res>
    implements $ProfileStatsModelCopyWith<$Res> {
  _$ProfileStatsModelCopyWithImpl(this._self, this._then);

  final ProfileStatsModel _self;
  final $Res Function(ProfileStatsModel) _then;

/// Create a copy of ProfileStatsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? articles = null,Object? followers = null,Object? following = null,Object? totalReads = null,}) {
  return _then(_self.copyWith(
articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,totalReads: null == totalReads ? _self.totalReads : totalReads // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileStatsModel].
extension ProfileStatsModelPatterns on ProfileStatsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileStatsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileStatsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileStatsModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileStatsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileStatsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileStatsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int articles,  int followers,  int following,  int totalReads)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileStatsModel() when $default != null:
return $default(_that.articles,_that.followers,_that.following,_that.totalReads);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int articles,  int followers,  int following,  int totalReads)  $default,) {final _that = this;
switch (_that) {
case _ProfileStatsModel():
return $default(_that.articles,_that.followers,_that.following,_that.totalReads);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int articles,  int followers,  int following,  int totalReads)?  $default,) {final _that = this;
switch (_that) {
case _ProfileStatsModel() when $default != null:
return $default(_that.articles,_that.followers,_that.following,_that.totalReads);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileStatsModel extends ProfileStatsModel {
  const _ProfileStatsModel({this.articles = 0, this.followers = 0, this.following = 0, this.totalReads = 0}): super._();
  factory _ProfileStatsModel.fromJson(Map<String, dynamic> json) => _$ProfileStatsModelFromJson(json);

@override@JsonKey() final  int articles;
@override@JsonKey() final  int followers;
@override@JsonKey() final  int following;
@override@JsonKey() final  int totalReads;

/// Create a copy of ProfileStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileStatsModelCopyWith<_ProfileStatsModel> get copyWith => __$ProfileStatsModelCopyWithImpl<_ProfileStatsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileStatsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileStatsModel&&(identical(other.articles, articles) || other.articles == articles)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.following, following) || other.following == following)&&(identical(other.totalReads, totalReads) || other.totalReads == totalReads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,articles,followers,following,totalReads);

@override
String toString() {
  return 'ProfileStatsModel(articles: $articles, followers: $followers, following: $following, totalReads: $totalReads)';
}


}

/// @nodoc
abstract mixin class _$ProfileStatsModelCopyWith<$Res> implements $ProfileStatsModelCopyWith<$Res> {
  factory _$ProfileStatsModelCopyWith(_ProfileStatsModel value, $Res Function(_ProfileStatsModel) _then) = __$ProfileStatsModelCopyWithImpl;
@override @useResult
$Res call({
 int articles, int followers, int following, int totalReads
});




}
/// @nodoc
class __$ProfileStatsModelCopyWithImpl<$Res>
    implements _$ProfileStatsModelCopyWith<$Res> {
  __$ProfileStatsModelCopyWithImpl(this._self, this._then);

  final _ProfileStatsModel _self;
  final $Res Function(_ProfileStatsModel) _then;

/// Create a copy of ProfileStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? articles = null,Object? followers = null,Object? following = null,Object? totalReads = null,}) {
  return _then(_ProfileStatsModel(
articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,totalReads: null == totalReads ? _self.totalReads : totalReads // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProfileModel {

 String get id; String get displayName; String get username; String? get avatarUrl;// `{ "64": url, "128": url, "256": url, "512": url }`, or null.
 Map<String, String>? get avatarVariants; bool get isVerified; String? get bio; ProfileLinksModel get links; List<ExpertiseFieldModel> get expertise; DateTime? get joinedAt; ProfileStatsModel get stats; bool get isMe; bool get isFollowing; bool get followsYou; bool get readingStatsVisible;
/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileModelCopyWith<ProfileModel> get copyWith => _$ProfileModelCopyWithImpl<ProfileModel>(this as ProfileModel, _$identity);

  /// Serializes this ProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other.avatarVariants, avatarVariants)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.links, links) || other.links == links)&&const DeepCollectionEquality().equals(other.expertise, expertise)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followsYou, followsYou) || other.followsYou == followsYou)&&(identical(other.readingStatsVisible, readingStatsVisible) || other.readingStatsVisible == readingStatsVisible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,const DeepCollectionEquality().hash(avatarVariants),isVerified,bio,links,const DeepCollectionEquality().hash(expertise),joinedAt,stats,isMe,isFollowing,followsYou,readingStatsVisible);

@override
String toString() {
  return 'ProfileModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, avatarVariants: $avatarVariants, isVerified: $isVerified, bio: $bio, links: $links, expertise: $expertise, joinedAt: $joinedAt, stats: $stats, isMe: $isMe, isFollowing: $isFollowing, followsYou: $followsYou, readingStatsVisible: $readingStatsVisible)';
}


}

/// @nodoc
abstract mixin class $ProfileModelCopyWith<$Res>  {
  factory $ProfileModelCopyWith(ProfileModel value, $Res Function(ProfileModel) _then) = _$ProfileModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, Map<String, String>? avatarVariants, bool isVerified, String? bio, ProfileLinksModel links, List<ExpertiseFieldModel> expertise, DateTime? joinedAt, ProfileStatsModel stats, bool isMe, bool isFollowing, bool followsYou, bool readingStatsVisible
});


$ProfileLinksModelCopyWith<$Res> get links;$ProfileStatsModelCopyWith<$Res> get stats;

}
/// @nodoc
class _$ProfileModelCopyWithImpl<$Res>
    implements $ProfileModelCopyWith<$Res> {
  _$ProfileModelCopyWithImpl(this._self, this._then);

  final ProfileModel _self;
  final $Res Function(ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? avatarVariants = freezed,Object? isVerified = null,Object? bio = freezed,Object? links = null,Object? expertise = null,Object? joinedAt = freezed,Object? stats = null,Object? isMe = null,Object? isFollowing = null,Object? followsYou = null,Object? readingStatsVisible = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarVariants: freezed == avatarVariants ? _self.avatarVariants : avatarVariants // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as ProfileLinksModel,expertise: null == expertise ? _self.expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<ExpertiseFieldModel>,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as ProfileStatsModel,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followsYou: null == followsYou ? _self.followsYou : followsYou // ignore: cast_nullable_to_non_nullable
as bool,readingStatsVisible: null == readingStatsVisible ? _self.readingStatsVisible : readingStatsVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileLinksModelCopyWith<$Res> get links {
  
  return $ProfileLinksModelCopyWith<$Res>(_self.links, (value) {
    return _then(_self.copyWith(links: value));
  });
}/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileStatsModelCopyWith<$Res> get stats {
  
  return $ProfileStatsModelCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProfileModel].
extension ProfileModelPatterns on ProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  Map<String, String>? avatarVariants,  bool isVerified,  String? bio,  ProfileLinksModel links,  List<ExpertiseFieldModel> expertise,  DateTime? joinedAt,  ProfileStatsModel stats,  bool isMe,  bool isFollowing,  bool followsYou,  bool readingStatsVisible)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarVariants,_that.isVerified,_that.bio,_that.links,_that.expertise,_that.joinedAt,_that.stats,_that.isMe,_that.isFollowing,_that.followsYou,_that.readingStatsVisible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  Map<String, String>? avatarVariants,  bool isVerified,  String? bio,  ProfileLinksModel links,  List<ExpertiseFieldModel> expertise,  DateTime? joinedAt,  ProfileStatsModel stats,  bool isMe,  bool isFollowing,  bool followsYou,  bool readingStatsVisible)  $default,) {final _that = this;
switch (_that) {
case _ProfileModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarVariants,_that.isVerified,_that.bio,_that.links,_that.expertise,_that.joinedAt,_that.stats,_that.isMe,_that.isFollowing,_that.followsYou,_that.readingStatsVisible);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  Map<String, String>? avatarVariants,  bool isVerified,  String? bio,  ProfileLinksModel links,  List<ExpertiseFieldModel> expertise,  DateTime? joinedAt,  ProfileStatsModel stats,  bool isMe,  bool isFollowing,  bool followsYou,  bool readingStatsVisible)?  $default,) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarVariants,_that.isVerified,_that.bio,_that.links,_that.expertise,_that.joinedAt,_that.stats,_that.isMe,_that.isFollowing,_that.followsYou,_that.readingStatsVisible);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileModel extends ProfileModel {
  const _ProfileModel({required this.id, required this.displayName, required this.username, this.avatarUrl, final  Map<String, String>? avatarVariants, this.isVerified = false, this.bio, this.links = const ProfileLinksModel(), final  List<ExpertiseFieldModel> expertise = const <ExpertiseFieldModel>[], this.joinedAt, this.stats = const ProfileStatsModel(), this.isMe = false, this.isFollowing = false, this.followsYou = false, this.readingStatsVisible = false}): _avatarVariants = avatarVariants,_expertise = expertise,super._();
  factory _ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String username;
@override final  String? avatarUrl;
// `{ "64": url, "128": url, "256": url, "512": url }`, or null.
 final  Map<String, String>? _avatarVariants;
// `{ "64": url, "128": url, "256": url, "512": url }`, or null.
@override Map<String, String>? get avatarVariants {
  final value = _avatarVariants;
  if (value == null) return null;
  if (_avatarVariants is EqualUnmodifiableMapView) return _avatarVariants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  bool isVerified;
@override final  String? bio;
@override@JsonKey() final  ProfileLinksModel links;
 final  List<ExpertiseFieldModel> _expertise;
@override@JsonKey() List<ExpertiseFieldModel> get expertise {
  if (_expertise is EqualUnmodifiableListView) return _expertise;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expertise);
}

@override final  DateTime? joinedAt;
@override@JsonKey() final  ProfileStatsModel stats;
@override@JsonKey() final  bool isMe;
@override@JsonKey() final  bool isFollowing;
@override@JsonKey() final  bool followsYou;
@override@JsonKey() final  bool readingStatsVisible;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileModelCopyWith<_ProfileModel> get copyWith => __$ProfileModelCopyWithImpl<_ProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other._avatarVariants, _avatarVariants)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.links, links) || other.links == links)&&const DeepCollectionEquality().equals(other._expertise, _expertise)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followsYou, followsYou) || other.followsYou == followsYou)&&(identical(other.readingStatsVisible, readingStatsVisible) || other.readingStatsVisible == readingStatsVisible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,const DeepCollectionEquality().hash(_avatarVariants),isVerified,bio,links,const DeepCollectionEquality().hash(_expertise),joinedAt,stats,isMe,isFollowing,followsYou,readingStatsVisible);

@override
String toString() {
  return 'ProfileModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, avatarVariants: $avatarVariants, isVerified: $isVerified, bio: $bio, links: $links, expertise: $expertise, joinedAt: $joinedAt, stats: $stats, isMe: $isMe, isFollowing: $isFollowing, followsYou: $followsYou, readingStatsVisible: $readingStatsVisible)';
}


}

/// @nodoc
abstract mixin class _$ProfileModelCopyWith<$Res> implements $ProfileModelCopyWith<$Res> {
  factory _$ProfileModelCopyWith(_ProfileModel value, $Res Function(_ProfileModel) _then) = __$ProfileModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, Map<String, String>? avatarVariants, bool isVerified, String? bio, ProfileLinksModel links, List<ExpertiseFieldModel> expertise, DateTime? joinedAt, ProfileStatsModel stats, bool isMe, bool isFollowing, bool followsYou, bool readingStatsVisible
});


@override $ProfileLinksModelCopyWith<$Res> get links;@override $ProfileStatsModelCopyWith<$Res> get stats;

}
/// @nodoc
class __$ProfileModelCopyWithImpl<$Res>
    implements _$ProfileModelCopyWith<$Res> {
  __$ProfileModelCopyWithImpl(this._self, this._then);

  final _ProfileModel _self;
  final $Res Function(_ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? avatarVariants = freezed,Object? isVerified = null,Object? bio = freezed,Object? links = null,Object? expertise = null,Object? joinedAt = freezed,Object? stats = null,Object? isMe = null,Object? isFollowing = null,Object? followsYou = null,Object? readingStatsVisible = null,}) {
  return _then(_ProfileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarVariants: freezed == avatarVariants ? _self._avatarVariants : avatarVariants // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as ProfileLinksModel,expertise: null == expertise ? _self._expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<ExpertiseFieldModel>,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as ProfileStatsModel,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followsYou: null == followsYou ? _self.followsYou : followsYou // ignore: cast_nullable_to_non_nullable
as bool,readingStatsVisible: null == readingStatsVisible ? _self.readingStatsVisible : readingStatsVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileLinksModelCopyWith<$Res> get links {
  
  return $ProfileLinksModelCopyWith<$Res>(_self.links, (value) {
    return _then(_self.copyWith(links: value));
  });
}/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileStatsModelCopyWith<$Res> get stats {
  
  return $ProfileStatsModelCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}

// dart format on
