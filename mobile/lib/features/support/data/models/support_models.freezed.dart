// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportConfigModel {

 String? get email; List<String> get categories; int get maxAttachments; int get maxAttachmentBytes;
/// Create a copy of SupportConfigModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportConfigModelCopyWith<SupportConfigModel> get copyWith => _$SupportConfigModelCopyWithImpl<SupportConfigModel>(this as SupportConfigModel, _$identity);

  /// Serializes this SupportConfigModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportConfigModel&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.maxAttachments, maxAttachments) || other.maxAttachments == maxAttachments)&&(identical(other.maxAttachmentBytes, maxAttachmentBytes) || other.maxAttachmentBytes == maxAttachmentBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,const DeepCollectionEquality().hash(categories),maxAttachments,maxAttachmentBytes);

@override
String toString() {
  return 'SupportConfigModel(email: $email, categories: $categories, maxAttachments: $maxAttachments, maxAttachmentBytes: $maxAttachmentBytes)';
}


}

/// @nodoc
abstract mixin class $SupportConfigModelCopyWith<$Res>  {
  factory $SupportConfigModelCopyWith(SupportConfigModel value, $Res Function(SupportConfigModel) _then) = _$SupportConfigModelCopyWithImpl;
@useResult
$Res call({
 String? email, List<String> categories, int maxAttachments, int maxAttachmentBytes
});




}
/// @nodoc
class _$SupportConfigModelCopyWithImpl<$Res>
    implements $SupportConfigModelCopyWith<$Res> {
  _$SupportConfigModelCopyWithImpl(this._self, this._then);

  final SupportConfigModel _self;
  final $Res Function(SupportConfigModel) _then;

/// Create a copy of SupportConfigModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = freezed,Object? categories = null,Object? maxAttachments = null,Object? maxAttachmentBytes = null,}) {
  return _then(_self.copyWith(
email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,maxAttachments: null == maxAttachments ? _self.maxAttachments : maxAttachments // ignore: cast_nullable_to_non_nullable
as int,maxAttachmentBytes: null == maxAttachmentBytes ? _self.maxAttachmentBytes : maxAttachmentBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportConfigModel].
extension SupportConfigModelPatterns on SupportConfigModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportConfigModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportConfigModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportConfigModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportConfigModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportConfigModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportConfigModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? email,  List<String> categories,  int maxAttachments,  int maxAttachmentBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportConfigModel() when $default != null:
return $default(_that.email,_that.categories,_that.maxAttachments,_that.maxAttachmentBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? email,  List<String> categories,  int maxAttachments,  int maxAttachmentBytes)  $default,) {final _that = this;
switch (_that) {
case _SupportConfigModel():
return $default(_that.email,_that.categories,_that.maxAttachments,_that.maxAttachmentBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? email,  List<String> categories,  int maxAttachments,  int maxAttachmentBytes)?  $default,) {final _that = this;
switch (_that) {
case _SupportConfigModel() when $default != null:
return $default(_that.email,_that.categories,_that.maxAttachments,_that.maxAttachmentBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportConfigModel extends SupportConfigModel {
  const _SupportConfigModel({this.email, final  List<String> categories = const <String>[], this.maxAttachments = SupportLimits.maxScreenshots, this.maxAttachmentBytes = SupportLimits.screenshotMaxBytes}): _categories = categories,super._();
  factory _SupportConfigModel.fromJson(Map<String, dynamic> json) => _$SupportConfigModelFromJson(json);

@override final  String? email;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override@JsonKey() final  int maxAttachments;
@override@JsonKey() final  int maxAttachmentBytes;

/// Create a copy of SupportConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportConfigModelCopyWith<_SupportConfigModel> get copyWith => __$SupportConfigModelCopyWithImpl<_SupportConfigModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportConfigModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportConfigModel&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.maxAttachments, maxAttachments) || other.maxAttachments == maxAttachments)&&(identical(other.maxAttachmentBytes, maxAttachmentBytes) || other.maxAttachmentBytes == maxAttachmentBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,const DeepCollectionEquality().hash(_categories),maxAttachments,maxAttachmentBytes);

@override
String toString() {
  return 'SupportConfigModel(email: $email, categories: $categories, maxAttachments: $maxAttachments, maxAttachmentBytes: $maxAttachmentBytes)';
}


}

/// @nodoc
abstract mixin class _$SupportConfigModelCopyWith<$Res> implements $SupportConfigModelCopyWith<$Res> {
  factory _$SupportConfigModelCopyWith(_SupportConfigModel value, $Res Function(_SupportConfigModel) _then) = __$SupportConfigModelCopyWithImpl;
@override @useResult
$Res call({
 String? email, List<String> categories, int maxAttachments, int maxAttachmentBytes
});




}
/// @nodoc
class __$SupportConfigModelCopyWithImpl<$Res>
    implements _$SupportConfigModelCopyWith<$Res> {
  __$SupportConfigModelCopyWithImpl(this._self, this._then);

  final _SupportConfigModel _self;
  final $Res Function(_SupportConfigModel) _then;

/// Create a copy of SupportConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = freezed,Object? categories = null,Object? maxAttachments = null,Object? maxAttachmentBytes = null,}) {
  return _then(_SupportConfigModel(
email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,maxAttachments: null == maxAttachments ? _self.maxAttachments : maxAttachments // ignore: cast_nullable_to_non_nullable
as int,maxAttachmentBytes: null == maxAttachmentBytes ? _self.maxAttachmentBytes : maxAttachmentBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SupportDeviceModel {

 String? get platform; String? get osVersion; String? get appVersion; String? get language; String? get screen;
/// Create a copy of SupportDeviceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportDeviceModelCopyWith<SupportDeviceModel> get copyWith => _$SupportDeviceModelCopyWithImpl<SupportDeviceModel>(this as SupportDeviceModel, _$identity);

  /// Serializes this SupportDeviceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportDeviceModel&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.language, language) || other.language == language)&&(identical(other.screen, screen) || other.screen == screen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,osVersion,appVersion,language,screen);

@override
String toString() {
  return 'SupportDeviceModel(platform: $platform, osVersion: $osVersion, appVersion: $appVersion, language: $language, screen: $screen)';
}


}

/// @nodoc
abstract mixin class $SupportDeviceModelCopyWith<$Res>  {
  factory $SupportDeviceModelCopyWith(SupportDeviceModel value, $Res Function(SupportDeviceModel) _then) = _$SupportDeviceModelCopyWithImpl;
@useResult
$Res call({
 String? platform, String? osVersion, String? appVersion, String? language, String? screen
});




}
/// @nodoc
class _$SupportDeviceModelCopyWithImpl<$Res>
    implements $SupportDeviceModelCopyWith<$Res> {
  _$SupportDeviceModelCopyWithImpl(this._self, this._then);

  final SupportDeviceModel _self;
  final $Res Function(SupportDeviceModel) _then;

/// Create a copy of SupportDeviceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = freezed,Object? osVersion = freezed,Object? appVersion = freezed,Object? language = freezed,Object? screen = freezed,}) {
  return _then(_self.copyWith(
platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,screen: freezed == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportDeviceModel].
extension SupportDeviceModelPatterns on SupportDeviceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportDeviceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportDeviceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportDeviceModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportDeviceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportDeviceModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportDeviceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? platform,  String? osVersion,  String? appVersion,  String? language,  String? screen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportDeviceModel() when $default != null:
return $default(_that.platform,_that.osVersion,_that.appVersion,_that.language,_that.screen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? platform,  String? osVersion,  String? appVersion,  String? language,  String? screen)  $default,) {final _that = this;
switch (_that) {
case _SupportDeviceModel():
return $default(_that.platform,_that.osVersion,_that.appVersion,_that.language,_that.screen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? platform,  String? osVersion,  String? appVersion,  String? language,  String? screen)?  $default,) {final _that = this;
switch (_that) {
case _SupportDeviceModel() when $default != null:
return $default(_that.platform,_that.osVersion,_that.appVersion,_that.language,_that.screen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportDeviceModel extends SupportDeviceModel {
  const _SupportDeviceModel({this.platform, this.osVersion, this.appVersion, this.language, this.screen}): super._();
  factory _SupportDeviceModel.fromJson(Map<String, dynamic> json) => _$SupportDeviceModelFromJson(json);

@override final  String? platform;
@override final  String? osVersion;
@override final  String? appVersion;
@override final  String? language;
@override final  String? screen;

/// Create a copy of SupportDeviceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportDeviceModelCopyWith<_SupportDeviceModel> get copyWith => __$SupportDeviceModelCopyWithImpl<_SupportDeviceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportDeviceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportDeviceModel&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.language, language) || other.language == language)&&(identical(other.screen, screen) || other.screen == screen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,osVersion,appVersion,language,screen);

@override
String toString() {
  return 'SupportDeviceModel(platform: $platform, osVersion: $osVersion, appVersion: $appVersion, language: $language, screen: $screen)';
}


}

/// @nodoc
abstract mixin class _$SupportDeviceModelCopyWith<$Res> implements $SupportDeviceModelCopyWith<$Res> {
  factory _$SupportDeviceModelCopyWith(_SupportDeviceModel value, $Res Function(_SupportDeviceModel) _then) = __$SupportDeviceModelCopyWithImpl;
@override @useResult
$Res call({
 String? platform, String? osVersion, String? appVersion, String? language, String? screen
});




}
/// @nodoc
class __$SupportDeviceModelCopyWithImpl<$Res>
    implements _$SupportDeviceModelCopyWith<$Res> {
  __$SupportDeviceModelCopyWithImpl(this._self, this._then);

  final _SupportDeviceModel _self;
  final $Res Function(_SupportDeviceModel) _then;

/// Create a copy of SupportDeviceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = freezed,Object? osVersion = freezed,Object? appVersion = freezed,Object? language = freezed,Object? screen = freezed,}) {
  return _then(_SupportDeviceModel(
platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,screen: freezed == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SupportAttachmentModel {

 String get id; String get contentType; int get sizeBytes;
/// Create a copy of SupportAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportAttachmentModelCopyWith<SupportAttachmentModel> get copyWith => _$SupportAttachmentModelCopyWithImpl<SupportAttachmentModel>(this as SupportAttachmentModel, _$identity);

  /// Serializes this SupportAttachmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportAttachmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contentType,sizeBytes);

@override
String toString() {
  return 'SupportAttachmentModel(id: $id, contentType: $contentType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $SupportAttachmentModelCopyWith<$Res>  {
  factory $SupportAttachmentModelCopyWith(SupportAttachmentModel value, $Res Function(SupportAttachmentModel) _then) = _$SupportAttachmentModelCopyWithImpl;
@useResult
$Res call({
 String id, String contentType, int sizeBytes
});




}
/// @nodoc
class _$SupportAttachmentModelCopyWithImpl<$Res>
    implements $SupportAttachmentModelCopyWith<$Res> {
  _$SupportAttachmentModelCopyWithImpl(this._self, this._then);

  final SupportAttachmentModel _self;
  final $Res Function(SupportAttachmentModel) _then;

/// Create a copy of SupportAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? contentType = null,Object? sizeBytes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportAttachmentModel].
extension SupportAttachmentModelPatterns on SupportAttachmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportAttachmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportAttachmentModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportAttachmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportAttachmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String contentType,  int sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportAttachmentModel() when $default != null:
return $default(_that.id,_that.contentType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String contentType,  int sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _SupportAttachmentModel():
return $default(_that.id,_that.contentType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String contentType,  int sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _SupportAttachmentModel() when $default != null:
return $default(_that.id,_that.contentType,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportAttachmentModel extends SupportAttachmentModel {
  const _SupportAttachmentModel({required this.id, this.contentType = 'image/jpeg', this.sizeBytes = 0}): super._();
  factory _SupportAttachmentModel.fromJson(Map<String, dynamic> json) => _$SupportAttachmentModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String contentType;
@override@JsonKey() final  int sizeBytes;

/// Create a copy of SupportAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportAttachmentModelCopyWith<_SupportAttachmentModel> get copyWith => __$SupportAttachmentModelCopyWithImpl<_SupportAttachmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportAttachmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportAttachmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contentType,sizeBytes);

@override
String toString() {
  return 'SupportAttachmentModel(id: $id, contentType: $contentType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$SupportAttachmentModelCopyWith<$Res> implements $SupportAttachmentModelCopyWith<$Res> {
  factory _$SupportAttachmentModelCopyWith(_SupportAttachmentModel value, $Res Function(_SupportAttachmentModel) _then) = __$SupportAttachmentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String contentType, int sizeBytes
});




}
/// @nodoc
class __$SupportAttachmentModelCopyWithImpl<$Res>
    implements _$SupportAttachmentModelCopyWith<$Res> {
  __$SupportAttachmentModelCopyWithImpl(this._self, this._then);

  final _SupportAttachmentModel _self;
  final $Res Function(_SupportAttachmentModel) _then;

/// Create a copy of SupportAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? contentType = null,Object? sizeBytes = null,}) {
  return _then(_SupportAttachmentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SupportPersonModel {

 String get id; String get displayName; String get username;
/// Create a copy of SupportPersonModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportPersonModelCopyWith<SupportPersonModel> get copyWith => _$SupportPersonModelCopyWithImpl<SupportPersonModel>(this as SupportPersonModel, _$identity);

  /// Serializes this SupportPersonModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportPersonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username);

@override
String toString() {
  return 'SupportPersonModel(id: $id, displayName: $displayName, username: $username)';
}


}

/// @nodoc
abstract mixin class $SupportPersonModelCopyWith<$Res>  {
  factory $SupportPersonModelCopyWith(SupportPersonModel value, $Res Function(SupportPersonModel) _then) = _$SupportPersonModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username
});




}
/// @nodoc
class _$SupportPersonModelCopyWithImpl<$Res>
    implements $SupportPersonModelCopyWith<$Res> {
  _$SupportPersonModelCopyWithImpl(this._self, this._then);

  final SupportPersonModel _self;
  final $Res Function(SupportPersonModel) _then;

/// Create a copy of SupportPersonModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportPersonModel].
extension SupportPersonModelPatterns on SupportPersonModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportPersonModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportPersonModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportPersonModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportPersonModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportPersonModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportPersonModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportPersonModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username)  $default,) {final _that = this;
switch (_that) {
case _SupportPersonModel():
return $default(_that.id,_that.displayName,_that.username);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username)?  $default,) {final _that = this;
switch (_that) {
case _SupportPersonModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportPersonModel extends SupportPersonModel {
  const _SupportPersonModel({required this.id, this.displayName = '', this.username = ''}): super._();
  factory _SupportPersonModel.fromJson(Map<String, dynamic> json) => _$SupportPersonModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String username;

/// Create a copy of SupportPersonModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportPersonModelCopyWith<_SupportPersonModel> get copyWith => __$SupportPersonModelCopyWithImpl<_SupportPersonModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportPersonModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportPersonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username);

@override
String toString() {
  return 'SupportPersonModel(id: $id, displayName: $displayName, username: $username)';
}


}

/// @nodoc
abstract mixin class _$SupportPersonModelCopyWith<$Res> implements $SupportPersonModelCopyWith<$Res> {
  factory _$SupportPersonModelCopyWith(_SupportPersonModel value, $Res Function(_SupportPersonModel) _then) = __$SupportPersonModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username
});




}
/// @nodoc
class __$SupportPersonModelCopyWithImpl<$Res>
    implements _$SupportPersonModelCopyWith<$Res> {
  __$SupportPersonModelCopyWithImpl(this._self, this._then);

  final _SupportPersonModel _self;
  final $Res Function(_SupportPersonModel) _then;

/// Create a copy of SupportPersonModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,}) {
  return _then(_SupportPersonModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SupportMessageModel {

 String get id; bool get fromSupport; String get body; List<SupportAttachmentModel> get attachments; DateTime get createdAt; bool get isInternalNote; SupportPersonModel? get author;
/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportMessageModelCopyWith<SupportMessageModel> get copyWith => _$SupportMessageModelCopyWithImpl<SupportMessageModel>(this as SupportMessageModel, _$identity);

  /// Serializes this SupportMessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fromSupport, fromSupport) || other.fromSupport == fromSupport)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isInternalNote, isInternalNote) || other.isInternalNote == isInternalNote)&&(identical(other.author, author) || other.author == author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromSupport,body,const DeepCollectionEquality().hash(attachments),createdAt,isInternalNote,author);

@override
String toString() {
  return 'SupportMessageModel(id: $id, fromSupport: $fromSupport, body: $body, attachments: $attachments, createdAt: $createdAt, isInternalNote: $isInternalNote, author: $author)';
}


}

/// @nodoc
abstract mixin class $SupportMessageModelCopyWith<$Res>  {
  factory $SupportMessageModelCopyWith(SupportMessageModel value, $Res Function(SupportMessageModel) _then) = _$SupportMessageModelCopyWithImpl;
@useResult
$Res call({
 String id, bool fromSupport, String body, List<SupportAttachmentModel> attachments, DateTime createdAt, bool isInternalNote, SupportPersonModel? author
});


$SupportPersonModelCopyWith<$Res>? get author;

}
/// @nodoc
class _$SupportMessageModelCopyWithImpl<$Res>
    implements $SupportMessageModelCopyWith<$Res> {
  _$SupportMessageModelCopyWithImpl(this._self, this._then);

  final SupportMessageModel _self;
  final $Res Function(SupportMessageModel) _then;

/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromSupport = null,Object? body = null,Object? attachments = null,Object? createdAt = null,Object? isInternalNote = null,Object? author = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromSupport: null == fromSupport ? _self.fromSupport : fromSupport // ignore: cast_nullable_to_non_nullable
as bool,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<SupportAttachmentModel>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isInternalNote: null == isInternalNote ? _self.isInternalNote : isInternalNote // ignore: cast_nullable_to_non_nullable
as bool,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as SupportPersonModel?,
  ));
}
/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportPersonModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $SupportPersonModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportMessageModel].
extension SupportMessageModelPatterns on SupportMessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportMessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportMessageModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportMessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportMessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  bool fromSupport,  String body,  List<SupportAttachmentModel> attachments,  DateTime createdAt,  bool isInternalNote,  SupportPersonModel? author)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
return $default(_that.id,_that.fromSupport,_that.body,_that.attachments,_that.createdAt,_that.isInternalNote,_that.author);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  bool fromSupport,  String body,  List<SupportAttachmentModel> attachments,  DateTime createdAt,  bool isInternalNote,  SupportPersonModel? author)  $default,) {final _that = this;
switch (_that) {
case _SupportMessageModel():
return $default(_that.id,_that.fromSupport,_that.body,_that.attachments,_that.createdAt,_that.isInternalNote,_that.author);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  bool fromSupport,  String body,  List<SupportAttachmentModel> attachments,  DateTime createdAt,  bool isInternalNote,  SupportPersonModel? author)?  $default,) {final _that = this;
switch (_that) {
case _SupportMessageModel() when $default != null:
return $default(_that.id,_that.fromSupport,_that.body,_that.attachments,_that.createdAt,_that.isInternalNote,_that.author);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportMessageModel extends SupportMessageModel {
  const _SupportMessageModel({required this.id, this.fromSupport = false, this.body = '', final  List<SupportAttachmentModel> attachments = const <SupportAttachmentModel>[], required this.createdAt, this.isInternalNote = false, this.author}): _attachments = attachments,super._();
  factory _SupportMessageModel.fromJson(Map<String, dynamic> json) => _$SupportMessageModelFromJson(json);

@override final  String id;
@override@JsonKey() final  bool fromSupport;
@override@JsonKey() final  String body;
 final  List<SupportAttachmentModel> _attachments;
@override@JsonKey() List<SupportAttachmentModel> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

@override final  DateTime createdAt;
@override@JsonKey() final  bool isInternalNote;
@override final  SupportPersonModel? author;

/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportMessageModelCopyWith<_SupportMessageModel> get copyWith => __$SupportMessageModelCopyWithImpl<_SupportMessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportMessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fromSupport, fromSupport) || other.fromSupport == fromSupport)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isInternalNote, isInternalNote) || other.isInternalNote == isInternalNote)&&(identical(other.author, author) || other.author == author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromSupport,body,const DeepCollectionEquality().hash(_attachments),createdAt,isInternalNote,author);

@override
String toString() {
  return 'SupportMessageModel(id: $id, fromSupport: $fromSupport, body: $body, attachments: $attachments, createdAt: $createdAt, isInternalNote: $isInternalNote, author: $author)';
}


}

/// @nodoc
abstract mixin class _$SupportMessageModelCopyWith<$Res> implements $SupportMessageModelCopyWith<$Res> {
  factory _$SupportMessageModelCopyWith(_SupportMessageModel value, $Res Function(_SupportMessageModel) _then) = __$SupportMessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, bool fromSupport, String body, List<SupportAttachmentModel> attachments, DateTime createdAt, bool isInternalNote, SupportPersonModel? author
});


@override $SupportPersonModelCopyWith<$Res>? get author;

}
/// @nodoc
class __$SupportMessageModelCopyWithImpl<$Res>
    implements _$SupportMessageModelCopyWith<$Res> {
  __$SupportMessageModelCopyWithImpl(this._self, this._then);

  final _SupportMessageModel _self;
  final $Res Function(_SupportMessageModel) _then;

/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromSupport = null,Object? body = null,Object? attachments = null,Object? createdAt = null,Object? isInternalNote = null,Object? author = freezed,}) {
  return _then(_SupportMessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromSupport: null == fromSupport ? _self.fromSupport : fromSupport // ignore: cast_nullable_to_non_nullable
as bool,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<SupportAttachmentModel>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isInternalNote: null == isInternalNote ? _self.isInternalNote : isInternalNote // ignore: cast_nullable_to_non_nullable
as bool,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as SupportPersonModel?,
  ));
}

/// Create a copy of SupportMessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportPersonModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $SupportPersonModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$SupportLastMessageModel {

 bool get fromSupport; bool get isInternalNote; String get excerpt; DateTime get createdAt;
/// Create a copy of SupportLastMessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportLastMessageModelCopyWith<SupportLastMessageModel> get copyWith => _$SupportLastMessageModelCopyWithImpl<SupportLastMessageModel>(this as SupportLastMessageModel, _$identity);

  /// Serializes this SupportLastMessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportLastMessageModel&&(identical(other.fromSupport, fromSupport) || other.fromSupport == fromSupport)&&(identical(other.isInternalNote, isInternalNote) || other.isInternalNote == isInternalNote)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fromSupport,isInternalNote,excerpt,createdAt);

@override
String toString() {
  return 'SupportLastMessageModel(fromSupport: $fromSupport, isInternalNote: $isInternalNote, excerpt: $excerpt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SupportLastMessageModelCopyWith<$Res>  {
  factory $SupportLastMessageModelCopyWith(SupportLastMessageModel value, $Res Function(SupportLastMessageModel) _then) = _$SupportLastMessageModelCopyWithImpl;
@useResult
$Res call({
 bool fromSupport, bool isInternalNote, String excerpt, DateTime createdAt
});




}
/// @nodoc
class _$SupportLastMessageModelCopyWithImpl<$Res>
    implements $SupportLastMessageModelCopyWith<$Res> {
  _$SupportLastMessageModelCopyWithImpl(this._self, this._then);

  final SupportLastMessageModel _self;
  final $Res Function(SupportLastMessageModel) _then;

/// Create a copy of SupportLastMessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromSupport = null,Object? isInternalNote = null,Object? excerpt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
fromSupport: null == fromSupport ? _self.fromSupport : fromSupport // ignore: cast_nullable_to_non_nullable
as bool,isInternalNote: null == isInternalNote ? _self.isInternalNote : isInternalNote // ignore: cast_nullable_to_non_nullable
as bool,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportLastMessageModel].
extension SupportLastMessageModelPatterns on SupportLastMessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportLastMessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportLastMessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportLastMessageModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportLastMessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportLastMessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportLastMessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool fromSupport,  bool isInternalNote,  String excerpt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportLastMessageModel() when $default != null:
return $default(_that.fromSupport,_that.isInternalNote,_that.excerpt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool fromSupport,  bool isInternalNote,  String excerpt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SupportLastMessageModel():
return $default(_that.fromSupport,_that.isInternalNote,_that.excerpt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool fromSupport,  bool isInternalNote,  String excerpt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportLastMessageModel() when $default != null:
return $default(_that.fromSupport,_that.isInternalNote,_that.excerpt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportLastMessageModel extends SupportLastMessageModel {
  const _SupportLastMessageModel({this.fromSupport = false, this.isInternalNote = false, this.excerpt = '', required this.createdAt}): super._();
  factory _SupportLastMessageModel.fromJson(Map<String, dynamic> json) => _$SupportLastMessageModelFromJson(json);

@override@JsonKey() final  bool fromSupport;
@override@JsonKey() final  bool isInternalNote;
@override@JsonKey() final  String excerpt;
@override final  DateTime createdAt;

/// Create a copy of SupportLastMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportLastMessageModelCopyWith<_SupportLastMessageModel> get copyWith => __$SupportLastMessageModelCopyWithImpl<_SupportLastMessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportLastMessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportLastMessageModel&&(identical(other.fromSupport, fromSupport) || other.fromSupport == fromSupport)&&(identical(other.isInternalNote, isInternalNote) || other.isInternalNote == isInternalNote)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fromSupport,isInternalNote,excerpt,createdAt);

@override
String toString() {
  return 'SupportLastMessageModel(fromSupport: $fromSupport, isInternalNote: $isInternalNote, excerpt: $excerpt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SupportLastMessageModelCopyWith<$Res> implements $SupportLastMessageModelCopyWith<$Res> {
  factory _$SupportLastMessageModelCopyWith(_SupportLastMessageModel value, $Res Function(_SupportLastMessageModel) _then) = __$SupportLastMessageModelCopyWithImpl;
@override @useResult
$Res call({
 bool fromSupport, bool isInternalNote, String excerpt, DateTime createdAt
});




}
/// @nodoc
class __$SupportLastMessageModelCopyWithImpl<$Res>
    implements _$SupportLastMessageModelCopyWith<$Res> {
  __$SupportLastMessageModelCopyWithImpl(this._self, this._then);

  final _SupportLastMessageModel _self;
  final $Res Function(_SupportLastMessageModel) _then;

/// Create a copy of SupportLastMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromSupport = null,Object? isInternalNote = null,Object? excerpt = null,Object? createdAt = null,}) {
  return _then(_SupportLastMessageModel(
fromSupport: null == fromSupport ? _self.fromSupport : fromSupport // ignore: cast_nullable_to_non_nullable
as bool,isInternalNote: null == isInternalNote ? _self.isInternalNote : isInternalNote // ignore: cast_nullable_to_non_nullable
as bool,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SupportTicketModel {

 String get id; int get number; String? get category; String get subject; String? get status; DateTime get createdAt; DateTime get updatedAt; SupportLastMessageModel? get lastMessage; DateTime? get closedAt; bool get canReopen; SupportDeviceModel? get device; List<SupportMessageModel> get messages;
/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketModelCopyWith<SupportTicketModel> get copyWith => _$SupportTicketModelCopyWithImpl<SupportTicketModel>(this as SupportTicketModel, _$identity);

  /// Serializes this SupportTicketModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicketModel&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.category, category) || other.category == category)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.canReopen, canReopen) || other.canReopen == canReopen)&&(identical(other.device, device) || other.device == device)&&const DeepCollectionEquality().equals(other.messages, messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,category,subject,status,createdAt,updatedAt,lastMessage,closedAt,canReopen,device,const DeepCollectionEquality().hash(messages));

@override
String toString() {
  return 'SupportTicketModel(id: $id, number: $number, category: $category, subject: $subject, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, lastMessage: $lastMessage, closedAt: $closedAt, canReopen: $canReopen, device: $device, messages: $messages)';
}


}

/// @nodoc
abstract mixin class $SupportTicketModelCopyWith<$Res>  {
  factory $SupportTicketModelCopyWith(SupportTicketModel value, $Res Function(SupportTicketModel) _then) = _$SupportTicketModelCopyWithImpl;
@useResult
$Res call({
 String id, int number, String? category, String subject, String? status, DateTime createdAt, DateTime updatedAt, SupportLastMessageModel? lastMessage, DateTime? closedAt, bool canReopen, SupportDeviceModel? device, List<SupportMessageModel> messages
});


$SupportLastMessageModelCopyWith<$Res>? get lastMessage;$SupportDeviceModelCopyWith<$Res>? get device;

}
/// @nodoc
class _$SupportTicketModelCopyWithImpl<$Res>
    implements $SupportTicketModelCopyWith<$Res> {
  _$SupportTicketModelCopyWithImpl(this._self, this._then);

  final SupportTicketModel _self;
  final $Res Function(SupportTicketModel) _then;

/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? category = freezed,Object? subject = null,Object? status = freezed,Object? createdAt = null,Object? updatedAt = null,Object? lastMessage = freezed,Object? closedAt = freezed,Object? canReopen = null,Object? device = freezed,Object? messages = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as SupportLastMessageModel?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canReopen: null == canReopen ? _self.canReopen : canReopen // ignore: cast_nullable_to_non_nullable
as bool,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as SupportDeviceModel?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessageModel>,
  ));
}
/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportLastMessageModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $SupportLastMessageModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportDeviceModelCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $SupportDeviceModelCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportTicketModel].
extension SupportTicketModelPatterns on SupportTicketModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicketModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicketModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicketModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicketModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicketModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicketModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int number,  String? category,  String subject,  String? status,  DateTime createdAt,  DateTime updatedAt,  SupportLastMessageModel? lastMessage,  DateTime? closedAt,  bool canReopen,  SupportDeviceModel? device,  List<SupportMessageModel> messages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicketModel() when $default != null:
return $default(_that.id,_that.number,_that.category,_that.subject,_that.status,_that.createdAt,_that.updatedAt,_that.lastMessage,_that.closedAt,_that.canReopen,_that.device,_that.messages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int number,  String? category,  String subject,  String? status,  DateTime createdAt,  DateTime updatedAt,  SupportLastMessageModel? lastMessage,  DateTime? closedAt,  bool canReopen,  SupportDeviceModel? device,  List<SupportMessageModel> messages)  $default,) {final _that = this;
switch (_that) {
case _SupportTicketModel():
return $default(_that.id,_that.number,_that.category,_that.subject,_that.status,_that.createdAt,_that.updatedAt,_that.lastMessage,_that.closedAt,_that.canReopen,_that.device,_that.messages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int number,  String? category,  String subject,  String? status,  DateTime createdAt,  DateTime updatedAt,  SupportLastMessageModel? lastMessage,  DateTime? closedAt,  bool canReopen,  SupportDeviceModel? device,  List<SupportMessageModel> messages)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicketModel() when $default != null:
return $default(_that.id,_that.number,_that.category,_that.subject,_that.status,_that.createdAt,_that.updatedAt,_that.lastMessage,_that.closedAt,_that.canReopen,_that.device,_that.messages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTicketModel extends SupportTicketModel {
  const _SupportTicketModel({required this.id, this.number = 0, this.category, this.subject = '', this.status, required this.createdAt, required this.updatedAt, this.lastMessage, this.closedAt, this.canReopen = false, this.device, final  List<SupportMessageModel> messages = const <SupportMessageModel>[]}): _messages = messages,super._();
  factory _SupportTicketModel.fromJson(Map<String, dynamic> json) => _$SupportTicketModelFromJson(json);

@override final  String id;
@override@JsonKey() final  int number;
@override final  String? category;
@override@JsonKey() final  String subject;
@override final  String? status;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  SupportLastMessageModel? lastMessage;
@override final  DateTime? closedAt;
@override@JsonKey() final  bool canReopen;
@override final  SupportDeviceModel? device;
 final  List<SupportMessageModel> _messages;
@override@JsonKey() List<SupportMessageModel> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}


/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketModelCopyWith<_SupportTicketModel> get copyWith => __$SupportTicketModelCopyWithImpl<_SupportTicketModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicketModel&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.category, category) || other.category == category)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.canReopen, canReopen) || other.canReopen == canReopen)&&(identical(other.device, device) || other.device == device)&&const DeepCollectionEquality().equals(other._messages, _messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,category,subject,status,createdAt,updatedAt,lastMessage,closedAt,canReopen,device,const DeepCollectionEquality().hash(_messages));

@override
String toString() {
  return 'SupportTicketModel(id: $id, number: $number, category: $category, subject: $subject, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, lastMessage: $lastMessage, closedAt: $closedAt, canReopen: $canReopen, device: $device, messages: $messages)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketModelCopyWith<$Res> implements $SupportTicketModelCopyWith<$Res> {
  factory _$SupportTicketModelCopyWith(_SupportTicketModel value, $Res Function(_SupportTicketModel) _then) = __$SupportTicketModelCopyWithImpl;
@override @useResult
$Res call({
 String id, int number, String? category, String subject, String? status, DateTime createdAt, DateTime updatedAt, SupportLastMessageModel? lastMessage, DateTime? closedAt, bool canReopen, SupportDeviceModel? device, List<SupportMessageModel> messages
});


@override $SupportLastMessageModelCopyWith<$Res>? get lastMessage;@override $SupportDeviceModelCopyWith<$Res>? get device;

}
/// @nodoc
class __$SupportTicketModelCopyWithImpl<$Res>
    implements _$SupportTicketModelCopyWith<$Res> {
  __$SupportTicketModelCopyWithImpl(this._self, this._then);

  final _SupportTicketModel _self;
  final $Res Function(_SupportTicketModel) _then;

/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? category = freezed,Object? subject = null,Object? status = freezed,Object? createdAt = null,Object? updatedAt = null,Object? lastMessage = freezed,Object? closedAt = freezed,Object? canReopen = null,Object? device = freezed,Object? messages = null,}) {
  return _then(_SupportTicketModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as SupportLastMessageModel?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canReopen: null == canReopen ? _self.canReopen : canReopen // ignore: cast_nullable_to_non_nullable
as bool,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as SupportDeviceModel?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessageModel>,
  ));
}

/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportLastMessageModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $SupportLastMessageModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of SupportTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportDeviceModelCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $SupportDeviceModelCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}


/// @nodoc
mixin _$SupportTicketPageModel {

 List<SupportTicketModel> get items; String? get nextCursor;
/// Create a copy of SupportTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketPageModelCopyWith<SupportTicketPageModel> get copyWith => _$SupportTicketPageModelCopyWithImpl<SupportTicketPageModel>(this as SupportTicketPageModel, _$identity);

  /// Serializes this SupportTicketPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicketPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'SupportTicketPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $SupportTicketPageModelCopyWith<$Res>  {
  factory $SupportTicketPageModelCopyWith(SupportTicketPageModel value, $Res Function(SupportTicketPageModel) _then) = _$SupportTicketPageModelCopyWithImpl;
@useResult
$Res call({
 List<SupportTicketModel> items, String? nextCursor
});




}
/// @nodoc
class _$SupportTicketPageModelCopyWithImpl<$Res>
    implements $SupportTicketPageModelCopyWith<$Res> {
  _$SupportTicketPageModelCopyWithImpl(this._self, this._then);

  final SupportTicketPageModel _self;
  final $Res Function(SupportTicketPageModel) _then;

/// Create a copy of SupportTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SupportTicketModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportTicketPageModel].
extension SupportTicketPageModelPatterns on SupportTicketPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicketPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicketPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicketPageModel value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicketPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicketPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicketPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SupportTicketModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicketPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SupportTicketModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _SupportTicketPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SupportTicketModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicketPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTicketPageModel implements SupportTicketPageModel {
  const _SupportTicketPageModel({final  List<SupportTicketModel> items = const <SupportTicketModel>[], this.nextCursor}): _items = items;
  factory _SupportTicketPageModel.fromJson(Map<String, dynamic> json) => _$SupportTicketPageModelFromJson(json);

 final  List<SupportTicketModel> _items;
@override@JsonKey() List<SupportTicketModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of SupportTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketPageModelCopyWith<_SupportTicketPageModel> get copyWith => __$SupportTicketPageModelCopyWithImpl<_SupportTicketPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicketPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'SupportTicketPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketPageModelCopyWith<$Res> implements $SupportTicketPageModelCopyWith<$Res> {
  factory _$SupportTicketPageModelCopyWith(_SupportTicketPageModel value, $Res Function(_SupportTicketPageModel) _then) = __$SupportTicketPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<SupportTicketModel> items, String? nextCursor
});




}
/// @nodoc
class __$SupportTicketPageModelCopyWithImpl<$Res>
    implements _$SupportTicketPageModelCopyWith<$Res> {
  __$SupportTicketPageModelCopyWithImpl(this._self, this._then);

  final _SupportTicketPageModel _self;
  final $Res Function(_SupportTicketPageModel) _then;

/// Create a copy of SupportTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_SupportTicketPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SupportTicketModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AdminTicketModel {

 String get id; int get number; String? get category; String get subject; String? get status; AuthorModel get user; DateTime get createdAt; DateTime? get waitingSince; SupportLastMessageModel? get lastMessage; DateTime? get closedAt;// The page (`GET /admin/support/tickets/{id}`).
 SupportDeviceModel? get device; List<SupportMessageModel> get messages; String? get closedBy; AdminTicketMemberModel? get member; AdminTicketReportsModel? get reportsFiled; int? get reportsAgainst; List<AdminTicketModerationModel>? get moderation;
/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketModelCopyWith<AdminTicketModel> get copyWith => _$AdminTicketModelCopyWithImpl<AdminTicketModel>(this as AdminTicketModel, _$identity);

  /// Serializes this AdminTicketModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketModel&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.category, category) || other.category == category)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.waitingSince, waitingSince) || other.waitingSince == waitingSince)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.device, device) || other.device == device)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.closedBy, closedBy) || other.closedBy == closedBy)&&(identical(other.member, member) || other.member == member)&&(identical(other.reportsFiled, reportsFiled) || other.reportsFiled == reportsFiled)&&(identical(other.reportsAgainst, reportsAgainst) || other.reportsAgainst == reportsAgainst)&&const DeepCollectionEquality().equals(other.moderation, moderation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,category,subject,status,user,createdAt,waitingSince,lastMessage,closedAt,device,const DeepCollectionEquality().hash(messages),closedBy,member,reportsFiled,reportsAgainst,const DeepCollectionEquality().hash(moderation));

@override
String toString() {
  return 'AdminTicketModel(id: $id, number: $number, category: $category, subject: $subject, status: $status, user: $user, createdAt: $createdAt, waitingSince: $waitingSince, lastMessage: $lastMessage, closedAt: $closedAt, device: $device, messages: $messages, closedBy: $closedBy, member: $member, reportsFiled: $reportsFiled, reportsAgainst: $reportsAgainst, moderation: $moderation)';
}


}

/// @nodoc
abstract mixin class $AdminTicketModelCopyWith<$Res>  {
  factory $AdminTicketModelCopyWith(AdminTicketModel value, $Res Function(AdminTicketModel) _then) = _$AdminTicketModelCopyWithImpl;
@useResult
$Res call({
 String id, int number, String? category, String subject, String? status, AuthorModel user, DateTime createdAt, DateTime? waitingSince, SupportLastMessageModel? lastMessage, DateTime? closedAt, SupportDeviceModel? device, List<SupportMessageModel> messages, String? closedBy, AdminTicketMemberModel? member, AdminTicketReportsModel? reportsFiled, int? reportsAgainst, List<AdminTicketModerationModel>? moderation
});


$AuthorModelCopyWith<$Res> get user;$SupportLastMessageModelCopyWith<$Res>? get lastMessage;$SupportDeviceModelCopyWith<$Res>? get device;$AdminTicketMemberModelCopyWith<$Res>? get member;$AdminTicketReportsModelCopyWith<$Res>? get reportsFiled;

}
/// @nodoc
class _$AdminTicketModelCopyWithImpl<$Res>
    implements $AdminTicketModelCopyWith<$Res> {
  _$AdminTicketModelCopyWithImpl(this._self, this._then);

  final AdminTicketModel _self;
  final $Res Function(AdminTicketModel) _then;

/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? category = freezed,Object? subject = null,Object? status = freezed,Object? user = null,Object? createdAt = null,Object? waitingSince = freezed,Object? lastMessage = freezed,Object? closedAt = freezed,Object? device = freezed,Object? messages = null,Object? closedBy = freezed,Object? member = freezed,Object? reportsFiled = freezed,Object? reportsAgainst = freezed,Object? moderation = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthorModel,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,waitingSince: freezed == waitingSince ? _self.waitingSince : waitingSince // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as SupportLastMessageModel?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as SupportDeviceModel?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessageModel>,closedBy: freezed == closedBy ? _self.closedBy : closedBy // ignore: cast_nullable_to_non_nullable
as String?,member: freezed == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as AdminTicketMemberModel?,reportsFiled: freezed == reportsFiled ? _self.reportsFiled : reportsFiled // ignore: cast_nullable_to_non_nullable
as AdminTicketReportsModel?,reportsAgainst: freezed == reportsAgainst ? _self.reportsAgainst : reportsAgainst // ignore: cast_nullable_to_non_nullable
as int?,moderation: freezed == moderation ? _self.moderation : moderation // ignore: cast_nullable_to_non_nullable
as List<AdminTicketModerationModel>?,
  ));
}
/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get user {
  
  return $AuthorModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportLastMessageModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $SupportLastMessageModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportDeviceModelCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $SupportDeviceModelCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminTicketMemberModelCopyWith<$Res>? get member {
    if (_self.member == null) {
    return null;
  }

  return $AdminTicketMemberModelCopyWith<$Res>(_self.member!, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminTicketReportsModelCopyWith<$Res>? get reportsFiled {
    if (_self.reportsFiled == null) {
    return null;
  }

  return $AdminTicketReportsModelCopyWith<$Res>(_self.reportsFiled!, (value) {
    return _then(_self.copyWith(reportsFiled: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminTicketModel].
extension AdminTicketModelPatterns on AdminTicketModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int number,  String? category,  String subject,  String? status,  AuthorModel user,  DateTime createdAt,  DateTime? waitingSince,  SupportLastMessageModel? lastMessage,  DateTime? closedAt,  SupportDeviceModel? device,  List<SupportMessageModel> messages,  String? closedBy,  AdminTicketMemberModel? member,  AdminTicketReportsModel? reportsFiled,  int? reportsAgainst,  List<AdminTicketModerationModel>? moderation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketModel() when $default != null:
return $default(_that.id,_that.number,_that.category,_that.subject,_that.status,_that.user,_that.createdAt,_that.waitingSince,_that.lastMessage,_that.closedAt,_that.device,_that.messages,_that.closedBy,_that.member,_that.reportsFiled,_that.reportsAgainst,_that.moderation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int number,  String? category,  String subject,  String? status,  AuthorModel user,  DateTime createdAt,  DateTime? waitingSince,  SupportLastMessageModel? lastMessage,  DateTime? closedAt,  SupportDeviceModel? device,  List<SupportMessageModel> messages,  String? closedBy,  AdminTicketMemberModel? member,  AdminTicketReportsModel? reportsFiled,  int? reportsAgainst,  List<AdminTicketModerationModel>? moderation)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketModel():
return $default(_that.id,_that.number,_that.category,_that.subject,_that.status,_that.user,_that.createdAt,_that.waitingSince,_that.lastMessage,_that.closedAt,_that.device,_that.messages,_that.closedBy,_that.member,_that.reportsFiled,_that.reportsAgainst,_that.moderation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int number,  String? category,  String subject,  String? status,  AuthorModel user,  DateTime createdAt,  DateTime? waitingSince,  SupportLastMessageModel? lastMessage,  DateTime? closedAt,  SupportDeviceModel? device,  List<SupportMessageModel> messages,  String? closedBy,  AdminTicketMemberModel? member,  AdminTicketReportsModel? reportsFiled,  int? reportsAgainst,  List<AdminTicketModerationModel>? moderation)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketModel() when $default != null:
return $default(_that.id,_that.number,_that.category,_that.subject,_that.status,_that.user,_that.createdAt,_that.waitingSince,_that.lastMessage,_that.closedAt,_that.device,_that.messages,_that.closedBy,_that.member,_that.reportsFiled,_that.reportsAgainst,_that.moderation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketModel extends AdminTicketModel {
  const _AdminTicketModel({required this.id, this.number = 0, this.category, this.subject = '', this.status, required this.user, required this.createdAt, this.waitingSince, this.lastMessage, this.closedAt, this.device, final  List<SupportMessageModel> messages = const <SupportMessageModel>[], this.closedBy, this.member, this.reportsFiled, this.reportsAgainst, final  List<AdminTicketModerationModel>? moderation}): _messages = messages,_moderation = moderation,super._();
  factory _AdminTicketModel.fromJson(Map<String, dynamic> json) => _$AdminTicketModelFromJson(json);

@override final  String id;
@override@JsonKey() final  int number;
@override final  String? category;
@override@JsonKey() final  String subject;
@override final  String? status;
@override final  AuthorModel user;
@override final  DateTime createdAt;
@override final  DateTime? waitingSince;
@override final  SupportLastMessageModel? lastMessage;
@override final  DateTime? closedAt;
// The page (`GET /admin/support/tickets/{id}`).
@override final  SupportDeviceModel? device;
 final  List<SupportMessageModel> _messages;
@override@JsonKey() List<SupportMessageModel> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override final  String? closedBy;
@override final  AdminTicketMemberModel? member;
@override final  AdminTicketReportsModel? reportsFiled;
@override final  int? reportsAgainst;
 final  List<AdminTicketModerationModel>? _moderation;
@override List<AdminTicketModerationModel>? get moderation {
  final value = _moderation;
  if (value == null) return null;
  if (_moderation is EqualUnmodifiableListView) return _moderation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketModelCopyWith<_AdminTicketModel> get copyWith => __$AdminTicketModelCopyWithImpl<_AdminTicketModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketModel&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.category, category) || other.category == category)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.waitingSince, waitingSince) || other.waitingSince == waitingSince)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.device, device) || other.device == device)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.closedBy, closedBy) || other.closedBy == closedBy)&&(identical(other.member, member) || other.member == member)&&(identical(other.reportsFiled, reportsFiled) || other.reportsFiled == reportsFiled)&&(identical(other.reportsAgainst, reportsAgainst) || other.reportsAgainst == reportsAgainst)&&const DeepCollectionEquality().equals(other._moderation, _moderation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,category,subject,status,user,createdAt,waitingSince,lastMessage,closedAt,device,const DeepCollectionEquality().hash(_messages),closedBy,member,reportsFiled,reportsAgainst,const DeepCollectionEquality().hash(_moderation));

@override
String toString() {
  return 'AdminTicketModel(id: $id, number: $number, category: $category, subject: $subject, status: $status, user: $user, createdAt: $createdAt, waitingSince: $waitingSince, lastMessage: $lastMessage, closedAt: $closedAt, device: $device, messages: $messages, closedBy: $closedBy, member: $member, reportsFiled: $reportsFiled, reportsAgainst: $reportsAgainst, moderation: $moderation)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketModelCopyWith<$Res> implements $AdminTicketModelCopyWith<$Res> {
  factory _$AdminTicketModelCopyWith(_AdminTicketModel value, $Res Function(_AdminTicketModel) _then) = __$AdminTicketModelCopyWithImpl;
@override @useResult
$Res call({
 String id, int number, String? category, String subject, String? status, AuthorModel user, DateTime createdAt, DateTime? waitingSince, SupportLastMessageModel? lastMessage, DateTime? closedAt, SupportDeviceModel? device, List<SupportMessageModel> messages, String? closedBy, AdminTicketMemberModel? member, AdminTicketReportsModel? reportsFiled, int? reportsAgainst, List<AdminTicketModerationModel>? moderation
});


@override $AuthorModelCopyWith<$Res> get user;@override $SupportLastMessageModelCopyWith<$Res>? get lastMessage;@override $SupportDeviceModelCopyWith<$Res>? get device;@override $AdminTicketMemberModelCopyWith<$Res>? get member;@override $AdminTicketReportsModelCopyWith<$Res>? get reportsFiled;

}
/// @nodoc
class __$AdminTicketModelCopyWithImpl<$Res>
    implements _$AdminTicketModelCopyWith<$Res> {
  __$AdminTicketModelCopyWithImpl(this._self, this._then);

  final _AdminTicketModel _self;
  final $Res Function(_AdminTicketModel) _then;

/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? category = freezed,Object? subject = null,Object? status = freezed,Object? user = null,Object? createdAt = null,Object? waitingSince = freezed,Object? lastMessage = freezed,Object? closedAt = freezed,Object? device = freezed,Object? messages = null,Object? closedBy = freezed,Object? member = freezed,Object? reportsFiled = freezed,Object? reportsAgainst = freezed,Object? moderation = freezed,}) {
  return _then(_AdminTicketModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthorModel,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,waitingSince: freezed == waitingSince ? _self.waitingSince : waitingSince // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as SupportLastMessageModel?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as SupportDeviceModel?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessageModel>,closedBy: freezed == closedBy ? _self.closedBy : closedBy // ignore: cast_nullable_to_non_nullable
as String?,member: freezed == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as AdminTicketMemberModel?,reportsFiled: freezed == reportsFiled ? _self.reportsFiled : reportsFiled // ignore: cast_nullable_to_non_nullable
as AdminTicketReportsModel?,reportsAgainst: freezed == reportsAgainst ? _self.reportsAgainst : reportsAgainst // ignore: cast_nullable_to_non_nullable
as int?,moderation: freezed == moderation ? _self._moderation : moderation // ignore: cast_nullable_to_non_nullable
as List<AdminTicketModerationModel>?,
  ));
}

/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get user {
  
  return $AuthorModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportLastMessageModelCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $SupportLastMessageModelCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportDeviceModelCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $SupportDeviceModelCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminTicketMemberModelCopyWith<$Res>? get member {
    if (_self.member == null) {
    return null;
  }

  return $AdminTicketMemberModelCopyWith<$Res>(_self.member!, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of AdminTicketModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminTicketReportsModelCopyWith<$Res>? get reportsFiled {
    if (_self.reportsFiled == null) {
    return null;
  }

  return $AdminTicketReportsModelCopyWith<$Res>(_self.reportsFiled!, (value) {
    return _then(_self.copyWith(reportsFiled: value));
  });
}
}


/// @nodoc
mixin _$AdminTicketMemberModel {

 String? get status; DateTime? get suspendedUntil; DateTime get joinedAt; List<String> get signInMethods; int get ticketCount;
/// Create a copy of AdminTicketMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketMemberModelCopyWith<AdminTicketMemberModel> get copyWith => _$AdminTicketMemberModelCopyWithImpl<AdminTicketMemberModel>(this as AdminTicketMemberModel, _$identity);

  /// Serializes this AdminTicketMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketMemberModel&&(identical(other.status, status) || other.status == status)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&const DeepCollectionEquality().equals(other.signInMethods, signInMethods)&&(identical(other.ticketCount, ticketCount) || other.ticketCount == ticketCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,suspendedUntil,joinedAt,const DeepCollectionEquality().hash(signInMethods),ticketCount);

@override
String toString() {
  return 'AdminTicketMemberModel(status: $status, suspendedUntil: $suspendedUntil, joinedAt: $joinedAt, signInMethods: $signInMethods, ticketCount: $ticketCount)';
}


}

/// @nodoc
abstract mixin class $AdminTicketMemberModelCopyWith<$Res>  {
  factory $AdminTicketMemberModelCopyWith(AdminTicketMemberModel value, $Res Function(AdminTicketMemberModel) _then) = _$AdminTicketMemberModelCopyWithImpl;
@useResult
$Res call({
 String? status, DateTime? suspendedUntil, DateTime joinedAt, List<String> signInMethods, int ticketCount
});




}
/// @nodoc
class _$AdminTicketMemberModelCopyWithImpl<$Res>
    implements $AdminTicketMemberModelCopyWith<$Res> {
  _$AdminTicketMemberModelCopyWithImpl(this._self, this._then);

  final AdminTicketMemberModel _self;
  final $Res Function(AdminTicketMemberModel) _then;

/// Create a copy of AdminTicketMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,Object? suspendedUntil = freezed,Object? joinedAt = null,Object? signInMethods = null,Object? ticketCount = null,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,signInMethods: null == signInMethods ? _self.signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,ticketCount: null == ticketCount ? _self.ticketCount : ticketCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketMemberModel].
extension AdminTicketMemberModelPatterns on AdminTicketMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? status,  DateTime? suspendedUntil,  DateTime joinedAt,  List<String> signInMethods,  int ticketCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketMemberModel() when $default != null:
return $default(_that.status,_that.suspendedUntil,_that.joinedAt,_that.signInMethods,_that.ticketCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? status,  DateTime? suspendedUntil,  DateTime joinedAt,  List<String> signInMethods,  int ticketCount)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketMemberModel():
return $default(_that.status,_that.suspendedUntil,_that.joinedAt,_that.signInMethods,_that.ticketCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? status,  DateTime? suspendedUntil,  DateTime joinedAt,  List<String> signInMethods,  int ticketCount)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketMemberModel() when $default != null:
return $default(_that.status,_that.suspendedUntil,_that.joinedAt,_that.signInMethods,_that.ticketCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketMemberModel extends AdminTicketMemberModel {
  const _AdminTicketMemberModel({this.status, this.suspendedUntil, required this.joinedAt, final  List<String> signInMethods = const <String>[], this.ticketCount = 0}): _signInMethods = signInMethods,super._();
  factory _AdminTicketMemberModel.fromJson(Map<String, dynamic> json) => _$AdminTicketMemberModelFromJson(json);

@override final  String? status;
@override final  DateTime? suspendedUntil;
@override final  DateTime joinedAt;
 final  List<String> _signInMethods;
@override@JsonKey() List<String> get signInMethods {
  if (_signInMethods is EqualUnmodifiableListView) return _signInMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_signInMethods);
}

@override@JsonKey() final  int ticketCount;

/// Create a copy of AdminTicketMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketMemberModelCopyWith<_AdminTicketMemberModel> get copyWith => __$AdminTicketMemberModelCopyWithImpl<_AdminTicketMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketMemberModel&&(identical(other.status, status) || other.status == status)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&const DeepCollectionEquality().equals(other._signInMethods, _signInMethods)&&(identical(other.ticketCount, ticketCount) || other.ticketCount == ticketCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,suspendedUntil,joinedAt,const DeepCollectionEquality().hash(_signInMethods),ticketCount);

@override
String toString() {
  return 'AdminTicketMemberModel(status: $status, suspendedUntil: $suspendedUntil, joinedAt: $joinedAt, signInMethods: $signInMethods, ticketCount: $ticketCount)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketMemberModelCopyWith<$Res> implements $AdminTicketMemberModelCopyWith<$Res> {
  factory _$AdminTicketMemberModelCopyWith(_AdminTicketMemberModel value, $Res Function(_AdminTicketMemberModel) _then) = __$AdminTicketMemberModelCopyWithImpl;
@override @useResult
$Res call({
 String? status, DateTime? suspendedUntil, DateTime joinedAt, List<String> signInMethods, int ticketCount
});




}
/// @nodoc
class __$AdminTicketMemberModelCopyWithImpl<$Res>
    implements _$AdminTicketMemberModelCopyWith<$Res> {
  __$AdminTicketMemberModelCopyWithImpl(this._self, this._then);

  final _AdminTicketMemberModel _self;
  final $Res Function(_AdminTicketMemberModel) _then;

/// Create a copy of AdminTicketMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,Object? suspendedUntil = freezed,Object? joinedAt = null,Object? signInMethods = null,Object? ticketCount = null,}) {
  return _then(_AdminTicketMemberModel(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,signInMethods: null == signInMethods ? _self._signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,ticketCount: null == ticketCount ? _self.ticketCount : ticketCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminTicketReportsModel {

 List<AdminTicketReportModel> get items; int get total;
/// Create a copy of AdminTicketReportsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketReportsModelCopyWith<AdminTicketReportsModel> get copyWith => _$AdminTicketReportsModelCopyWithImpl<AdminTicketReportsModel>(this as AdminTicketReportsModel, _$identity);

  /// Serializes this AdminTicketReportsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketReportsModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),total);

@override
String toString() {
  return 'AdminTicketReportsModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class $AdminTicketReportsModelCopyWith<$Res>  {
  factory $AdminTicketReportsModelCopyWith(AdminTicketReportsModel value, $Res Function(AdminTicketReportsModel) _then) = _$AdminTicketReportsModelCopyWithImpl;
@useResult
$Res call({
 List<AdminTicketReportModel> items, int total
});




}
/// @nodoc
class _$AdminTicketReportsModelCopyWithImpl<$Res>
    implements $AdminTicketReportsModelCopyWith<$Res> {
  _$AdminTicketReportsModelCopyWithImpl(this._self, this._then);

  final AdminTicketReportsModel _self;
  final $Res Function(AdminTicketReportsModel) _then;

/// Create a copy of AdminTicketReportsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminTicketReportModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketReportsModel].
extension AdminTicketReportsModelPatterns on AdminTicketReportsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketReportsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketReportsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketReportsModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketReportsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketReportsModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketReportsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminTicketReportModel> items,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketReportsModel() when $default != null:
return $default(_that.items,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminTicketReportModel> items,  int total)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketReportsModel():
return $default(_that.items,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminTicketReportModel> items,  int total)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketReportsModel() when $default != null:
return $default(_that.items,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketReportsModel implements AdminTicketReportsModel {
  const _AdminTicketReportsModel({final  List<AdminTicketReportModel> items = const <AdminTicketReportModel>[], this.total = 0}): _items = items;
  factory _AdminTicketReportsModel.fromJson(Map<String, dynamic> json) => _$AdminTicketReportsModelFromJson(json);

 final  List<AdminTicketReportModel> _items;
@override@JsonKey() List<AdminTicketReportModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int total;

/// Create a copy of AdminTicketReportsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketReportsModelCopyWith<_AdminTicketReportsModel> get copyWith => __$AdminTicketReportsModelCopyWithImpl<_AdminTicketReportsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketReportsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketReportsModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total);

@override
String toString() {
  return 'AdminTicketReportsModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketReportsModelCopyWith<$Res> implements $AdminTicketReportsModelCopyWith<$Res> {
  factory _$AdminTicketReportsModelCopyWith(_AdminTicketReportsModel value, $Res Function(_AdminTicketReportsModel) _then) = __$AdminTicketReportsModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminTicketReportModel> items, int total
});




}
/// @nodoc
class __$AdminTicketReportsModelCopyWithImpl<$Res>
    implements _$AdminTicketReportsModelCopyWith<$Res> {
  __$AdminTicketReportsModelCopyWithImpl(this._self, this._then);

  final _AdminTicketReportsModel _self;
  final $Res Function(_AdminTicketReportsModel) _then;

/// Create a copy of AdminTicketReportsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,}) {
  return _then(_AdminTicketReportsModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminTicketReportModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminTicketReportModel {

 String get id; String get targetType; String? get targetLabel; String get reason; String get status; DateTime get createdAt;
/// Create a copy of AdminTicketReportModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketReportModelCopyWith<AdminTicketReportModel> get copyWith => _$AdminTicketReportModelCopyWithImpl<AdminTicketReportModel>(this as AdminTicketReportModel, _$identity);

  /// Serializes this AdminTicketReportModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetLabel,reason,status,createdAt);

@override
String toString() {
  return 'AdminTicketReportModel(id: $id, targetType: $targetType, targetLabel: $targetLabel, reason: $reason, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AdminTicketReportModelCopyWith<$Res>  {
  factory $AdminTicketReportModelCopyWith(AdminTicketReportModel value, $Res Function(AdminTicketReportModel) _then) = _$AdminTicketReportModelCopyWithImpl;
@useResult
$Res call({
 String id, String targetType, String? targetLabel, String reason, String status, DateTime createdAt
});




}
/// @nodoc
class _$AdminTicketReportModelCopyWithImpl<$Res>
    implements $AdminTicketReportModelCopyWith<$Res> {
  _$AdminTicketReportModelCopyWithImpl(this._self, this._then);

  final AdminTicketReportModel _self;
  final $Res Function(AdminTicketReportModel) _then;

/// Create a copy of AdminTicketReportModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targetType = null,Object? targetLabel = freezed,Object? reason = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketReportModel].
extension AdminTicketReportModelPatterns on AdminTicketReportModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketReportModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketReportModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketReportModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketReportModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketReportModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketReportModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String targetType,  String? targetLabel,  String reason,  String status,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketReportModel() when $default != null:
return $default(_that.id,_that.targetType,_that.targetLabel,_that.reason,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String targetType,  String? targetLabel,  String reason,  String status,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketReportModel():
return $default(_that.id,_that.targetType,_that.targetLabel,_that.reason,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String targetType,  String? targetLabel,  String reason,  String status,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketReportModel() when $default != null:
return $default(_that.id,_that.targetType,_that.targetLabel,_that.reason,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketReportModel extends AdminTicketReportModel {
  const _AdminTicketReportModel({required this.id, this.targetType = '', this.targetLabel, this.reason = 'other', this.status = 'open', required this.createdAt}): super._();
  factory _AdminTicketReportModel.fromJson(Map<String, dynamic> json) => _$AdminTicketReportModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String targetType;
@override final  String? targetLabel;
@override@JsonKey() final  String reason;
@override@JsonKey() final  String status;
@override final  DateTime createdAt;

/// Create a copy of AdminTicketReportModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketReportModelCopyWith<_AdminTicketReportModel> get copyWith => __$AdminTicketReportModelCopyWithImpl<_AdminTicketReportModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketReportModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetLabel,reason,status,createdAt);

@override
String toString() {
  return 'AdminTicketReportModel(id: $id, targetType: $targetType, targetLabel: $targetLabel, reason: $reason, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketReportModelCopyWith<$Res> implements $AdminTicketReportModelCopyWith<$Res> {
  factory _$AdminTicketReportModelCopyWith(_AdminTicketReportModel value, $Res Function(_AdminTicketReportModel) _then) = __$AdminTicketReportModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String targetType, String? targetLabel, String reason, String status, DateTime createdAt
});




}
/// @nodoc
class __$AdminTicketReportModelCopyWithImpl<$Res>
    implements _$AdminTicketReportModelCopyWith<$Res> {
  __$AdminTicketReportModelCopyWithImpl(this._self, this._then);

  final _AdminTicketReportModel _self;
  final $Res Function(_AdminTicketReportModel) _then;

/// Create a copy of AdminTicketReportModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targetType = null,Object? targetLabel = freezed,Object? reason = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_AdminTicketReportModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$AdminTicketModerationModel {

 String get id; String get action; String? get note; DateTime? get suspendedUntil; DateTime get createdAt;
/// Create a copy of AdminTicketModerationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketModerationModelCopyWith<AdminTicketModerationModel> get copyWith => _$AdminTicketModerationModelCopyWithImpl<AdminTicketModerationModel>(this as AdminTicketModerationModel, _$identity);

  /// Serializes this AdminTicketModerationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketModerationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.note, note) || other.note == note)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,note,suspendedUntil,createdAt);

@override
String toString() {
  return 'AdminTicketModerationModel(id: $id, action: $action, note: $note, suspendedUntil: $suspendedUntil, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AdminTicketModerationModelCopyWith<$Res>  {
  factory $AdminTicketModerationModelCopyWith(AdminTicketModerationModel value, $Res Function(AdminTicketModerationModel) _then) = _$AdminTicketModerationModelCopyWithImpl;
@useResult
$Res call({
 String id, String action, String? note, DateTime? suspendedUntil, DateTime createdAt
});




}
/// @nodoc
class _$AdminTicketModerationModelCopyWithImpl<$Res>
    implements $AdminTicketModerationModelCopyWith<$Res> {
  _$AdminTicketModerationModelCopyWithImpl(this._self, this._then);

  final AdminTicketModerationModel _self;
  final $Res Function(AdminTicketModerationModel) _then;

/// Create a copy of AdminTicketModerationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? note = freezed,Object? suspendedUntil = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketModerationModel].
extension AdminTicketModerationModelPatterns on AdminTicketModerationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketModerationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketModerationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketModerationModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketModerationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketModerationModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketModerationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String action,  String? note,  DateTime? suspendedUntil,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketModerationModel() when $default != null:
return $default(_that.id,_that.action,_that.note,_that.suspendedUntil,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String action,  String? note,  DateTime? suspendedUntil,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketModerationModel():
return $default(_that.id,_that.action,_that.note,_that.suspendedUntil,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String action,  String? note,  DateTime? suspendedUntil,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketModerationModel() when $default != null:
return $default(_that.id,_that.action,_that.note,_that.suspendedUntil,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketModerationModel extends AdminTicketModerationModel {
  const _AdminTicketModerationModel({required this.id, this.action = '', this.note, this.suspendedUntil, required this.createdAt}): super._();
  factory _AdminTicketModerationModel.fromJson(Map<String, dynamic> json) => _$AdminTicketModerationModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String action;
@override final  String? note;
@override final  DateTime? suspendedUntil;
@override final  DateTime createdAt;

/// Create a copy of AdminTicketModerationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketModerationModelCopyWith<_AdminTicketModerationModel> get copyWith => __$AdminTicketModerationModelCopyWithImpl<_AdminTicketModerationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketModerationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketModerationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.note, note) || other.note == note)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,note,suspendedUntil,createdAt);

@override
String toString() {
  return 'AdminTicketModerationModel(id: $id, action: $action, note: $note, suspendedUntil: $suspendedUntil, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketModerationModelCopyWith<$Res> implements $AdminTicketModerationModelCopyWith<$Res> {
  factory _$AdminTicketModerationModelCopyWith(_AdminTicketModerationModel value, $Res Function(_AdminTicketModerationModel) _then) = __$AdminTicketModerationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String action, String? note, DateTime? suspendedUntil, DateTime createdAt
});




}
/// @nodoc
class __$AdminTicketModerationModelCopyWithImpl<$Res>
    implements _$AdminTicketModerationModelCopyWith<$Res> {
  __$AdminTicketModerationModelCopyWithImpl(this._self, this._then);

  final _AdminTicketModerationModel _self;
  final $Res Function(_AdminTicketModerationModel) _then;

/// Create a copy of AdminTicketModerationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? note = freezed,Object? suspendedUntil = freezed,Object? createdAt = null,}) {
  return _then(_AdminTicketModerationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$AdminTicketPageModel {

 List<AdminTicketModel> get items; int get page; int get pageSize; int get totalCount; int get totalPages;
/// Create a copy of AdminTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketPageModelCopyWith<AdminTicketPageModel> get copyWith => _$AdminTicketPageModelCopyWithImpl<AdminTicketPageModel>(this as AdminTicketPageModel, _$identity);

  /// Serializes this AdminTicketPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminTicketPageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class $AdminTicketPageModelCopyWith<$Res>  {
  factory $AdminTicketPageModelCopyWith(AdminTicketPageModel value, $Res Function(AdminTicketPageModel) _then) = _$AdminTicketPageModelCopyWithImpl;
@useResult
$Res call({
 List<AdminTicketModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class _$AdminTicketPageModelCopyWithImpl<$Res>
    implements $AdminTicketPageModelCopyWith<$Res> {
  _$AdminTicketPageModelCopyWithImpl(this._self, this._then);

  final AdminTicketPageModel _self;
  final $Res Function(AdminTicketPageModel) _then;

/// Create a copy of AdminTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminTicketModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketPageModel].
extension AdminTicketPageModelPatterns on AdminTicketPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketPageModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminTicketModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketPageModel() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.totalCount,_that.totalPages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminTicketModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketPageModel():
return $default(_that.items,_that.page,_that.pageSize,_that.totalCount,_that.totalPages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminTicketModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketPageModel() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.totalCount,_that.totalPages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketPageModel implements AdminTicketPageModel {
  const _AdminTicketPageModel({final  List<AdminTicketModel> items = const <AdminTicketModel>[], this.page = 1, this.pageSize = 50, this.totalCount = 0, this.totalPages = 0}): _items = items;
  factory _AdminTicketPageModel.fromJson(Map<String, dynamic> json) => _$AdminTicketPageModelFromJson(json);

 final  List<AdminTicketModel> _items;
@override@JsonKey() List<AdminTicketModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  int pageSize;
@override@JsonKey() final  int totalCount;
@override@JsonKey() final  int totalPages;

/// Create a copy of AdminTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketPageModelCopyWith<_AdminTicketPageModel> get copyWith => __$AdminTicketPageModelCopyWithImpl<_AdminTicketPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminTicketPageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketPageModelCopyWith<$Res> implements $AdminTicketPageModelCopyWith<$Res> {
  factory _$AdminTicketPageModelCopyWith(_AdminTicketPageModel value, $Res Function(_AdminTicketPageModel) _then) = __$AdminTicketPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminTicketModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class __$AdminTicketPageModelCopyWithImpl<$Res>
    implements _$AdminTicketPageModelCopyWith<$Res> {
  __$AdminTicketPageModelCopyWithImpl(this._self, this._then);

  final _AdminTicketPageModel _self;
  final $Res Function(_AdminTicketPageModel) _then;

/// Create a copy of AdminTicketPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_AdminTicketPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminTicketModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminTicketMessageRequest {

 String get body; bool get internal;
/// Create a copy of AdminTicketMessageRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketMessageRequestCopyWith<AdminTicketMessageRequest> get copyWith => _$AdminTicketMessageRequestCopyWithImpl<AdminTicketMessageRequest>(this as AdminTicketMessageRequest, _$identity);

  /// Serializes this AdminTicketMessageRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketMessageRequest&&(identical(other.body, body) || other.body == body)&&(identical(other.internal, internal) || other.internal == internal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,internal);

@override
String toString() {
  return 'AdminTicketMessageRequest(body: $body, internal: $internal)';
}


}

/// @nodoc
abstract mixin class $AdminTicketMessageRequestCopyWith<$Res>  {
  factory $AdminTicketMessageRequestCopyWith(AdminTicketMessageRequest value, $Res Function(AdminTicketMessageRequest) _then) = _$AdminTicketMessageRequestCopyWithImpl;
@useResult
$Res call({
 String body, bool internal
});




}
/// @nodoc
class _$AdminTicketMessageRequestCopyWithImpl<$Res>
    implements $AdminTicketMessageRequestCopyWith<$Res> {
  _$AdminTicketMessageRequestCopyWithImpl(this._self, this._then);

  final AdminTicketMessageRequest _self;
  final $Res Function(AdminTicketMessageRequest) _then;

/// Create a copy of AdminTicketMessageRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,Object? internal = null,}) {
  return _then(_self.copyWith(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,internal: null == internal ? _self.internal : internal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketMessageRequest].
extension AdminTicketMessageRequestPatterns on AdminTicketMessageRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketMessageRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketMessageRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketMessageRequest value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketMessageRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketMessageRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketMessageRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String body,  bool internal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketMessageRequest() when $default != null:
return $default(_that.body,_that.internal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String body,  bool internal)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketMessageRequest():
return $default(_that.body,_that.internal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String body,  bool internal)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketMessageRequest() when $default != null:
return $default(_that.body,_that.internal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketMessageRequest implements AdminTicketMessageRequest {
  const _AdminTicketMessageRequest({required this.body, required this.internal});
  factory _AdminTicketMessageRequest.fromJson(Map<String, dynamic> json) => _$AdminTicketMessageRequestFromJson(json);

@override final  String body;
@override final  bool internal;

/// Create a copy of AdminTicketMessageRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketMessageRequestCopyWith<_AdminTicketMessageRequest> get copyWith => __$AdminTicketMessageRequestCopyWithImpl<_AdminTicketMessageRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketMessageRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketMessageRequest&&(identical(other.body, body) || other.body == body)&&(identical(other.internal, internal) || other.internal == internal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body,internal);

@override
String toString() {
  return 'AdminTicketMessageRequest(body: $body, internal: $internal)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketMessageRequestCopyWith<$Res> implements $AdminTicketMessageRequestCopyWith<$Res> {
  factory _$AdminTicketMessageRequestCopyWith(_AdminTicketMessageRequest value, $Res Function(_AdminTicketMessageRequest) _then) = __$AdminTicketMessageRequestCopyWithImpl;
@override @useResult
$Res call({
 String body, bool internal
});




}
/// @nodoc
class __$AdminTicketMessageRequestCopyWithImpl<$Res>
    implements _$AdminTicketMessageRequestCopyWith<$Res> {
  __$AdminTicketMessageRequestCopyWithImpl(this._self, this._then);

  final _AdminTicketMessageRequest _self;
  final $Res Function(_AdminTicketMessageRequest) _then;

/// Create a copy of AdminTicketMessageRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? internal = null,}) {
  return _then(_AdminTicketMessageRequest(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,internal: null == internal ? _self.internal : internal // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AdminTicketUpdateRequest {

 String? get status; String? get category;
/// Create a copy of AdminTicketUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketUpdateRequestCopyWith<AdminTicketUpdateRequest> get copyWith => _$AdminTicketUpdateRequestCopyWithImpl<AdminTicketUpdateRequest>(this as AdminTicketUpdateRequest, _$identity);

  /// Serializes this AdminTicketUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketUpdateRequest&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,category);

@override
String toString() {
  return 'AdminTicketUpdateRequest(status: $status, category: $category)';
}


}

/// @nodoc
abstract mixin class $AdminTicketUpdateRequestCopyWith<$Res>  {
  factory $AdminTicketUpdateRequestCopyWith(AdminTicketUpdateRequest value, $Res Function(AdminTicketUpdateRequest) _then) = _$AdminTicketUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String? status, String? category
});




}
/// @nodoc
class _$AdminTicketUpdateRequestCopyWithImpl<$Res>
    implements $AdminTicketUpdateRequestCopyWith<$Res> {
  _$AdminTicketUpdateRequestCopyWithImpl(this._self, this._then);

  final AdminTicketUpdateRequest _self;
  final $Res Function(AdminTicketUpdateRequest) _then;

/// Create a copy of AdminTicketUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,Object? category = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketUpdateRequest].
extension AdminTicketUpdateRequestPatterns on AdminTicketUpdateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketUpdateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketUpdateRequest value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketUpdateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketUpdateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? status,  String? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketUpdateRequest() when $default != null:
return $default(_that.status,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? status,  String? category)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketUpdateRequest():
return $default(_that.status,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? status,  String? category)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketUpdateRequest() when $default != null:
return $default(_that.status,_that.category);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _AdminTicketUpdateRequest implements AdminTicketUpdateRequest {
  const _AdminTicketUpdateRequest({this.status, this.category});
  factory _AdminTicketUpdateRequest.fromJson(Map<String, dynamic> json) => _$AdminTicketUpdateRequestFromJson(json);

@override final  String? status;
@override final  String? category;

/// Create a copy of AdminTicketUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketUpdateRequestCopyWith<_AdminTicketUpdateRequest> get copyWith => __$AdminTicketUpdateRequestCopyWithImpl<_AdminTicketUpdateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketUpdateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketUpdateRequest&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,category);

@override
String toString() {
  return 'AdminTicketUpdateRequest(status: $status, category: $category)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketUpdateRequestCopyWith<$Res> implements $AdminTicketUpdateRequestCopyWith<$Res> {
  factory _$AdminTicketUpdateRequestCopyWith(_AdminTicketUpdateRequest value, $Res Function(_AdminTicketUpdateRequest) _then) = __$AdminTicketUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? status, String? category
});




}
/// @nodoc
class __$AdminTicketUpdateRequestCopyWithImpl<$Res>
    implements _$AdminTicketUpdateRequestCopyWith<$Res> {
  __$AdminTicketUpdateRequestCopyWithImpl(this._self, this._then);

  final _AdminTicketUpdateRequest _self;
  final $Res Function(_AdminTicketUpdateRequest) _then;

/// Create a copy of AdminTicketUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,Object? category = freezed,}) {
  return _then(_AdminTicketUpdateRequest(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
