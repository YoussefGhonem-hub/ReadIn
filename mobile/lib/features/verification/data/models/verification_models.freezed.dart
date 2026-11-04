// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationFieldModel {

 String get id; String get slug; String get name;
/// Create a copy of VerificationFieldModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationFieldModelCopyWith<VerificationFieldModel> get copyWith => _$VerificationFieldModelCopyWithImpl<VerificationFieldModel>(this as VerificationFieldModel, _$identity);

  /// Serializes this VerificationFieldModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name);

@override
String toString() {
  return 'VerificationFieldModel(id: $id, slug: $slug, name: $name)';
}


}

/// @nodoc
abstract mixin class $VerificationFieldModelCopyWith<$Res>  {
  factory $VerificationFieldModelCopyWith(VerificationFieldModel value, $Res Function(VerificationFieldModel) _then) = _$VerificationFieldModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name
});




}
/// @nodoc
class _$VerificationFieldModelCopyWithImpl<$Res>
    implements $VerificationFieldModelCopyWith<$Res> {
  _$VerificationFieldModelCopyWithImpl(this._self, this._then);

  final VerificationFieldModel _self;
  final $Res Function(VerificationFieldModel) _then;

/// Create a copy of VerificationFieldModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationFieldModel].
extension VerificationFieldModelPatterns on VerificationFieldModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationFieldModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationFieldModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationFieldModel value)  $default,){
final _that = this;
switch (_that) {
case _VerificationFieldModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationFieldModel value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationFieldModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name)  $default,) {final _that = this;
switch (_that) {
case _VerificationFieldModel():
return $default(_that.id,_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name)?  $default,) {final _that = this;
switch (_that) {
case _VerificationFieldModel() when $default != null:
return $default(_that.id,_that.slug,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationFieldModel extends VerificationFieldModel {
  const _VerificationFieldModel({required this.id, this.slug = '', this.name = ''}): super._();
  factory _VerificationFieldModel.fromJson(Map<String, dynamic> json) => _$VerificationFieldModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String slug;
@override@JsonKey() final  String name;

/// Create a copy of VerificationFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationFieldModelCopyWith<_VerificationFieldModel> get copyWith => __$VerificationFieldModelCopyWithImpl<_VerificationFieldModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationFieldModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationFieldModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name);

@override
String toString() {
  return 'VerificationFieldModel(id: $id, slug: $slug, name: $name)';
}


}

/// @nodoc
abstract mixin class _$VerificationFieldModelCopyWith<$Res> implements $VerificationFieldModelCopyWith<$Res> {
  factory _$VerificationFieldModelCopyWith(_VerificationFieldModel value, $Res Function(_VerificationFieldModel) _then) = __$VerificationFieldModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name
});




}
/// @nodoc
class __$VerificationFieldModelCopyWithImpl<$Res>
    implements _$VerificationFieldModelCopyWith<$Res> {
  __$VerificationFieldModelCopyWithImpl(this._self, this._then);

  final _VerificationFieldModel _self;
  final $Res Function(_VerificationFieldModel) _then;

/// Create a copy of VerificationFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,}) {
  return _then(_VerificationFieldModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MyVerificationRequestModel {

 String get id; String get status; VerificationFieldModel get field; String get jobTitle; String? get proofUrl; String? get proofFileName; String? get note; DateTime get submittedAt; DateTime? get decidedAt; String? get rejectionReason;
/// Create a copy of MyVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyVerificationRequestModelCopyWith<MyVerificationRequestModel> get copyWith => _$MyVerificationRequestModelCopyWithImpl<MyVerificationRequestModel>(this as MyVerificationRequestModel, _$identity);

  /// Serializes this MyVerificationRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyVerificationRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.field, field) || other.field == field)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.proofUrl, proofUrl) || other.proofUrl == proofUrl)&&(identical(other.proofFileName, proofFileName) || other.proofFileName == proofFileName)&&(identical(other.note, note) || other.note == note)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,field,jobTitle,proofUrl,proofFileName,note,submittedAt,decidedAt,rejectionReason);

@override
String toString() {
  return 'MyVerificationRequestModel(id: $id, status: $status, field: $field, jobTitle: $jobTitle, proofUrl: $proofUrl, proofFileName: $proofFileName, note: $note, submittedAt: $submittedAt, decidedAt: $decidedAt, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class $MyVerificationRequestModelCopyWith<$Res>  {
  factory $MyVerificationRequestModelCopyWith(MyVerificationRequestModel value, $Res Function(MyVerificationRequestModel) _then) = _$MyVerificationRequestModelCopyWithImpl;
@useResult
$Res call({
 String id, String status, VerificationFieldModel field, String jobTitle, String? proofUrl, String? proofFileName, String? note, DateTime submittedAt, DateTime? decidedAt, String? rejectionReason
});


$VerificationFieldModelCopyWith<$Res> get field;

}
/// @nodoc
class _$MyVerificationRequestModelCopyWithImpl<$Res>
    implements $MyVerificationRequestModelCopyWith<$Res> {
  _$MyVerificationRequestModelCopyWithImpl(this._self, this._then);

  final MyVerificationRequestModel _self;
  final $Res Function(MyVerificationRequestModel) _then;

/// Create a copy of MyVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? field = null,Object? jobTitle = null,Object? proofUrl = freezed,Object? proofFileName = freezed,Object? note = freezed,Object? submittedAt = null,Object? decidedAt = freezed,Object? rejectionReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as VerificationFieldModel,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,proofUrl: freezed == proofUrl ? _self.proofUrl : proofUrl // ignore: cast_nullable_to_non_nullable
as String?,proofFileName: freezed == proofFileName ? _self.proofFileName : proofFileName // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of MyVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationFieldModelCopyWith<$Res> get field {
  
  return $VerificationFieldModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// Adds pattern-matching-related methods to [MyVerificationRequestModel].
extension MyVerificationRequestModelPatterns on MyVerificationRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyVerificationRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyVerificationRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyVerificationRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _MyVerificationRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyVerificationRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _MyVerificationRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  VerificationFieldModel field,  String jobTitle,  String? proofUrl,  String? proofFileName,  String? note,  DateTime submittedAt,  DateTime? decidedAt,  String? rejectionReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyVerificationRequestModel() when $default != null:
return $default(_that.id,_that.status,_that.field,_that.jobTitle,_that.proofUrl,_that.proofFileName,_that.note,_that.submittedAt,_that.decidedAt,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  VerificationFieldModel field,  String jobTitle,  String? proofUrl,  String? proofFileName,  String? note,  DateTime submittedAt,  DateTime? decidedAt,  String? rejectionReason)  $default,) {final _that = this;
switch (_that) {
case _MyVerificationRequestModel():
return $default(_that.id,_that.status,_that.field,_that.jobTitle,_that.proofUrl,_that.proofFileName,_that.note,_that.submittedAt,_that.decidedAt,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  VerificationFieldModel field,  String jobTitle,  String? proofUrl,  String? proofFileName,  String? note,  DateTime submittedAt,  DateTime? decidedAt,  String? rejectionReason)?  $default,) {final _that = this;
switch (_that) {
case _MyVerificationRequestModel() when $default != null:
return $default(_that.id,_that.status,_that.field,_that.jobTitle,_that.proofUrl,_that.proofFileName,_that.note,_that.submittedAt,_that.decidedAt,_that.rejectionReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyVerificationRequestModel extends MyVerificationRequestModel {
  const _MyVerificationRequestModel({required this.id, required this.status, required this.field, this.jobTitle = '', this.proofUrl, this.proofFileName, this.note, required this.submittedAt, this.decidedAt, this.rejectionReason}): super._();
  factory _MyVerificationRequestModel.fromJson(Map<String, dynamic> json) => _$MyVerificationRequestModelFromJson(json);

@override final  String id;
@override final  String status;
@override final  VerificationFieldModel field;
@override@JsonKey() final  String jobTitle;
@override final  String? proofUrl;
@override final  String? proofFileName;
@override final  String? note;
@override final  DateTime submittedAt;
@override final  DateTime? decidedAt;
@override final  String? rejectionReason;

/// Create a copy of MyVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyVerificationRequestModelCopyWith<_MyVerificationRequestModel> get copyWith => __$MyVerificationRequestModelCopyWithImpl<_MyVerificationRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyVerificationRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyVerificationRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.field, field) || other.field == field)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.proofUrl, proofUrl) || other.proofUrl == proofUrl)&&(identical(other.proofFileName, proofFileName) || other.proofFileName == proofFileName)&&(identical(other.note, note) || other.note == note)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,field,jobTitle,proofUrl,proofFileName,note,submittedAt,decidedAt,rejectionReason);

@override
String toString() {
  return 'MyVerificationRequestModel(id: $id, status: $status, field: $field, jobTitle: $jobTitle, proofUrl: $proofUrl, proofFileName: $proofFileName, note: $note, submittedAt: $submittedAt, decidedAt: $decidedAt, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class _$MyVerificationRequestModelCopyWith<$Res> implements $MyVerificationRequestModelCopyWith<$Res> {
  factory _$MyVerificationRequestModelCopyWith(_MyVerificationRequestModel value, $Res Function(_MyVerificationRequestModel) _then) = __$MyVerificationRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, VerificationFieldModel field, String jobTitle, String? proofUrl, String? proofFileName, String? note, DateTime submittedAt, DateTime? decidedAt, String? rejectionReason
});


@override $VerificationFieldModelCopyWith<$Res> get field;

}
/// @nodoc
class __$MyVerificationRequestModelCopyWithImpl<$Res>
    implements _$MyVerificationRequestModelCopyWith<$Res> {
  __$MyVerificationRequestModelCopyWithImpl(this._self, this._then);

  final _MyVerificationRequestModel _self;
  final $Res Function(_MyVerificationRequestModel) _then;

/// Create a copy of MyVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? field = null,Object? jobTitle = null,Object? proofUrl = freezed,Object? proofFileName = freezed,Object? note = freezed,Object? submittedAt = null,Object? decidedAt = freezed,Object? rejectionReason = freezed,}) {
  return _then(_MyVerificationRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as VerificationFieldModel,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,proofUrl: freezed == proofUrl ? _self.proofUrl : proofUrl // ignore: cast_nullable_to_non_nullable
as String?,proofFileName: freezed == proofFileName ? _self.proofFileName : proofFileName // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of MyVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationFieldModelCopyWith<$Res> get field {
  
  return $VerificationFieldModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// @nodoc
mixin _$VerificationStatusModel {

 bool get isVerified; bool get canRequest; MyVerificationRequestModel? get request;
/// Create a copy of VerificationStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationStatusModelCopyWith<VerificationStatusModel> get copyWith => _$VerificationStatusModelCopyWithImpl<VerificationStatusModel>(this as VerificationStatusModel, _$identity);

  /// Serializes this VerificationStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationStatusModel&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.canRequest, canRequest) || other.canRequest == canRequest)&&(identical(other.request, request) || other.request == request));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isVerified,canRequest,request);

@override
String toString() {
  return 'VerificationStatusModel(isVerified: $isVerified, canRequest: $canRequest, request: $request)';
}


}

/// @nodoc
abstract mixin class $VerificationStatusModelCopyWith<$Res>  {
  factory $VerificationStatusModelCopyWith(VerificationStatusModel value, $Res Function(VerificationStatusModel) _then) = _$VerificationStatusModelCopyWithImpl;
@useResult
$Res call({
 bool isVerified, bool canRequest, MyVerificationRequestModel? request
});


$MyVerificationRequestModelCopyWith<$Res>? get request;

}
/// @nodoc
class _$VerificationStatusModelCopyWithImpl<$Res>
    implements $VerificationStatusModelCopyWith<$Res> {
  _$VerificationStatusModelCopyWithImpl(this._self, this._then);

  final VerificationStatusModel _self;
  final $Res Function(VerificationStatusModel) _then;

/// Create a copy of VerificationStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isVerified = null,Object? canRequest = null,Object? request = freezed,}) {
  return _then(_self.copyWith(
isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,canRequest: null == canRequest ? _self.canRequest : canRequest // ignore: cast_nullable_to_non_nullable
as bool,request: freezed == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as MyVerificationRequestModel?,
  ));
}
/// Create a copy of VerificationStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyVerificationRequestModelCopyWith<$Res>? get request {
    if (_self.request == null) {
    return null;
  }

  return $MyVerificationRequestModelCopyWith<$Res>(_self.request!, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}


/// Adds pattern-matching-related methods to [VerificationStatusModel].
extension VerificationStatusModelPatterns on VerificationStatusModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationStatusModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _VerificationStatusModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationStatusModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isVerified,  bool canRequest,  MyVerificationRequestModel? request)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationStatusModel() when $default != null:
return $default(_that.isVerified,_that.canRequest,_that.request);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isVerified,  bool canRequest,  MyVerificationRequestModel? request)  $default,) {final _that = this;
switch (_that) {
case _VerificationStatusModel():
return $default(_that.isVerified,_that.canRequest,_that.request);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isVerified,  bool canRequest,  MyVerificationRequestModel? request)?  $default,) {final _that = this;
switch (_that) {
case _VerificationStatusModel() when $default != null:
return $default(_that.isVerified,_that.canRequest,_that.request);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationStatusModel extends VerificationStatusModel {
  const _VerificationStatusModel({this.isVerified = false, this.canRequest = false, this.request}): super._();
  factory _VerificationStatusModel.fromJson(Map<String, dynamic> json) => _$VerificationStatusModelFromJson(json);

@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool canRequest;
@override final  MyVerificationRequestModel? request;

/// Create a copy of VerificationStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationStatusModelCopyWith<_VerificationStatusModel> get copyWith => __$VerificationStatusModelCopyWithImpl<_VerificationStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationStatusModel&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.canRequest, canRequest) || other.canRequest == canRequest)&&(identical(other.request, request) || other.request == request));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isVerified,canRequest,request);

@override
String toString() {
  return 'VerificationStatusModel(isVerified: $isVerified, canRequest: $canRequest, request: $request)';
}


}

/// @nodoc
abstract mixin class _$VerificationStatusModelCopyWith<$Res> implements $VerificationStatusModelCopyWith<$Res> {
  factory _$VerificationStatusModelCopyWith(_VerificationStatusModel value, $Res Function(_VerificationStatusModel) _then) = __$VerificationStatusModelCopyWithImpl;
@override @useResult
$Res call({
 bool isVerified, bool canRequest, MyVerificationRequestModel? request
});


@override $MyVerificationRequestModelCopyWith<$Res>? get request;

}
/// @nodoc
class __$VerificationStatusModelCopyWithImpl<$Res>
    implements _$VerificationStatusModelCopyWith<$Res> {
  __$VerificationStatusModelCopyWithImpl(this._self, this._then);

  final _VerificationStatusModel _self;
  final $Res Function(_VerificationStatusModel) _then;

/// Create a copy of VerificationStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isVerified = null,Object? canRequest = null,Object? request = freezed,}) {
  return _then(_VerificationStatusModel(
isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,canRequest: null == canRequest ? _self.canRequest : canRequest // ignore: cast_nullable_to_non_nullable
as bool,request: freezed == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as MyVerificationRequestModel?,
  ));
}

/// Create a copy of VerificationStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyVerificationRequestModelCopyWith<$Res>? get request {
    if (_self.request == null) {
    return null;
  }

  return $MyVerificationRequestModelCopyWith<$Res>(_self.request!, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

// dart format on
