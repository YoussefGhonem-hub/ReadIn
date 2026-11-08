// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LegalModel {

 String get termsVersion; DateTime? get effectiveAt; LegalSummaryModel get summary; LegalPagesModel? get pages;
/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalModelCopyWith<LegalModel> get copyWith => _$LegalModelCopyWithImpl<LegalModel>(this as LegalModel, _$identity);

  /// Serializes this LegalModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalModel&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion)&&(identical(other.effectiveAt, effectiveAt) || other.effectiveAt == effectiveAt)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,termsVersion,effectiveAt,summary,pages);

@override
String toString() {
  return 'LegalModel(termsVersion: $termsVersion, effectiveAt: $effectiveAt, summary: $summary, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $LegalModelCopyWith<$Res>  {
  factory $LegalModelCopyWith(LegalModel value, $Res Function(LegalModel) _then) = _$LegalModelCopyWithImpl;
@useResult
$Res call({
 String termsVersion, DateTime? effectiveAt, LegalSummaryModel summary, LegalPagesModel? pages
});


$LegalSummaryModelCopyWith<$Res> get summary;$LegalPagesModelCopyWith<$Res>? get pages;

}
/// @nodoc
class _$LegalModelCopyWithImpl<$Res>
    implements $LegalModelCopyWith<$Res> {
  _$LegalModelCopyWithImpl(this._self, this._then);

  final LegalModel _self;
  final $Res Function(LegalModel) _then;

/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? termsVersion = null,Object? effectiveAt = freezed,Object? summary = null,Object? pages = freezed,}) {
  return _then(_self.copyWith(
termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,effectiveAt: freezed == effectiveAt ? _self.effectiveAt : effectiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as LegalSummaryModel,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as LegalPagesModel?,
  ));
}
/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalSummaryModelCopyWith<$Res> get summary {
  
  return $LegalSummaryModelCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalPagesModelCopyWith<$Res>? get pages {
    if (_self.pages == null) {
    return null;
  }

  return $LegalPagesModelCopyWith<$Res>(_self.pages!, (value) {
    return _then(_self.copyWith(pages: value));
  });
}
}


/// Adds pattern-matching-related methods to [LegalModel].
extension LegalModelPatterns on LegalModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalModel value)  $default,){
final _that = this;
switch (_that) {
case _LegalModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalModel value)?  $default,){
final _that = this;
switch (_that) {
case _LegalModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String termsVersion,  DateTime? effectiveAt,  LegalSummaryModel summary,  LegalPagesModel? pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalModel() when $default != null:
return $default(_that.termsVersion,_that.effectiveAt,_that.summary,_that.pages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String termsVersion,  DateTime? effectiveAt,  LegalSummaryModel summary,  LegalPagesModel? pages)  $default,) {final _that = this;
switch (_that) {
case _LegalModel():
return $default(_that.termsVersion,_that.effectiveAt,_that.summary,_that.pages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String termsVersion,  DateTime? effectiveAt,  LegalSummaryModel summary,  LegalPagesModel? pages)?  $default,) {final _that = this;
switch (_that) {
case _LegalModel() when $default != null:
return $default(_that.termsVersion,_that.effectiveAt,_that.summary,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LegalModel extends LegalModel {
  const _LegalModel({required this.termsVersion, this.effectiveAt, this.summary = const LegalSummaryModel(), this.pages}): super._();
  factory _LegalModel.fromJson(Map<String, dynamic> json) => _$LegalModelFromJson(json);

@override final  String termsVersion;
@override final  DateTime? effectiveAt;
@override@JsonKey() final  LegalSummaryModel summary;
@override final  LegalPagesModel? pages;

/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalModelCopyWith<_LegalModel> get copyWith => __$LegalModelCopyWithImpl<_LegalModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LegalModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalModel&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion)&&(identical(other.effectiveAt, effectiveAt) || other.effectiveAt == effectiveAt)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,termsVersion,effectiveAt,summary,pages);

@override
String toString() {
  return 'LegalModel(termsVersion: $termsVersion, effectiveAt: $effectiveAt, summary: $summary, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$LegalModelCopyWith<$Res> implements $LegalModelCopyWith<$Res> {
  factory _$LegalModelCopyWith(_LegalModel value, $Res Function(_LegalModel) _then) = __$LegalModelCopyWithImpl;
@override @useResult
$Res call({
 String termsVersion, DateTime? effectiveAt, LegalSummaryModel summary, LegalPagesModel? pages
});


@override $LegalSummaryModelCopyWith<$Res> get summary;@override $LegalPagesModelCopyWith<$Res>? get pages;

}
/// @nodoc
class __$LegalModelCopyWithImpl<$Res>
    implements _$LegalModelCopyWith<$Res> {
  __$LegalModelCopyWithImpl(this._self, this._then);

  final _LegalModel _self;
  final $Res Function(_LegalModel) _then;

/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? termsVersion = null,Object? effectiveAt = freezed,Object? summary = null,Object? pages = freezed,}) {
  return _then(_LegalModel(
termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,effectiveAt: freezed == effectiveAt ? _self.effectiveAt : effectiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as LegalSummaryModel,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as LegalPagesModel?,
  ));
}

/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalSummaryModelCopyWith<$Res> get summary {
  
  return $LegalSummaryModelCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of LegalModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalPagesModelCopyWith<$Res>? get pages {
    if (_self.pages == null) {
    return null;
  }

  return $LegalPagesModelCopyWith<$Res>(_self.pages!, (value) {
    return _then(_self.copyWith(pages: value));
  });
}
}


/// @nodoc
mixin _$LegalSummaryModel {

 String? get ar; String? get en;
/// Create a copy of LegalSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalSummaryModelCopyWith<LegalSummaryModel> get copyWith => _$LegalSummaryModelCopyWithImpl<LegalSummaryModel>(this as LegalSummaryModel, _$identity);

  /// Serializes this LegalSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalSummaryModel&&(identical(other.ar, ar) || other.ar == ar)&&(identical(other.en, en) || other.en == en));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ar,en);

@override
String toString() {
  return 'LegalSummaryModel(ar: $ar, en: $en)';
}


}

/// @nodoc
abstract mixin class $LegalSummaryModelCopyWith<$Res>  {
  factory $LegalSummaryModelCopyWith(LegalSummaryModel value, $Res Function(LegalSummaryModel) _then) = _$LegalSummaryModelCopyWithImpl;
@useResult
$Res call({
 String? ar, String? en
});




}
/// @nodoc
class _$LegalSummaryModelCopyWithImpl<$Res>
    implements $LegalSummaryModelCopyWith<$Res> {
  _$LegalSummaryModelCopyWithImpl(this._self, this._then);

  final LegalSummaryModel _self;
  final $Res Function(LegalSummaryModel) _then;

/// Create a copy of LegalSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ar = freezed,Object? en = freezed,}) {
  return _then(_self.copyWith(
ar: freezed == ar ? _self.ar : ar // ignore: cast_nullable_to_non_nullable
as String?,en: freezed == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LegalSummaryModel].
extension LegalSummaryModelPatterns on LegalSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _LegalSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _LegalSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? ar,  String? en)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalSummaryModel() when $default != null:
return $default(_that.ar,_that.en);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? ar,  String? en)  $default,) {final _that = this;
switch (_that) {
case _LegalSummaryModel():
return $default(_that.ar,_that.en);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? ar,  String? en)?  $default,) {final _that = this;
switch (_that) {
case _LegalSummaryModel() when $default != null:
return $default(_that.ar,_that.en);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LegalSummaryModel implements LegalSummaryModel {
  const _LegalSummaryModel({this.ar, this.en});
  factory _LegalSummaryModel.fromJson(Map<String, dynamic> json) => _$LegalSummaryModelFromJson(json);

@override final  String? ar;
@override final  String? en;

/// Create a copy of LegalSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalSummaryModelCopyWith<_LegalSummaryModel> get copyWith => __$LegalSummaryModelCopyWithImpl<_LegalSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LegalSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalSummaryModel&&(identical(other.ar, ar) || other.ar == ar)&&(identical(other.en, en) || other.en == en));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ar,en);

@override
String toString() {
  return 'LegalSummaryModel(ar: $ar, en: $en)';
}


}

/// @nodoc
abstract mixin class _$LegalSummaryModelCopyWith<$Res> implements $LegalSummaryModelCopyWith<$Res> {
  factory _$LegalSummaryModelCopyWith(_LegalSummaryModel value, $Res Function(_LegalSummaryModel) _then) = __$LegalSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String? ar, String? en
});




}
/// @nodoc
class __$LegalSummaryModelCopyWithImpl<$Res>
    implements _$LegalSummaryModelCopyWith<$Res> {
  __$LegalSummaryModelCopyWithImpl(this._self, this._then);

  final _LegalSummaryModel _self;
  final $Res Function(_LegalSummaryModel) _then;

/// Create a copy of LegalSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ar = freezed,Object? en = freezed,}) {
  return _then(_LegalSummaryModel(
ar: freezed == ar ? _self.ar : ar // ignore: cast_nullable_to_non_nullable
as String?,en: freezed == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LegalPagesModel {

 String get terms; String get communityGuidelines; String get privacy;
/// Create a copy of LegalPagesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalPagesModelCopyWith<LegalPagesModel> get copyWith => _$LegalPagesModelCopyWithImpl<LegalPagesModel>(this as LegalPagesModel, _$identity);

  /// Serializes this LegalPagesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalPagesModel&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.communityGuidelines, communityGuidelines) || other.communityGuidelines == communityGuidelines)&&(identical(other.privacy, privacy) || other.privacy == privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,terms,communityGuidelines,privacy);

@override
String toString() {
  return 'LegalPagesModel(terms: $terms, communityGuidelines: $communityGuidelines, privacy: $privacy)';
}


}

/// @nodoc
abstract mixin class $LegalPagesModelCopyWith<$Res>  {
  factory $LegalPagesModelCopyWith(LegalPagesModel value, $Res Function(LegalPagesModel) _then) = _$LegalPagesModelCopyWithImpl;
@useResult
$Res call({
 String terms, String communityGuidelines, String privacy
});




}
/// @nodoc
class _$LegalPagesModelCopyWithImpl<$Res>
    implements $LegalPagesModelCopyWith<$Res> {
  _$LegalPagesModelCopyWithImpl(this._self, this._then);

  final LegalPagesModel _self;
  final $Res Function(LegalPagesModel) _then;

/// Create a copy of LegalPagesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? terms = null,Object? communityGuidelines = null,Object? privacy = null,}) {
  return _then(_self.copyWith(
terms: null == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as String,communityGuidelines: null == communityGuidelines ? _self.communityGuidelines : communityGuidelines // ignore: cast_nullable_to_non_nullable
as String,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LegalPagesModel].
extension LegalPagesModelPatterns on LegalPagesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalPagesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalPagesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalPagesModel value)  $default,){
final _that = this;
switch (_that) {
case _LegalPagesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalPagesModel value)?  $default,){
final _that = this;
switch (_that) {
case _LegalPagesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String terms,  String communityGuidelines,  String privacy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalPagesModel() when $default != null:
return $default(_that.terms,_that.communityGuidelines,_that.privacy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String terms,  String communityGuidelines,  String privacy)  $default,) {final _that = this;
switch (_that) {
case _LegalPagesModel():
return $default(_that.terms,_that.communityGuidelines,_that.privacy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String terms,  String communityGuidelines,  String privacy)?  $default,) {final _that = this;
switch (_that) {
case _LegalPagesModel() when $default != null:
return $default(_that.terms,_that.communityGuidelines,_that.privacy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LegalPagesModel extends LegalPagesModel {
  const _LegalPagesModel({this.terms = '/terms', this.communityGuidelines = '/community-guidelines', this.privacy = '/privacy'}): super._();
  factory _LegalPagesModel.fromJson(Map<String, dynamic> json) => _$LegalPagesModelFromJson(json);

@override@JsonKey() final  String terms;
@override@JsonKey() final  String communityGuidelines;
@override@JsonKey() final  String privacy;

/// Create a copy of LegalPagesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalPagesModelCopyWith<_LegalPagesModel> get copyWith => __$LegalPagesModelCopyWithImpl<_LegalPagesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LegalPagesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalPagesModel&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.communityGuidelines, communityGuidelines) || other.communityGuidelines == communityGuidelines)&&(identical(other.privacy, privacy) || other.privacy == privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,terms,communityGuidelines,privacy);

@override
String toString() {
  return 'LegalPagesModel(terms: $terms, communityGuidelines: $communityGuidelines, privacy: $privacy)';
}


}

/// @nodoc
abstract mixin class _$LegalPagesModelCopyWith<$Res> implements $LegalPagesModelCopyWith<$Res> {
  factory _$LegalPagesModelCopyWith(_LegalPagesModel value, $Res Function(_LegalPagesModel) _then) = __$LegalPagesModelCopyWithImpl;
@override @useResult
$Res call({
 String terms, String communityGuidelines, String privacy
});




}
/// @nodoc
class __$LegalPagesModelCopyWithImpl<$Res>
    implements _$LegalPagesModelCopyWith<$Res> {
  __$LegalPagesModelCopyWithImpl(this._self, this._then);

  final _LegalPagesModel _self;
  final $Res Function(_LegalPagesModel) _then;

/// Create a copy of LegalPagesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? terms = null,Object? communityGuidelines = null,Object? privacy = null,}) {
  return _then(_LegalPagesModel(
terms: null == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as String,communityGuidelines: null == communityGuidelines ? _self.communityGuidelines : communityGuidelines // ignore: cast_nullable_to_non_nullable
as String,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
