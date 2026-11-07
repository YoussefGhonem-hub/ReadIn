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
mixin _$ProfileLinkModel {

 String get platform; String get url; String? get label;
/// Create a copy of ProfileLinkModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileLinkModelCopyWith<ProfileLinkModel> get copyWith => _$ProfileLinkModelCopyWithImpl<ProfileLinkModel>(this as ProfileLinkModel, _$identity);

  /// Serializes this ProfileLinkModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileLinkModel&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.url, url) || other.url == url)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,url,label);

@override
String toString() {
  return 'ProfileLinkModel(platform: $platform, url: $url, label: $label)';
}


}

/// @nodoc
abstract mixin class $ProfileLinkModelCopyWith<$Res>  {
  factory $ProfileLinkModelCopyWith(ProfileLinkModel value, $Res Function(ProfileLinkModel) _then) = _$ProfileLinkModelCopyWithImpl;
@useResult
$Res call({
 String platform, String url, String? label
});




}
/// @nodoc
class _$ProfileLinkModelCopyWithImpl<$Res>
    implements $ProfileLinkModelCopyWith<$Res> {
  _$ProfileLinkModelCopyWithImpl(this._self, this._then);

  final ProfileLinkModel _self;
  final $Res Function(ProfileLinkModel) _then;

/// Create a copy of ProfileLinkModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? url = null,Object? label = freezed,}) {
  return _then(_self.copyWith(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileLinkModel].
extension ProfileLinkModelPatterns on ProfileLinkModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileLinkModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileLinkModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileLinkModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileLinkModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileLinkModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileLinkModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String platform,  String url,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileLinkModel() when $default != null:
return $default(_that.platform,_that.url,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String platform,  String url,  String? label)  $default,) {final _that = this;
switch (_that) {
case _ProfileLinkModel():
return $default(_that.platform,_that.url,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String platform,  String url,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _ProfileLinkModel() when $default != null:
return $default(_that.platform,_that.url,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileLinkModel extends ProfileLinkModel {
  const _ProfileLinkModel({required this.platform, this.url = '', this.label}): super._();
  factory _ProfileLinkModel.fromJson(Map<String, dynamic> json) => _$ProfileLinkModelFromJson(json);

@override final  String platform;
@override@JsonKey() final  String url;
@override final  String? label;

/// Create a copy of ProfileLinkModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileLinkModelCopyWith<_ProfileLinkModel> get copyWith => __$ProfileLinkModelCopyWithImpl<_ProfileLinkModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileLinkModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileLinkModel&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.url, url) || other.url == url)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,url,label);

@override
String toString() {
  return 'ProfileLinkModel(platform: $platform, url: $url, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ProfileLinkModelCopyWith<$Res> implements $ProfileLinkModelCopyWith<$Res> {
  factory _$ProfileLinkModelCopyWith(_ProfileLinkModel value, $Res Function(_ProfileLinkModel) _then) = __$ProfileLinkModelCopyWithImpl;
@override @useResult
$Res call({
 String platform, String url, String? label
});




}
/// @nodoc
class __$ProfileLinkModelCopyWithImpl<$Res>
    implements _$ProfileLinkModelCopyWith<$Res> {
  __$ProfileLinkModelCopyWithImpl(this._self, this._then);

  final _ProfileLinkModel _self;
  final $Res Function(_ProfileLinkModel) _then;

/// Create a copy of ProfileLinkModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? url = null,Object? label = freezed,}) {
  return _then(_ProfileLinkModel(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
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
 Map<String, String>? get avatarVariants; bool get isVerified;// F14 title, shown in full on the profile; older APIs leave it out.
 String? get headline; String? get bio;@ProfileLinksJson() List<ProfileLinkModel> get links; List<ExpertiseFieldModel> get expertise; DateTime? get joinedAt; ProfileStatsModel get stats; bool get isMe; bool get isFollowing; bool get followsYou; bool get readingStatsVisible;// F28: the viewer muted this user.
 bool get isMuted;// F28: the official @readin account, which can't be muted.
 bool get isSystemAccount;// F23: the account's state, for holders of `users.read` only (null for everyone else).
 ProfileAdminModel? get admin;
/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileModelCopyWith<ProfileModel> get copyWith => _$ProfileModelCopyWithImpl<ProfileModel>(this as ProfileModel, _$identity);

  /// Serializes this ProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other.avatarVariants, avatarVariants)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.links, links)&&const DeepCollectionEquality().equals(other.expertise, expertise)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followsYou, followsYou) || other.followsYou == followsYou)&&(identical(other.readingStatsVisible, readingStatsVisible) || other.readingStatsVisible == readingStatsVisible)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isSystemAccount, isSystemAccount) || other.isSystemAccount == isSystemAccount)&&(identical(other.admin, admin) || other.admin == admin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,username,avatarUrl,const DeepCollectionEquality().hash(avatarVariants),isVerified,headline,bio,const DeepCollectionEquality().hash(links),const DeepCollectionEquality().hash(expertise),joinedAt,stats,isMe,isFollowing,followsYou,readingStatsVisible,isMuted,isSystemAccount,admin]);

@override
String toString() {
  return 'ProfileModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, avatarVariants: $avatarVariants, isVerified: $isVerified, headline: $headline, bio: $bio, links: $links, expertise: $expertise, joinedAt: $joinedAt, stats: $stats, isMe: $isMe, isFollowing: $isFollowing, followsYou: $followsYou, readingStatsVisible: $readingStatsVisible, isMuted: $isMuted, isSystemAccount: $isSystemAccount, admin: $admin)';
}


}

/// @nodoc
abstract mixin class $ProfileModelCopyWith<$Res>  {
  factory $ProfileModelCopyWith(ProfileModel value, $Res Function(ProfileModel) _then) = _$ProfileModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, Map<String, String>? avatarVariants, bool isVerified, String? headline, String? bio,@ProfileLinksJson() List<ProfileLinkModel> links, List<ExpertiseFieldModel> expertise, DateTime? joinedAt, ProfileStatsModel stats, bool isMe, bool isFollowing, bool followsYou, bool readingStatsVisible, bool isMuted, bool isSystemAccount, ProfileAdminModel? admin
});


$ProfileStatsModelCopyWith<$Res> get stats;$ProfileAdminModelCopyWith<$Res>? get admin;

}
/// @nodoc
class _$ProfileModelCopyWithImpl<$Res>
    implements $ProfileModelCopyWith<$Res> {
  _$ProfileModelCopyWithImpl(this._self, this._then);

  final ProfileModel _self;
  final $Res Function(ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? avatarVariants = freezed,Object? isVerified = null,Object? headline = freezed,Object? bio = freezed,Object? links = null,Object? expertise = null,Object? joinedAt = freezed,Object? stats = null,Object? isMe = null,Object? isFollowing = null,Object? followsYou = null,Object? readingStatsVisible = null,Object? isMuted = null,Object? isSystemAccount = null,Object? admin = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarVariants: freezed == avatarVariants ? _self.avatarVariants : avatarVariants // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<ProfileLinkModel>,expertise: null == expertise ? _self.expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<ExpertiseFieldModel>,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as ProfileStatsModel,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followsYou: null == followsYou ? _self.followsYou : followsYou // ignore: cast_nullable_to_non_nullable
as bool,readingStatsVisible: null == readingStatsVisible ? _self.readingStatsVisible : readingStatsVisible // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isSystemAccount: null == isSystemAccount ? _self.isSystemAccount : isSystemAccount // ignore: cast_nullable_to_non_nullable
as bool,admin: freezed == admin ? _self.admin : admin // ignore: cast_nullable_to_non_nullable
as ProfileAdminModel?,
  ));
}
/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileStatsModelCopyWith<$Res> get stats {
  
  return $ProfileStatsModelCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileAdminModelCopyWith<$Res>? get admin {
    if (_self.admin == null) {
    return null;
  }

  return $ProfileAdminModelCopyWith<$Res>(_self.admin!, (value) {
    return _then(_self.copyWith(admin: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  Map<String, String>? avatarVariants,  bool isVerified,  String? headline,  String? bio, @ProfileLinksJson()  List<ProfileLinkModel> links,  List<ExpertiseFieldModel> expertise,  DateTime? joinedAt,  ProfileStatsModel stats,  bool isMe,  bool isFollowing,  bool followsYou,  bool readingStatsVisible,  bool isMuted,  bool isSystemAccount,  ProfileAdminModel? admin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarVariants,_that.isVerified,_that.headline,_that.bio,_that.links,_that.expertise,_that.joinedAt,_that.stats,_that.isMe,_that.isFollowing,_that.followsYou,_that.readingStatsVisible,_that.isMuted,_that.isSystemAccount,_that.admin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  Map<String, String>? avatarVariants,  bool isVerified,  String? headline,  String? bio, @ProfileLinksJson()  List<ProfileLinkModel> links,  List<ExpertiseFieldModel> expertise,  DateTime? joinedAt,  ProfileStatsModel stats,  bool isMe,  bool isFollowing,  bool followsYou,  bool readingStatsVisible,  bool isMuted,  bool isSystemAccount,  ProfileAdminModel? admin)  $default,) {final _that = this;
switch (_that) {
case _ProfileModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarVariants,_that.isVerified,_that.headline,_that.bio,_that.links,_that.expertise,_that.joinedAt,_that.stats,_that.isMe,_that.isFollowing,_that.followsYou,_that.readingStatsVisible,_that.isMuted,_that.isSystemAccount,_that.admin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  Map<String, String>? avatarVariants,  bool isVerified,  String? headline,  String? bio, @ProfileLinksJson()  List<ProfileLinkModel> links,  List<ExpertiseFieldModel> expertise,  DateTime? joinedAt,  ProfileStatsModel stats,  bool isMe,  bool isFollowing,  bool followsYou,  bool readingStatsVisible,  bool isMuted,  bool isSystemAccount,  ProfileAdminModel? admin)?  $default,) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.avatarVariants,_that.isVerified,_that.headline,_that.bio,_that.links,_that.expertise,_that.joinedAt,_that.stats,_that.isMe,_that.isFollowing,_that.followsYou,_that.readingStatsVisible,_that.isMuted,_that.isSystemAccount,_that.admin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileModel extends ProfileModel {
  const _ProfileModel({required this.id, required this.displayName, required this.username, this.avatarUrl, final  Map<String, String>? avatarVariants, this.isVerified = false, this.headline, this.bio, @ProfileLinksJson() final  List<ProfileLinkModel> links = const <ProfileLinkModel>[], final  List<ExpertiseFieldModel> expertise = const <ExpertiseFieldModel>[], this.joinedAt, this.stats = const ProfileStatsModel(), this.isMe = false, this.isFollowing = false, this.followsYou = false, this.readingStatsVisible = false, this.isMuted = false, this.isSystemAccount = false, this.admin}): _avatarVariants = avatarVariants,_links = links,_expertise = expertise,super._();
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
// F14 title, shown in full on the profile; older APIs leave it out.
@override final  String? headline;
@override final  String? bio;
 final  List<ProfileLinkModel> _links;
@override@JsonKey()@ProfileLinksJson() List<ProfileLinkModel> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

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
// F28: the viewer muted this user.
@override@JsonKey() final  bool isMuted;
// F28: the official @readin account, which can't be muted.
@override@JsonKey() final  bool isSystemAccount;
// F23: the account's state, for holders of `users.read` only (null for everyone else).
@override final  ProfileAdminModel? admin;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other._avatarVariants, _avatarVariants)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._links, _links)&&const DeepCollectionEquality().equals(other._expertise, _expertise)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.isFollowing, isFollowing) || other.isFollowing == isFollowing)&&(identical(other.followsYou, followsYou) || other.followsYou == followsYou)&&(identical(other.readingStatsVisible, readingStatsVisible) || other.readingStatsVisible == readingStatsVisible)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isSystemAccount, isSystemAccount) || other.isSystemAccount == isSystemAccount)&&(identical(other.admin, admin) || other.admin == admin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,username,avatarUrl,const DeepCollectionEquality().hash(_avatarVariants),isVerified,headline,bio,const DeepCollectionEquality().hash(_links),const DeepCollectionEquality().hash(_expertise),joinedAt,stats,isMe,isFollowing,followsYou,readingStatsVisible,isMuted,isSystemAccount,admin]);

@override
String toString() {
  return 'ProfileModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, avatarVariants: $avatarVariants, isVerified: $isVerified, headline: $headline, bio: $bio, links: $links, expertise: $expertise, joinedAt: $joinedAt, stats: $stats, isMe: $isMe, isFollowing: $isFollowing, followsYou: $followsYou, readingStatsVisible: $readingStatsVisible, isMuted: $isMuted, isSystemAccount: $isSystemAccount, admin: $admin)';
}


}

/// @nodoc
abstract mixin class _$ProfileModelCopyWith<$Res> implements $ProfileModelCopyWith<$Res> {
  factory _$ProfileModelCopyWith(_ProfileModel value, $Res Function(_ProfileModel) _then) = __$ProfileModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, Map<String, String>? avatarVariants, bool isVerified, String? headline, String? bio,@ProfileLinksJson() List<ProfileLinkModel> links, List<ExpertiseFieldModel> expertise, DateTime? joinedAt, ProfileStatsModel stats, bool isMe, bool isFollowing, bool followsYou, bool readingStatsVisible, bool isMuted, bool isSystemAccount, ProfileAdminModel? admin
});


@override $ProfileStatsModelCopyWith<$Res> get stats;@override $ProfileAdminModelCopyWith<$Res>? get admin;

}
/// @nodoc
class __$ProfileModelCopyWithImpl<$Res>
    implements _$ProfileModelCopyWith<$Res> {
  __$ProfileModelCopyWithImpl(this._self, this._then);

  final _ProfileModel _self;
  final $Res Function(_ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? avatarVariants = freezed,Object? isVerified = null,Object? headline = freezed,Object? bio = freezed,Object? links = null,Object? expertise = null,Object? joinedAt = freezed,Object? stats = null,Object? isMe = null,Object? isFollowing = null,Object? followsYou = null,Object? readingStatsVisible = null,Object? isMuted = null,Object? isSystemAccount = null,Object? admin = freezed,}) {
  return _then(_ProfileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarVariants: freezed == avatarVariants ? _self._avatarVariants : avatarVariants // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<ProfileLinkModel>,expertise: null == expertise ? _self._expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<ExpertiseFieldModel>,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as ProfileStatsModel,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,isFollowing: null == isFollowing ? _self.isFollowing : isFollowing // ignore: cast_nullable_to_non_nullable
as bool,followsYou: null == followsYou ? _self.followsYou : followsYou // ignore: cast_nullable_to_non_nullable
as bool,readingStatsVisible: null == readingStatsVisible ? _self.readingStatsVisible : readingStatsVisible // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isSystemAccount: null == isSystemAccount ? _self.isSystemAccount : isSystemAccount // ignore: cast_nullable_to_non_nullable
as bool,admin: freezed == admin ? _self.admin : admin // ignore: cast_nullable_to_non_nullable
as ProfileAdminModel?,
  ));
}

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileStatsModelCopyWith<$Res> get stats {
  
  return $ProfileStatsModelCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileAdminModelCopyWith<$Res>? get admin {
    if (_self.admin == null) {
    return null;
  }

  return $ProfileAdminModelCopyWith<$Res>(_self.admin!, (value) {
    return _then(_self.copyWith(admin: value));
  });
}
}


/// @nodoc
mixin _$ProfileAdminModel {

 bool get isSuspended; DateTime? get suspendedUntil; bool get isStaff;
/// Create a copy of ProfileAdminModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileAdminModelCopyWith<ProfileAdminModel> get copyWith => _$ProfileAdminModelCopyWithImpl<ProfileAdminModel>(this as ProfileAdminModel, _$identity);

  /// Serializes this ProfileAdminModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileAdminModel&&(identical(other.isSuspended, isSuspended) || other.isSuspended == isSuspended)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.isStaff, isStaff) || other.isStaff == isStaff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSuspended,suspendedUntil,isStaff);

@override
String toString() {
  return 'ProfileAdminModel(isSuspended: $isSuspended, suspendedUntil: $suspendedUntil, isStaff: $isStaff)';
}


}

/// @nodoc
abstract mixin class $ProfileAdminModelCopyWith<$Res>  {
  factory $ProfileAdminModelCopyWith(ProfileAdminModel value, $Res Function(ProfileAdminModel) _then) = _$ProfileAdminModelCopyWithImpl;
@useResult
$Res call({
 bool isSuspended, DateTime? suspendedUntil, bool isStaff
});




}
/// @nodoc
class _$ProfileAdminModelCopyWithImpl<$Res>
    implements $ProfileAdminModelCopyWith<$Res> {
  _$ProfileAdminModelCopyWithImpl(this._self, this._then);

  final ProfileAdminModel _self;
  final $Res Function(ProfileAdminModel) _then;

/// Create a copy of ProfileAdminModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSuspended = null,Object? suspendedUntil = freezed,Object? isStaff = null,}) {
  return _then(_self.copyWith(
isSuspended: null == isSuspended ? _self.isSuspended : isSuspended // ignore: cast_nullable_to_non_nullable
as bool,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isStaff: null == isStaff ? _self.isStaff : isStaff // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileAdminModel].
extension ProfileAdminModelPatterns on ProfileAdminModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileAdminModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileAdminModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileAdminModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileAdminModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileAdminModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileAdminModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSuspended,  DateTime? suspendedUntil,  bool isStaff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileAdminModel() when $default != null:
return $default(_that.isSuspended,_that.suspendedUntil,_that.isStaff);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSuspended,  DateTime? suspendedUntil,  bool isStaff)  $default,) {final _that = this;
switch (_that) {
case _ProfileAdminModel():
return $default(_that.isSuspended,_that.suspendedUntil,_that.isStaff);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSuspended,  DateTime? suspendedUntil,  bool isStaff)?  $default,) {final _that = this;
switch (_that) {
case _ProfileAdminModel() when $default != null:
return $default(_that.isSuspended,_that.suspendedUntil,_that.isStaff);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileAdminModel extends ProfileAdminModel {
  const _ProfileAdminModel({this.isSuspended = false, this.suspendedUntil, this.isStaff = false}): super._();
  factory _ProfileAdminModel.fromJson(Map<String, dynamic> json) => _$ProfileAdminModelFromJson(json);

@override@JsonKey() final  bool isSuspended;
@override final  DateTime? suspendedUntil;
@override@JsonKey() final  bool isStaff;

/// Create a copy of ProfileAdminModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileAdminModelCopyWith<_ProfileAdminModel> get copyWith => __$ProfileAdminModelCopyWithImpl<_ProfileAdminModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileAdminModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileAdminModel&&(identical(other.isSuspended, isSuspended) || other.isSuspended == isSuspended)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.isStaff, isStaff) || other.isStaff == isStaff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSuspended,suspendedUntil,isStaff);

@override
String toString() {
  return 'ProfileAdminModel(isSuspended: $isSuspended, suspendedUntil: $suspendedUntil, isStaff: $isStaff)';
}


}

/// @nodoc
abstract mixin class _$ProfileAdminModelCopyWith<$Res> implements $ProfileAdminModelCopyWith<$Res> {
  factory _$ProfileAdminModelCopyWith(_ProfileAdminModel value, $Res Function(_ProfileAdminModel) _then) = __$ProfileAdminModelCopyWithImpl;
@override @useResult
$Res call({
 bool isSuspended, DateTime? suspendedUntil, bool isStaff
});




}
/// @nodoc
class __$ProfileAdminModelCopyWithImpl<$Res>
    implements _$ProfileAdminModelCopyWith<$Res> {
  __$ProfileAdminModelCopyWithImpl(this._self, this._then);

  final _ProfileAdminModel _self;
  final $Res Function(_ProfileAdminModel) _then;

/// Create a copy of ProfileAdminModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSuspended = null,Object? suspendedUntil = freezed,Object? isStaff = null,}) {
  return _then(_ProfileAdminModel(
isSuspended: null == isSuspended ? _self.isSuspended : isSuspended // ignore: cast_nullable_to_non_nullable
as bool,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isStaff: null == isStaff ? _self.isStaff : isStaff // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
