// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaVariantModel {

 int get width; int get height; String get url; int get bytes;
/// Create a copy of MediaVariantModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaVariantModelCopyWith<MediaVariantModel> get copyWith => _$MediaVariantModelCopyWithImpl<MediaVariantModel>(this as MediaVariantModel, _$identity);

  /// Serializes this MediaVariantModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaVariantModel&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.url, url) || other.url == url)&&(identical(other.bytes, bytes) || other.bytes == bytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height,url,bytes);

@override
String toString() {
  return 'MediaVariantModel(width: $width, height: $height, url: $url, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $MediaVariantModelCopyWith<$Res>  {
  factory $MediaVariantModelCopyWith(MediaVariantModel value, $Res Function(MediaVariantModel) _then) = _$MediaVariantModelCopyWithImpl;
@useResult
$Res call({
 int width, int height, String url, int bytes
});




}
/// @nodoc
class _$MediaVariantModelCopyWithImpl<$Res>
    implements $MediaVariantModelCopyWith<$Res> {
  _$MediaVariantModelCopyWithImpl(this._self, this._then);

  final MediaVariantModel _self;
  final $Res Function(MediaVariantModel) _then;

/// Create a copy of MediaVariantModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = null,Object? height = null,Object? url = null,Object? bytes = null,}) {
  return _then(_self.copyWith(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaVariantModel].
extension MediaVariantModelPatterns on MediaVariantModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaVariantModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaVariantModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaVariantModel value)  $default,){
final _that = this;
switch (_that) {
case _MediaVariantModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaVariantModel value)?  $default,){
final _that = this;
switch (_that) {
case _MediaVariantModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int width,  int height,  String url,  int bytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaVariantModel() when $default != null:
return $default(_that.width,_that.height,_that.url,_that.bytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int width,  int height,  String url,  int bytes)  $default,) {final _that = this;
switch (_that) {
case _MediaVariantModel():
return $default(_that.width,_that.height,_that.url,_that.bytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int width,  int height,  String url,  int bytes)?  $default,) {final _that = this;
switch (_that) {
case _MediaVariantModel() when $default != null:
return $default(_that.width,_that.height,_that.url,_that.bytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaVariantModel extends MediaVariantModel {
  const _MediaVariantModel({required this.width, required this.height, required this.url, this.bytes = 0}): super._();
  factory _MediaVariantModel.fromJson(Map<String, dynamic> json) => _$MediaVariantModelFromJson(json);

@override final  int width;
@override final  int height;
@override final  String url;
@override@JsonKey() final  int bytes;

/// Create a copy of MediaVariantModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaVariantModelCopyWith<_MediaVariantModel> get copyWith => __$MediaVariantModelCopyWithImpl<_MediaVariantModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaVariantModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaVariantModel&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.url, url) || other.url == url)&&(identical(other.bytes, bytes) || other.bytes == bytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height,url,bytes);

@override
String toString() {
  return 'MediaVariantModel(width: $width, height: $height, url: $url, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class _$MediaVariantModelCopyWith<$Res> implements $MediaVariantModelCopyWith<$Res> {
  factory _$MediaVariantModelCopyWith(_MediaVariantModel value, $Res Function(_MediaVariantModel) _then) = __$MediaVariantModelCopyWithImpl;
@override @useResult
$Res call({
 int width, int height, String url, int bytes
});




}
/// @nodoc
class __$MediaVariantModelCopyWithImpl<$Res>
    implements _$MediaVariantModelCopyWith<$Res> {
  __$MediaVariantModelCopyWithImpl(this._self, this._then);

  final _MediaVariantModel _self;
  final $Res Function(_MediaVariantModel) _then;

/// Create a copy of MediaVariantModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = null,Object? height = null,Object? url = null,Object? bytes = null,}) {
  return _then(_MediaVariantModel(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MediaPageModel {

 int get pageNo; int get width; int get height; String? get blurHash; String get thumbUrl; String get viewUrl;
/// Create a copy of MediaPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaPageModelCopyWith<MediaPageModel> get copyWith => _$MediaPageModelCopyWithImpl<MediaPageModel>(this as MediaPageModel, _$identity);

  /// Serializes this MediaPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaPageModel&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurHash, blurHash) || other.blurHash == blurHash)&&(identical(other.thumbUrl, thumbUrl) || other.thumbUrl == thumbUrl)&&(identical(other.viewUrl, viewUrl) || other.viewUrl == viewUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageNo,width,height,blurHash,thumbUrl,viewUrl);

@override
String toString() {
  return 'MediaPageModel(pageNo: $pageNo, width: $width, height: $height, blurHash: $blurHash, thumbUrl: $thumbUrl, viewUrl: $viewUrl)';
}


}

/// @nodoc
abstract mixin class $MediaPageModelCopyWith<$Res>  {
  factory $MediaPageModelCopyWith(MediaPageModel value, $Res Function(MediaPageModel) _then) = _$MediaPageModelCopyWithImpl;
@useResult
$Res call({
 int pageNo, int width, int height, String? blurHash, String thumbUrl, String viewUrl
});




}
/// @nodoc
class _$MediaPageModelCopyWithImpl<$Res>
    implements $MediaPageModelCopyWith<$Res> {
  _$MediaPageModelCopyWithImpl(this._self, this._then);

  final MediaPageModel _self;
  final $Res Function(MediaPageModel) _then;

/// Create a copy of MediaPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageNo = null,Object? width = null,Object? height = null,Object? blurHash = freezed,Object? thumbUrl = null,Object? viewUrl = null,}) {
  return _then(_self.copyWith(
pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,thumbUrl: null == thumbUrl ? _self.thumbUrl : thumbUrl // ignore: cast_nullable_to_non_nullable
as String,viewUrl: null == viewUrl ? _self.viewUrl : viewUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaPageModel].
extension MediaPageModelPatterns on MediaPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaPageModel value)  $default,){
final _that = this;
switch (_that) {
case _MediaPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MediaPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pageNo,  int width,  int height,  String? blurHash,  String thumbUrl,  String viewUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaPageModel() when $default != null:
return $default(_that.pageNo,_that.width,_that.height,_that.blurHash,_that.thumbUrl,_that.viewUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pageNo,  int width,  int height,  String? blurHash,  String thumbUrl,  String viewUrl)  $default,) {final _that = this;
switch (_that) {
case _MediaPageModel():
return $default(_that.pageNo,_that.width,_that.height,_that.blurHash,_that.thumbUrl,_that.viewUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pageNo,  int width,  int height,  String? blurHash,  String thumbUrl,  String viewUrl)?  $default,) {final _that = this;
switch (_that) {
case _MediaPageModel() when $default != null:
return $default(_that.pageNo,_that.width,_that.height,_that.blurHash,_that.thumbUrl,_that.viewUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaPageModel extends MediaPageModel {
  const _MediaPageModel({required this.pageNo, required this.width, required this.height, this.blurHash, required this.thumbUrl, required this.viewUrl}): super._();
  factory _MediaPageModel.fromJson(Map<String, dynamic> json) => _$MediaPageModelFromJson(json);

@override final  int pageNo;
@override final  int width;
@override final  int height;
@override final  String? blurHash;
@override final  String thumbUrl;
@override final  String viewUrl;

/// Create a copy of MediaPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaPageModelCopyWith<_MediaPageModel> get copyWith => __$MediaPageModelCopyWithImpl<_MediaPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaPageModel&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurHash, blurHash) || other.blurHash == blurHash)&&(identical(other.thumbUrl, thumbUrl) || other.thumbUrl == thumbUrl)&&(identical(other.viewUrl, viewUrl) || other.viewUrl == viewUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageNo,width,height,blurHash,thumbUrl,viewUrl);

@override
String toString() {
  return 'MediaPageModel(pageNo: $pageNo, width: $width, height: $height, blurHash: $blurHash, thumbUrl: $thumbUrl, viewUrl: $viewUrl)';
}


}

/// @nodoc
abstract mixin class _$MediaPageModelCopyWith<$Res> implements $MediaPageModelCopyWith<$Res> {
  factory _$MediaPageModelCopyWith(_MediaPageModel value, $Res Function(_MediaPageModel) _then) = __$MediaPageModelCopyWithImpl;
@override @useResult
$Res call({
 int pageNo, int width, int height, String? blurHash, String thumbUrl, String viewUrl
});




}
/// @nodoc
class __$MediaPageModelCopyWithImpl<$Res>
    implements _$MediaPageModelCopyWith<$Res> {
  __$MediaPageModelCopyWithImpl(this._self, this._then);

  final _MediaPageModel _self;
  final $Res Function(_MediaPageModel) _then;

/// Create a copy of MediaPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageNo = null,Object? width = null,Object? height = null,Object? blurHash = freezed,Object? thumbUrl = null,Object? viewUrl = null,}) {
  return _then(_MediaPageModel(
pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,thumbUrl: null == thumbUrl ? _self.thumbUrl : thumbUrl // ignore: cast_nullable_to_non_nullable
as String,viewUrl: null == viewUrl ? _self.viewUrl : viewUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MediaAssetModel {

 String get id; String get kind; String get purpose; String get status; String? get failureReason; int? get width; int? get height; String? get blurHash; int get sizeBytes; List<MediaVariantModel> get variants; String? get title; int? get pageCount; int get pagesReady; List<MediaPageModel> get pages; bool get allowDownload; DateTime? get createdAt;
/// Create a copy of MediaAssetModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaAssetModelCopyWith<MediaAssetModel> get copyWith => _$MediaAssetModelCopyWithImpl<MediaAssetModel>(this as MediaAssetModel, _$identity);

  /// Serializes this MediaAssetModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaAssetModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.status, status) || other.status == status)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurHash, blurHash) || other.blurHash == blurHash)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&const DeepCollectionEquality().equals(other.variants, variants)&&(identical(other.title, title) || other.title == title)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.pagesReady, pagesReady) || other.pagesReady == pagesReady)&&const DeepCollectionEquality().equals(other.pages, pages)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,purpose,status,failureReason,width,height,blurHash,sizeBytes,const DeepCollectionEquality().hash(variants),title,pageCount,pagesReady,const DeepCollectionEquality().hash(pages),allowDownload,createdAt);

@override
String toString() {
  return 'MediaAssetModel(id: $id, kind: $kind, purpose: $purpose, status: $status, failureReason: $failureReason, width: $width, height: $height, blurHash: $blurHash, sizeBytes: $sizeBytes, variants: $variants, title: $title, pageCount: $pageCount, pagesReady: $pagesReady, pages: $pages, allowDownload: $allowDownload, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MediaAssetModelCopyWith<$Res>  {
  factory $MediaAssetModelCopyWith(MediaAssetModel value, $Res Function(MediaAssetModel) _then) = _$MediaAssetModelCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String purpose, String status, String? failureReason, int? width, int? height, String? blurHash, int sizeBytes, List<MediaVariantModel> variants, String? title, int? pageCount, int pagesReady, List<MediaPageModel> pages, bool allowDownload, DateTime? createdAt
});




}
/// @nodoc
class _$MediaAssetModelCopyWithImpl<$Res>
    implements $MediaAssetModelCopyWith<$Res> {
  _$MediaAssetModelCopyWithImpl(this._self, this._then);

  final MediaAssetModel _self;
  final $Res Function(MediaAssetModel) _then;

/// Create a copy of MediaAssetModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? purpose = null,Object? status = null,Object? failureReason = freezed,Object? width = freezed,Object? height = freezed,Object? blurHash = freezed,Object? sizeBytes = null,Object? variants = null,Object? title = freezed,Object? pageCount = freezed,Object? pagesReady = null,Object? pages = null,Object? allowDownload = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<MediaVariantModel>,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,pagesReady: null == pagesReady ? _self.pagesReady : pagesReady // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as List<MediaPageModel>,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaAssetModel].
extension MediaAssetModelPatterns on MediaAssetModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaAssetModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaAssetModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaAssetModel value)  $default,){
final _that = this;
switch (_that) {
case _MediaAssetModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaAssetModel value)?  $default,){
final _that = this;
switch (_that) {
case _MediaAssetModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String purpose,  String status,  String? failureReason,  int? width,  int? height,  String? blurHash,  int sizeBytes,  List<MediaVariantModel> variants,  String? title,  int? pageCount,  int pagesReady,  List<MediaPageModel> pages,  bool allowDownload,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaAssetModel() when $default != null:
return $default(_that.id,_that.kind,_that.purpose,_that.status,_that.failureReason,_that.width,_that.height,_that.blurHash,_that.sizeBytes,_that.variants,_that.title,_that.pageCount,_that.pagesReady,_that.pages,_that.allowDownload,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String purpose,  String status,  String? failureReason,  int? width,  int? height,  String? blurHash,  int sizeBytes,  List<MediaVariantModel> variants,  String? title,  int? pageCount,  int pagesReady,  List<MediaPageModel> pages,  bool allowDownload,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _MediaAssetModel():
return $default(_that.id,_that.kind,_that.purpose,_that.status,_that.failureReason,_that.width,_that.height,_that.blurHash,_that.sizeBytes,_that.variants,_that.title,_that.pageCount,_that.pagesReady,_that.pages,_that.allowDownload,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String purpose,  String status,  String? failureReason,  int? width,  int? height,  String? blurHash,  int sizeBytes,  List<MediaVariantModel> variants,  String? title,  int? pageCount,  int pagesReady,  List<MediaPageModel> pages,  bool allowDownload,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MediaAssetModel() when $default != null:
return $default(_that.id,_that.kind,_that.purpose,_that.status,_that.failureReason,_that.width,_that.height,_that.blurHash,_that.sizeBytes,_that.variants,_that.title,_that.pageCount,_that.pagesReady,_that.pages,_that.allowDownload,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaAssetModel extends MediaAssetModel {
  const _MediaAssetModel({required this.id, this.kind = 'image', this.purpose = 'image', this.status = 'processing', this.failureReason, this.width, this.height, this.blurHash, this.sizeBytes = 0, final  List<MediaVariantModel> variants = const <MediaVariantModel>[], this.title, this.pageCount, this.pagesReady = 0, final  List<MediaPageModel> pages = const <MediaPageModel>[], this.allowDownload = false, this.createdAt}): _variants = variants,_pages = pages,super._();
  factory _MediaAssetModel.fromJson(Map<String, dynamic> json) => _$MediaAssetModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String kind;
@override@JsonKey() final  String purpose;
@override@JsonKey() final  String status;
@override final  String? failureReason;
@override final  int? width;
@override final  int? height;
@override final  String? blurHash;
@override@JsonKey() final  int sizeBytes;
 final  List<MediaVariantModel> _variants;
@override@JsonKey() List<MediaVariantModel> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

@override final  String? title;
@override final  int? pageCount;
@override@JsonKey() final  int pagesReady;
 final  List<MediaPageModel> _pages;
@override@JsonKey() List<MediaPageModel> get pages {
  if (_pages is EqualUnmodifiableListView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pages);
}

@override@JsonKey() final  bool allowDownload;
@override final  DateTime? createdAt;

/// Create a copy of MediaAssetModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaAssetModelCopyWith<_MediaAssetModel> get copyWith => __$MediaAssetModelCopyWithImpl<_MediaAssetModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaAssetModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaAssetModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.status, status) || other.status == status)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurHash, blurHash) || other.blurHash == blurHash)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&const DeepCollectionEquality().equals(other._variants, _variants)&&(identical(other.title, title) || other.title == title)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.pagesReady, pagesReady) || other.pagesReady == pagesReady)&&const DeepCollectionEquality().equals(other._pages, _pages)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,purpose,status,failureReason,width,height,blurHash,sizeBytes,const DeepCollectionEquality().hash(_variants),title,pageCount,pagesReady,const DeepCollectionEquality().hash(_pages),allowDownload,createdAt);

@override
String toString() {
  return 'MediaAssetModel(id: $id, kind: $kind, purpose: $purpose, status: $status, failureReason: $failureReason, width: $width, height: $height, blurHash: $blurHash, sizeBytes: $sizeBytes, variants: $variants, title: $title, pageCount: $pageCount, pagesReady: $pagesReady, pages: $pages, allowDownload: $allowDownload, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MediaAssetModelCopyWith<$Res> implements $MediaAssetModelCopyWith<$Res> {
  factory _$MediaAssetModelCopyWith(_MediaAssetModel value, $Res Function(_MediaAssetModel) _then) = __$MediaAssetModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String purpose, String status, String? failureReason, int? width, int? height, String? blurHash, int sizeBytes, List<MediaVariantModel> variants, String? title, int? pageCount, int pagesReady, List<MediaPageModel> pages, bool allowDownload, DateTime? createdAt
});




}
/// @nodoc
class __$MediaAssetModelCopyWithImpl<$Res>
    implements _$MediaAssetModelCopyWith<$Res> {
  __$MediaAssetModelCopyWithImpl(this._self, this._then);

  final _MediaAssetModel _self;
  final $Res Function(_MediaAssetModel) _then;

/// Create a copy of MediaAssetModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? purpose = null,Object? status = null,Object? failureReason = freezed,Object? width = freezed,Object? height = freezed,Object? blurHash = freezed,Object? sizeBytes = null,Object? variants = null,Object? title = freezed,Object? pageCount = freezed,Object? pagesReady = null,Object? pages = null,Object? allowDownload = null,Object? createdAt = freezed,}) {
  return _then(_MediaAssetModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<MediaVariantModel>,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,pagesReady: null == pagesReady ? _self.pagesReady : pagesReady // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as List<MediaPageModel>,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ImageAttachmentModel {

 String get assetId; int get order; String? get caption; String get altText; int get width; int get height; String? get blurHash; List<MediaVariantModel> get variants;
/// Create a copy of ImageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageAttachmentModelCopyWith<ImageAttachmentModel> get copyWith => _$ImageAttachmentModelCopyWithImpl<ImageAttachmentModel>(this as ImageAttachmentModel, _$identity);

  /// Serializes this ImageAttachmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageAttachmentModel&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.order, order) || other.order == order)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurHash, blurHash) || other.blurHash == blurHash)&&const DeepCollectionEquality().equals(other.variants, variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,order,caption,altText,width,height,blurHash,const DeepCollectionEquality().hash(variants));

@override
String toString() {
  return 'ImageAttachmentModel(assetId: $assetId, order: $order, caption: $caption, altText: $altText, width: $width, height: $height, blurHash: $blurHash, variants: $variants)';
}


}

/// @nodoc
abstract mixin class $ImageAttachmentModelCopyWith<$Res>  {
  factory $ImageAttachmentModelCopyWith(ImageAttachmentModel value, $Res Function(ImageAttachmentModel) _then) = _$ImageAttachmentModelCopyWithImpl;
@useResult
$Res call({
 String assetId, int order, String? caption, String altText, int width, int height, String? blurHash, List<MediaVariantModel> variants
});




}
/// @nodoc
class _$ImageAttachmentModelCopyWithImpl<$Res>
    implements $ImageAttachmentModelCopyWith<$Res> {
  _$ImageAttachmentModelCopyWithImpl(this._self, this._then);

  final ImageAttachmentModel _self;
  final $Res Function(ImageAttachmentModel) _then;

/// Create a copy of ImageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetId = null,Object? order = null,Object? caption = freezed,Object? altText = null,Object? width = null,Object? height = null,Object? blurHash = freezed,Object? variants = null,}) {
  return _then(_self.copyWith(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,altText: null == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<MediaVariantModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageAttachmentModel].
extension ImageAttachmentModelPatterns on ImageAttachmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageAttachmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageAttachmentModel value)  $default,){
final _that = this;
switch (_that) {
case _ImageAttachmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageAttachmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _ImageAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String assetId,  int order,  String? caption,  String altText,  int width,  int height,  String? blurHash,  List<MediaVariantModel> variants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageAttachmentModel() when $default != null:
return $default(_that.assetId,_that.order,_that.caption,_that.altText,_that.width,_that.height,_that.blurHash,_that.variants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String assetId,  int order,  String? caption,  String altText,  int width,  int height,  String? blurHash,  List<MediaVariantModel> variants)  $default,) {final _that = this;
switch (_that) {
case _ImageAttachmentModel():
return $default(_that.assetId,_that.order,_that.caption,_that.altText,_that.width,_that.height,_that.blurHash,_that.variants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String assetId,  int order,  String? caption,  String altText,  int width,  int height,  String? blurHash,  List<MediaVariantModel> variants)?  $default,) {final _that = this;
switch (_that) {
case _ImageAttachmentModel() when $default != null:
return $default(_that.assetId,_that.order,_that.caption,_that.altText,_that.width,_that.height,_that.blurHash,_that.variants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageAttachmentModel extends ImageAttachmentModel {
  const _ImageAttachmentModel({required this.assetId, this.order = 0, this.caption, this.altText = '', this.width = 0, this.height = 0, this.blurHash, final  List<MediaVariantModel> variants = const <MediaVariantModel>[]}): _variants = variants,super._();
  factory _ImageAttachmentModel.fromJson(Map<String, dynamic> json) => _$ImageAttachmentModelFromJson(json);

@override final  String assetId;
@override@JsonKey() final  int order;
@override final  String? caption;
@override@JsonKey() final  String altText;
@override@JsonKey() final  int width;
@override@JsonKey() final  int height;
@override final  String? blurHash;
 final  List<MediaVariantModel> _variants;
@override@JsonKey() List<MediaVariantModel> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}


/// Create a copy of ImageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageAttachmentModelCopyWith<_ImageAttachmentModel> get copyWith => __$ImageAttachmentModelCopyWithImpl<_ImageAttachmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageAttachmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageAttachmentModel&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.order, order) || other.order == order)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.blurHash, blurHash) || other.blurHash == blurHash)&&const DeepCollectionEquality().equals(other._variants, _variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,order,caption,altText,width,height,blurHash,const DeepCollectionEquality().hash(_variants));

@override
String toString() {
  return 'ImageAttachmentModel(assetId: $assetId, order: $order, caption: $caption, altText: $altText, width: $width, height: $height, blurHash: $blurHash, variants: $variants)';
}


}

/// @nodoc
abstract mixin class _$ImageAttachmentModelCopyWith<$Res> implements $ImageAttachmentModelCopyWith<$Res> {
  factory _$ImageAttachmentModelCopyWith(_ImageAttachmentModel value, $Res Function(_ImageAttachmentModel) _then) = __$ImageAttachmentModelCopyWithImpl;
@override @useResult
$Res call({
 String assetId, int order, String? caption, String altText, int width, int height, String? blurHash, List<MediaVariantModel> variants
});




}
/// @nodoc
class __$ImageAttachmentModelCopyWithImpl<$Res>
    implements _$ImageAttachmentModelCopyWith<$Res> {
  __$ImageAttachmentModelCopyWithImpl(this._self, this._then);

  final _ImageAttachmentModel _self;
  final $Res Function(_ImageAttachmentModel) _then;

/// Create a copy of ImageAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetId = null,Object? order = null,Object? caption = freezed,Object? altText = null,Object? width = null,Object? height = null,Object? blurHash = freezed,Object? variants = null,}) {
  return _then(_ImageAttachmentModel(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,altText: null == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,blurHash: freezed == blurHash ? _self.blurHash : blurHash // ignore: cast_nullable_to_non_nullable
as String?,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<MediaVariantModel>,
  ));
}


}


/// @nodoc
mixin _$DocumentAttachmentModel {

 String get assetId; String get title; int get pageCount; bool get allowDownload; bool get canDownload; String get downloadUrl; List<MediaPageModel> get pages;
/// Create a copy of DocumentAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentAttachmentModelCopyWith<DocumentAttachmentModel> get copyWith => _$DocumentAttachmentModelCopyWithImpl<DocumentAttachmentModel>(this as DocumentAttachmentModel, _$identity);

  /// Serializes this DocumentAttachmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentAttachmentModel&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.title, title) || other.title == title)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.canDownload, canDownload) || other.canDownload == canDownload)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&const DeepCollectionEquality().equals(other.pages, pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,title,pageCount,allowDownload,canDownload,downloadUrl,const DeepCollectionEquality().hash(pages));

@override
String toString() {
  return 'DocumentAttachmentModel(assetId: $assetId, title: $title, pageCount: $pageCount, allowDownload: $allowDownload, canDownload: $canDownload, downloadUrl: $downloadUrl, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $DocumentAttachmentModelCopyWith<$Res>  {
  factory $DocumentAttachmentModelCopyWith(DocumentAttachmentModel value, $Res Function(DocumentAttachmentModel) _then) = _$DocumentAttachmentModelCopyWithImpl;
@useResult
$Res call({
 String assetId, String title, int pageCount, bool allowDownload, bool canDownload, String downloadUrl, List<MediaPageModel> pages
});




}
/// @nodoc
class _$DocumentAttachmentModelCopyWithImpl<$Res>
    implements $DocumentAttachmentModelCopyWith<$Res> {
  _$DocumentAttachmentModelCopyWithImpl(this._self, this._then);

  final DocumentAttachmentModel _self;
  final $Res Function(DocumentAttachmentModel) _then;

/// Create a copy of DocumentAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetId = null,Object? title = null,Object? pageCount = null,Object? allowDownload = null,Object? canDownload = null,Object? downloadUrl = null,Object? pages = null,}) {
  return _then(_self.copyWith(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,canDownload: null == canDownload ? _self.canDownload : canDownload // ignore: cast_nullable_to_non_nullable
as bool,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as List<MediaPageModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentAttachmentModel].
extension DocumentAttachmentModelPatterns on DocumentAttachmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentAttachmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentAttachmentModel value)  $default,){
final _that = this;
switch (_that) {
case _DocumentAttachmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentAttachmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String assetId,  String title,  int pageCount,  bool allowDownload,  bool canDownload,  String downloadUrl,  List<MediaPageModel> pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentAttachmentModel() when $default != null:
return $default(_that.assetId,_that.title,_that.pageCount,_that.allowDownload,_that.canDownload,_that.downloadUrl,_that.pages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String assetId,  String title,  int pageCount,  bool allowDownload,  bool canDownload,  String downloadUrl,  List<MediaPageModel> pages)  $default,) {final _that = this;
switch (_that) {
case _DocumentAttachmentModel():
return $default(_that.assetId,_that.title,_that.pageCount,_that.allowDownload,_that.canDownload,_that.downloadUrl,_that.pages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String assetId,  String title,  int pageCount,  bool allowDownload,  bool canDownload,  String downloadUrl,  List<MediaPageModel> pages)?  $default,) {final _that = this;
switch (_that) {
case _DocumentAttachmentModel() when $default != null:
return $default(_that.assetId,_that.title,_that.pageCount,_that.allowDownload,_that.canDownload,_that.downloadUrl,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentAttachmentModel extends DocumentAttachmentModel {
  const _DocumentAttachmentModel({required this.assetId, required this.title, this.pageCount = 0, this.allowDownload = false, this.canDownload = false, this.downloadUrl = '', final  List<MediaPageModel> pages = const <MediaPageModel>[]}): _pages = pages,super._();
  factory _DocumentAttachmentModel.fromJson(Map<String, dynamic> json) => _$DocumentAttachmentModelFromJson(json);

@override final  String assetId;
@override final  String title;
@override@JsonKey() final  int pageCount;
@override@JsonKey() final  bool allowDownload;
@override@JsonKey() final  bool canDownload;
@override@JsonKey() final  String downloadUrl;
 final  List<MediaPageModel> _pages;
@override@JsonKey() List<MediaPageModel> get pages {
  if (_pages is EqualUnmodifiableListView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pages);
}


/// Create a copy of DocumentAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentAttachmentModelCopyWith<_DocumentAttachmentModel> get copyWith => __$DocumentAttachmentModelCopyWithImpl<_DocumentAttachmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentAttachmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentAttachmentModel&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.title, title) || other.title == title)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.canDownload, canDownload) || other.canDownload == canDownload)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&const DeepCollectionEquality().equals(other._pages, _pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,title,pageCount,allowDownload,canDownload,downloadUrl,const DeepCollectionEquality().hash(_pages));

@override
String toString() {
  return 'DocumentAttachmentModel(assetId: $assetId, title: $title, pageCount: $pageCount, allowDownload: $allowDownload, canDownload: $canDownload, downloadUrl: $downloadUrl, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$DocumentAttachmentModelCopyWith<$Res> implements $DocumentAttachmentModelCopyWith<$Res> {
  factory _$DocumentAttachmentModelCopyWith(_DocumentAttachmentModel value, $Res Function(_DocumentAttachmentModel) _then) = __$DocumentAttachmentModelCopyWithImpl;
@override @useResult
$Res call({
 String assetId, String title, int pageCount, bool allowDownload, bool canDownload, String downloadUrl, List<MediaPageModel> pages
});




}
/// @nodoc
class __$DocumentAttachmentModelCopyWithImpl<$Res>
    implements _$DocumentAttachmentModelCopyWith<$Res> {
  __$DocumentAttachmentModelCopyWithImpl(this._self, this._then);

  final _DocumentAttachmentModel _self;
  final $Res Function(_DocumentAttachmentModel) _then;

/// Create a copy of DocumentAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetId = null,Object? title = null,Object? pageCount = null,Object? allowDownload = null,Object? canDownload = null,Object? downloadUrl = null,Object? pages = null,}) {
  return _then(_DocumentAttachmentModel(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,canDownload: null == canDownload ? _self.canDownload : canDownload // ignore: cast_nullable_to_non_nullable
as bool,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as List<MediaPageModel>,
  ));
}


}


/// @nodoc
mixin _$ArticleAttachmentsModel {

 String get kind; List<ImageAttachmentModel> get images; DocumentAttachmentModel? get document;
/// Create a copy of ArticleAttachmentsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleAttachmentsModelCopyWith<ArticleAttachmentsModel> get copyWith => _$ArticleAttachmentsModelCopyWithImpl<ArticleAttachmentsModel>(this as ArticleAttachmentsModel, _$identity);

  /// Serializes this ArticleAttachmentsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleAttachmentsModel&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.document, document) || other.document == document));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(images),document);

@override
String toString() {
  return 'ArticleAttachmentsModel(kind: $kind, images: $images, document: $document)';
}


}

/// @nodoc
abstract mixin class $ArticleAttachmentsModelCopyWith<$Res>  {
  factory $ArticleAttachmentsModelCopyWith(ArticleAttachmentsModel value, $Res Function(ArticleAttachmentsModel) _then) = _$ArticleAttachmentsModelCopyWithImpl;
@useResult
$Res call({
 String kind, List<ImageAttachmentModel> images, DocumentAttachmentModel? document
});


$DocumentAttachmentModelCopyWith<$Res>? get document;

}
/// @nodoc
class _$ArticleAttachmentsModelCopyWithImpl<$Res>
    implements $ArticleAttachmentsModelCopyWith<$Res> {
  _$ArticleAttachmentsModelCopyWithImpl(this._self, this._then);

  final ArticleAttachmentsModel _self;
  final $Res Function(ArticleAttachmentsModel) _then;

/// Create a copy of ArticleAttachmentsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? images = null,Object? document = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ImageAttachmentModel>,document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as DocumentAttachmentModel?,
  ));
}
/// Create a copy of ArticleAttachmentsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentAttachmentModelCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $DocumentAttachmentModelCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleAttachmentsModel].
extension ArticleAttachmentsModelPatterns on ArticleAttachmentsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleAttachmentsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleAttachmentsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleAttachmentsModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleAttachmentsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleAttachmentsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleAttachmentsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  List<ImageAttachmentModel> images,  DocumentAttachmentModel? document)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleAttachmentsModel() when $default != null:
return $default(_that.kind,_that.images,_that.document);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  List<ImageAttachmentModel> images,  DocumentAttachmentModel? document)  $default,) {final _that = this;
switch (_that) {
case _ArticleAttachmentsModel():
return $default(_that.kind,_that.images,_that.document);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  List<ImageAttachmentModel> images,  DocumentAttachmentModel? document)?  $default,) {final _that = this;
switch (_that) {
case _ArticleAttachmentsModel() when $default != null:
return $default(_that.kind,_that.images,_that.document);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleAttachmentsModel extends ArticleAttachmentsModel {
  const _ArticleAttachmentsModel({this.kind = 'images', final  List<ImageAttachmentModel> images = const <ImageAttachmentModel>[], this.document}): _images = images,super._();
  factory _ArticleAttachmentsModel.fromJson(Map<String, dynamic> json) => _$ArticleAttachmentsModelFromJson(json);

@override@JsonKey() final  String kind;
 final  List<ImageAttachmentModel> _images;
@override@JsonKey() List<ImageAttachmentModel> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  DocumentAttachmentModel? document;

/// Create a copy of ArticleAttachmentsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleAttachmentsModelCopyWith<_ArticleAttachmentsModel> get copyWith => __$ArticleAttachmentsModelCopyWithImpl<_ArticleAttachmentsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleAttachmentsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleAttachmentsModel&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.document, document) || other.document == document));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_images),document);

@override
String toString() {
  return 'ArticleAttachmentsModel(kind: $kind, images: $images, document: $document)';
}


}

/// @nodoc
abstract mixin class _$ArticleAttachmentsModelCopyWith<$Res> implements $ArticleAttachmentsModelCopyWith<$Res> {
  factory _$ArticleAttachmentsModelCopyWith(_ArticleAttachmentsModel value, $Res Function(_ArticleAttachmentsModel) _then) = __$ArticleAttachmentsModelCopyWithImpl;
@override @useResult
$Res call({
 String kind, List<ImageAttachmentModel> images, DocumentAttachmentModel? document
});


@override $DocumentAttachmentModelCopyWith<$Res>? get document;

}
/// @nodoc
class __$ArticleAttachmentsModelCopyWithImpl<$Res>
    implements _$ArticleAttachmentsModelCopyWith<$Res> {
  __$ArticleAttachmentsModelCopyWithImpl(this._self, this._then);

  final _ArticleAttachmentsModel _self;
  final $Res Function(_ArticleAttachmentsModel) _then;

/// Create a copy of ArticleAttachmentsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? images = null,Object? document = freezed,}) {
  return _then(_ArticleAttachmentsModel(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ImageAttachmentModel>,document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as DocumentAttachmentModel?,
  ));
}

/// Create a copy of ArticleAttachmentsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentAttachmentModelCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $DocumentAttachmentModelCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// @nodoc
mixin _$SetAttachmentsRequestModel {

 List<AttachmentItemModel> get items;
/// Create a copy of SetAttachmentsRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetAttachmentsRequestModelCopyWith<SetAttachmentsRequestModel> get copyWith => _$SetAttachmentsRequestModelCopyWithImpl<SetAttachmentsRequestModel>(this as SetAttachmentsRequestModel, _$identity);

  /// Serializes this SetAttachmentsRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetAttachmentsRequestModel&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'SetAttachmentsRequestModel(items: $items)';
}


}

/// @nodoc
abstract mixin class $SetAttachmentsRequestModelCopyWith<$Res>  {
  factory $SetAttachmentsRequestModelCopyWith(SetAttachmentsRequestModel value, $Res Function(SetAttachmentsRequestModel) _then) = _$SetAttachmentsRequestModelCopyWithImpl;
@useResult
$Res call({
 List<AttachmentItemModel> items
});




}
/// @nodoc
class _$SetAttachmentsRequestModelCopyWithImpl<$Res>
    implements $SetAttachmentsRequestModelCopyWith<$Res> {
  _$SetAttachmentsRequestModelCopyWithImpl(this._self, this._then);

  final SetAttachmentsRequestModel _self;
  final $Res Function(SetAttachmentsRequestModel) _then;

/// Create a copy of SetAttachmentsRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AttachmentItemModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [SetAttachmentsRequestModel].
extension SetAttachmentsRequestModelPatterns on SetAttachmentsRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetAttachmentsRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetAttachmentsRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetAttachmentsRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _SetAttachmentsRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetAttachmentsRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _SetAttachmentsRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AttachmentItemModel> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetAttachmentsRequestModel() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AttachmentItemModel> items)  $default,) {final _that = this;
switch (_that) {
case _SetAttachmentsRequestModel():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AttachmentItemModel> items)?  $default,) {final _that = this;
switch (_that) {
case _SetAttachmentsRequestModel() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetAttachmentsRequestModel implements SetAttachmentsRequestModel {
  const _SetAttachmentsRequestModel({required final  List<AttachmentItemModel> items}): _items = items;
  factory _SetAttachmentsRequestModel.fromJson(Map<String, dynamic> json) => _$SetAttachmentsRequestModelFromJson(json);

 final  List<AttachmentItemModel> _items;
@override List<AttachmentItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of SetAttachmentsRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetAttachmentsRequestModelCopyWith<_SetAttachmentsRequestModel> get copyWith => __$SetAttachmentsRequestModelCopyWithImpl<_SetAttachmentsRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetAttachmentsRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetAttachmentsRequestModel&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'SetAttachmentsRequestModel(items: $items)';
}


}

/// @nodoc
abstract mixin class _$SetAttachmentsRequestModelCopyWith<$Res> implements $SetAttachmentsRequestModelCopyWith<$Res> {
  factory _$SetAttachmentsRequestModelCopyWith(_SetAttachmentsRequestModel value, $Res Function(_SetAttachmentsRequestModel) _then) = __$SetAttachmentsRequestModelCopyWithImpl;
@override @useResult
$Res call({
 List<AttachmentItemModel> items
});




}
/// @nodoc
class __$SetAttachmentsRequestModelCopyWithImpl<$Res>
    implements _$SetAttachmentsRequestModelCopyWith<$Res> {
  __$SetAttachmentsRequestModelCopyWithImpl(this._self, this._then);

  final _SetAttachmentsRequestModel _self;
  final $Res Function(_SetAttachmentsRequestModel) _then;

/// Create a copy of SetAttachmentsRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_SetAttachmentsRequestModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AttachmentItemModel>,
  ));
}


}


/// @nodoc
mixin _$AttachmentItemModel {

 String get mediaAssetId; int get order; String? get caption; String? get altText; String? get title; bool? get allowDownload;
/// Create a copy of AttachmentItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentItemModelCopyWith<AttachmentItemModel> get copyWith => _$AttachmentItemModelCopyWithImpl<AttachmentItemModel>(this as AttachmentItemModel, _$identity);

  /// Serializes this AttachmentItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentItemModel&&(identical(other.mediaAssetId, mediaAssetId) || other.mediaAssetId == mediaAssetId)&&(identical(other.order, order) || other.order == order)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.title, title) || other.title == title)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaAssetId,order,caption,altText,title,allowDownload);

@override
String toString() {
  return 'AttachmentItemModel(mediaAssetId: $mediaAssetId, order: $order, caption: $caption, altText: $altText, title: $title, allowDownload: $allowDownload)';
}


}

/// @nodoc
abstract mixin class $AttachmentItemModelCopyWith<$Res>  {
  factory $AttachmentItemModelCopyWith(AttachmentItemModel value, $Res Function(AttachmentItemModel) _then) = _$AttachmentItemModelCopyWithImpl;
@useResult
$Res call({
 String mediaAssetId, int order, String? caption, String? altText, String? title, bool? allowDownload
});




}
/// @nodoc
class _$AttachmentItemModelCopyWithImpl<$Res>
    implements $AttachmentItemModelCopyWith<$Res> {
  _$AttachmentItemModelCopyWithImpl(this._self, this._then);

  final AttachmentItemModel _self;
  final $Res Function(AttachmentItemModel) _then;

/// Create a copy of AttachmentItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mediaAssetId = null,Object? order = null,Object? caption = freezed,Object? altText = freezed,Object? title = freezed,Object? allowDownload = freezed,}) {
  return _then(_self.copyWith(
mediaAssetId: null == mediaAssetId ? _self.mediaAssetId : mediaAssetId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,allowDownload: freezed == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttachmentItemModel].
extension AttachmentItemModelPatterns on AttachmentItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttachmentItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttachmentItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttachmentItemModel value)  $default,){
final _that = this;
switch (_that) {
case _AttachmentItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttachmentItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _AttachmentItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mediaAssetId,  int order,  String? caption,  String? altText,  String? title,  bool? allowDownload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttachmentItemModel() when $default != null:
return $default(_that.mediaAssetId,_that.order,_that.caption,_that.altText,_that.title,_that.allowDownload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mediaAssetId,  int order,  String? caption,  String? altText,  String? title,  bool? allowDownload)  $default,) {final _that = this;
switch (_that) {
case _AttachmentItemModel():
return $default(_that.mediaAssetId,_that.order,_that.caption,_that.altText,_that.title,_that.allowDownload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mediaAssetId,  int order,  String? caption,  String? altText,  String? title,  bool? allowDownload)?  $default,) {final _that = this;
switch (_that) {
case _AttachmentItemModel() when $default != null:
return $default(_that.mediaAssetId,_that.order,_that.caption,_that.altText,_that.title,_that.allowDownload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttachmentItemModel implements AttachmentItemModel {
  const _AttachmentItemModel({required this.mediaAssetId, required this.order, this.caption, this.altText, this.title, this.allowDownload});
  factory _AttachmentItemModel.fromJson(Map<String, dynamic> json) => _$AttachmentItemModelFromJson(json);

@override final  String mediaAssetId;
@override final  int order;
@override final  String? caption;
@override final  String? altText;
@override final  String? title;
@override final  bool? allowDownload;

/// Create a copy of AttachmentItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentItemModelCopyWith<_AttachmentItemModel> get copyWith => __$AttachmentItemModelCopyWithImpl<_AttachmentItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttachmentItemModel&&(identical(other.mediaAssetId, mediaAssetId) || other.mediaAssetId == mediaAssetId)&&(identical(other.order, order) || other.order == order)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.title, title) || other.title == title)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaAssetId,order,caption,altText,title,allowDownload);

@override
String toString() {
  return 'AttachmentItemModel(mediaAssetId: $mediaAssetId, order: $order, caption: $caption, altText: $altText, title: $title, allowDownload: $allowDownload)';
}


}

/// @nodoc
abstract mixin class _$AttachmentItemModelCopyWith<$Res> implements $AttachmentItemModelCopyWith<$Res> {
  factory _$AttachmentItemModelCopyWith(_AttachmentItemModel value, $Res Function(_AttachmentItemModel) _then) = __$AttachmentItemModelCopyWithImpl;
@override @useResult
$Res call({
 String mediaAssetId, int order, String? caption, String? altText, String? title, bool? allowDownload
});




}
/// @nodoc
class __$AttachmentItemModelCopyWithImpl<$Res>
    implements _$AttachmentItemModelCopyWith<$Res> {
  __$AttachmentItemModelCopyWithImpl(this._self, this._then);

  final _AttachmentItemModel _self;
  final $Res Function(_AttachmentItemModel) _then;

/// Create a copy of AttachmentItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mediaAssetId = null,Object? order = null,Object? caption = freezed,Object? altText = freezed,Object? title = freezed,Object? allowDownload = freezed,}) {
  return _then(_AttachmentItemModel(
mediaAssetId: null == mediaAssetId ? _self.mediaAssetId : mediaAssetId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,allowDownload: freezed == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
