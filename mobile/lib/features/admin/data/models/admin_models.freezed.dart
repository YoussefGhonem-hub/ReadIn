// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminSummaryModel {

 int? get openReports; int? get openTickets; int? get pendingVerifications; int get total; int? get openReportsOver24h;
/// Create a copy of AdminSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminSummaryModelCopyWith<AdminSummaryModel> get copyWith => _$AdminSummaryModelCopyWithImpl<AdminSummaryModel>(this as AdminSummaryModel, _$identity);

  /// Serializes this AdminSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminSummaryModel&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.openTickets, openTickets) || other.openTickets == openTickets)&&(identical(other.pendingVerifications, pendingVerifications) || other.pendingVerifications == pendingVerifications)&&(identical(other.total, total) || other.total == total)&&(identical(other.openReportsOver24h, openReportsOver24h) || other.openReportsOver24h == openReportsOver24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,openReports,openTickets,pendingVerifications,total,openReportsOver24h);

@override
String toString() {
  return 'AdminSummaryModel(openReports: $openReports, openTickets: $openTickets, pendingVerifications: $pendingVerifications, total: $total, openReportsOver24h: $openReportsOver24h)';
}


}

/// @nodoc
abstract mixin class $AdminSummaryModelCopyWith<$Res>  {
  factory $AdminSummaryModelCopyWith(AdminSummaryModel value, $Res Function(AdminSummaryModel) _then) = _$AdminSummaryModelCopyWithImpl;
@useResult
$Res call({
 int? openReports, int? openTickets, int? pendingVerifications, int total, int? openReportsOver24h
});




}
/// @nodoc
class _$AdminSummaryModelCopyWithImpl<$Res>
    implements $AdminSummaryModelCopyWith<$Res> {
  _$AdminSummaryModelCopyWithImpl(this._self, this._then);

  final AdminSummaryModel _self;
  final $Res Function(AdminSummaryModel) _then;

/// Create a copy of AdminSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? openReports = freezed,Object? openTickets = freezed,Object? pendingVerifications = freezed,Object? total = null,Object? openReportsOver24h = freezed,}) {
  return _then(_self.copyWith(
openReports: freezed == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int?,openTickets: freezed == openTickets ? _self.openTickets : openTickets // ignore: cast_nullable_to_non_nullable
as int?,pendingVerifications: freezed == pendingVerifications ? _self.pendingVerifications : pendingVerifications // ignore: cast_nullable_to_non_nullable
as int?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,openReportsOver24h: freezed == openReportsOver24h ? _self.openReportsOver24h : openReportsOver24h // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminSummaryModel].
extension AdminSummaryModelPatterns on AdminSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? openReports,  int? openTickets,  int? pendingVerifications,  int total,  int? openReportsOver24h)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminSummaryModel() when $default != null:
return $default(_that.openReports,_that.openTickets,_that.pendingVerifications,_that.total,_that.openReportsOver24h);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? openReports,  int? openTickets,  int? pendingVerifications,  int total,  int? openReportsOver24h)  $default,) {final _that = this;
switch (_that) {
case _AdminSummaryModel():
return $default(_that.openReports,_that.openTickets,_that.pendingVerifications,_that.total,_that.openReportsOver24h);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? openReports,  int? openTickets,  int? pendingVerifications,  int total,  int? openReportsOver24h)?  $default,) {final _that = this;
switch (_that) {
case _AdminSummaryModel() when $default != null:
return $default(_that.openReports,_that.openTickets,_that.pendingVerifications,_that.total,_that.openReportsOver24h);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminSummaryModel extends AdminSummaryModel {
  const _AdminSummaryModel({this.openReports, this.openTickets, this.pendingVerifications, this.total = 0, this.openReportsOver24h}): super._();
  factory _AdminSummaryModel.fromJson(Map<String, dynamic> json) => _$AdminSummaryModelFromJson(json);

@override final  int? openReports;
@override final  int? openTickets;
@override final  int? pendingVerifications;
@override@JsonKey() final  int total;
@override final  int? openReportsOver24h;

/// Create a copy of AdminSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminSummaryModelCopyWith<_AdminSummaryModel> get copyWith => __$AdminSummaryModelCopyWithImpl<_AdminSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminSummaryModel&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.openTickets, openTickets) || other.openTickets == openTickets)&&(identical(other.pendingVerifications, pendingVerifications) || other.pendingVerifications == pendingVerifications)&&(identical(other.total, total) || other.total == total)&&(identical(other.openReportsOver24h, openReportsOver24h) || other.openReportsOver24h == openReportsOver24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,openReports,openTickets,pendingVerifications,total,openReportsOver24h);

@override
String toString() {
  return 'AdminSummaryModel(openReports: $openReports, openTickets: $openTickets, pendingVerifications: $pendingVerifications, total: $total, openReportsOver24h: $openReportsOver24h)';
}


}

/// @nodoc
abstract mixin class _$AdminSummaryModelCopyWith<$Res> implements $AdminSummaryModelCopyWith<$Res> {
  factory _$AdminSummaryModelCopyWith(_AdminSummaryModel value, $Res Function(_AdminSummaryModel) _then) = __$AdminSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 int? openReports, int? openTickets, int? pendingVerifications, int total, int? openReportsOver24h
});




}
/// @nodoc
class __$AdminSummaryModelCopyWithImpl<$Res>
    implements _$AdminSummaryModelCopyWith<$Res> {
  __$AdminSummaryModelCopyWithImpl(this._self, this._then);

  final _AdminSummaryModel _self;
  final $Res Function(_AdminSummaryModel) _then;

/// Create a copy of AdminSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? openReports = freezed,Object? openTickets = freezed,Object? pendingVerifications = freezed,Object? total = null,Object? openReportsOver24h = freezed,}) {
  return _then(_AdminSummaryModel(
openReports: freezed == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int?,openTickets: freezed == openTickets ? _self.openTickets : openTickets // ignore: cast_nullable_to_non_nullable
as int?,pendingVerifications: freezed == pendingVerifications ? _self.pendingVerifications : pendingVerifications // ignore: cast_nullable_to_non_nullable
as int?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,openReportsOver24h: freezed == openReportsOver24h ? _self.openReportsOver24h : openReportsOver24h // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$DashboardValueModel {

 int get value; int get previous; int get phone; int get google; int get apple;
/// Create a copy of DashboardValueModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<DashboardValueModel> get copyWith => _$DashboardValueModelCopyWithImpl<DashboardValueModel>(this as DashboardValueModel, _$identity);

  /// Serializes this DashboardValueModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardValueModel&&(identical(other.value, value) || other.value == value)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.google, google) || other.google == google)&&(identical(other.apple, apple) || other.apple == apple));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,previous,phone,google,apple);

@override
String toString() {
  return 'DashboardValueModel(value: $value, previous: $previous, phone: $phone, google: $google, apple: $apple)';
}


}

/// @nodoc
abstract mixin class $DashboardValueModelCopyWith<$Res>  {
  factory $DashboardValueModelCopyWith(DashboardValueModel value, $Res Function(DashboardValueModel) _then) = _$DashboardValueModelCopyWithImpl;
@useResult
$Res call({
 int value, int previous, int phone, int google, int apple
});




}
/// @nodoc
class _$DashboardValueModelCopyWithImpl<$Res>
    implements $DashboardValueModelCopyWith<$Res> {
  _$DashboardValueModelCopyWithImpl(this._self, this._then);

  final DashboardValueModel _self;
  final $Res Function(DashboardValueModel) _then;

/// Create a copy of DashboardValueModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? previous = null,Object? phone = null,Object? google = null,Object? apple = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,previous: null == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as int,google: null == google ? _self.google : google // ignore: cast_nullable_to_non_nullable
as int,apple: null == apple ? _self.apple : apple // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardValueModel].
extension DashboardValueModelPatterns on DashboardValueModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardValueModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardValueModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardValueModel value)  $default,){
final _that = this;
switch (_that) {
case _DashboardValueModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardValueModel value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardValueModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value,  int previous,  int phone,  int google,  int apple)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardValueModel() when $default != null:
return $default(_that.value,_that.previous,_that.phone,_that.google,_that.apple);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value,  int previous,  int phone,  int google,  int apple)  $default,) {final _that = this;
switch (_that) {
case _DashboardValueModel():
return $default(_that.value,_that.previous,_that.phone,_that.google,_that.apple);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value,  int previous,  int phone,  int google,  int apple)?  $default,) {final _that = this;
switch (_that) {
case _DashboardValueModel() when $default != null:
return $default(_that.value,_that.previous,_that.phone,_that.google,_that.apple);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardValueModel extends DashboardValueModel {
  const _DashboardValueModel({this.value = 0, this.previous = 0, this.phone = 0, this.google = 0, this.apple = 0}): super._();
  factory _DashboardValueModel.fromJson(Map<String, dynamic> json) => _$DashboardValueModelFromJson(json);

@override@JsonKey() final  int value;
@override@JsonKey() final  int previous;
@override@JsonKey() final  int phone;
@override@JsonKey() final  int google;
@override@JsonKey() final  int apple;

/// Create a copy of DashboardValueModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardValueModelCopyWith<_DashboardValueModel> get copyWith => __$DashboardValueModelCopyWithImpl<_DashboardValueModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardValueModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardValueModel&&(identical(other.value, value) || other.value == value)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.google, google) || other.google == google)&&(identical(other.apple, apple) || other.apple == apple));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,previous,phone,google,apple);

@override
String toString() {
  return 'DashboardValueModel(value: $value, previous: $previous, phone: $phone, google: $google, apple: $apple)';
}


}

/// @nodoc
abstract mixin class _$DashboardValueModelCopyWith<$Res> implements $DashboardValueModelCopyWith<$Res> {
  factory _$DashboardValueModelCopyWith(_DashboardValueModel value, $Res Function(_DashboardValueModel) _then) = __$DashboardValueModelCopyWithImpl;
@override @useResult
$Res call({
 int value, int previous, int phone, int google, int apple
});




}
/// @nodoc
class __$DashboardValueModelCopyWithImpl<$Res>
    implements _$DashboardValueModelCopyWith<$Res> {
  __$DashboardValueModelCopyWithImpl(this._self, this._then);

  final _DashboardValueModel _self;
  final $Res Function(_DashboardValueModel) _then;

/// Create a copy of DashboardValueModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? previous = null,Object? phone = null,Object? google = null,Object? apple = null,}) {
  return _then(_DashboardValueModel(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,previous: null == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as int,google: null == google ? _self.google : google // ignore: cast_nullable_to_non_nullable
as int,apple: null == apple ? _self.apple : apple // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DashboardCardsModel {

 DashboardValueModel get articlesPublished; DashboardValueModel get newUsers; DashboardValueModel get activeReaders; DashboardValueModel get reads; DashboardValueModel get comments; DashboardValueModel get reactions; DashboardValueModel get reposts; int? get openReports; int? get openTickets; int? get pendingVerifications; int get suspendedNow; int? get openReportsOver24h;
/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardCardsModelCopyWith<DashboardCardsModel> get copyWith => _$DashboardCardsModelCopyWithImpl<DashboardCardsModel>(this as DashboardCardsModel, _$identity);

  /// Serializes this DashboardCardsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardCardsModel&&(identical(other.articlesPublished, articlesPublished) || other.articlesPublished == articlesPublished)&&(identical(other.newUsers, newUsers) || other.newUsers == newUsers)&&(identical(other.activeReaders, activeReaders) || other.activeReaders == activeReaders)&&(identical(other.reads, reads) || other.reads == reads)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.reposts, reposts) || other.reposts == reposts)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.openTickets, openTickets) || other.openTickets == openTickets)&&(identical(other.pendingVerifications, pendingVerifications) || other.pendingVerifications == pendingVerifications)&&(identical(other.suspendedNow, suspendedNow) || other.suspendedNow == suspendedNow)&&(identical(other.openReportsOver24h, openReportsOver24h) || other.openReportsOver24h == openReportsOver24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,articlesPublished,newUsers,activeReaders,reads,comments,reactions,reposts,openReports,openTickets,pendingVerifications,suspendedNow,openReportsOver24h);

@override
String toString() {
  return 'DashboardCardsModel(articlesPublished: $articlesPublished, newUsers: $newUsers, activeReaders: $activeReaders, reads: $reads, comments: $comments, reactions: $reactions, reposts: $reposts, openReports: $openReports, openTickets: $openTickets, pendingVerifications: $pendingVerifications, suspendedNow: $suspendedNow, openReportsOver24h: $openReportsOver24h)';
}


}

/// @nodoc
abstract mixin class $DashboardCardsModelCopyWith<$Res>  {
  factory $DashboardCardsModelCopyWith(DashboardCardsModel value, $Res Function(DashboardCardsModel) _then) = _$DashboardCardsModelCopyWithImpl;
@useResult
$Res call({
 DashboardValueModel articlesPublished, DashboardValueModel newUsers, DashboardValueModel activeReaders, DashboardValueModel reads, DashboardValueModel comments, DashboardValueModel reactions, DashboardValueModel reposts, int? openReports, int? openTickets, int? pendingVerifications, int suspendedNow, int? openReportsOver24h
});


$DashboardValueModelCopyWith<$Res> get articlesPublished;$DashboardValueModelCopyWith<$Res> get newUsers;$DashboardValueModelCopyWith<$Res> get activeReaders;$DashboardValueModelCopyWith<$Res> get reads;$DashboardValueModelCopyWith<$Res> get comments;$DashboardValueModelCopyWith<$Res> get reactions;$DashboardValueModelCopyWith<$Res> get reposts;

}
/// @nodoc
class _$DashboardCardsModelCopyWithImpl<$Res>
    implements $DashboardCardsModelCopyWith<$Res> {
  _$DashboardCardsModelCopyWithImpl(this._self, this._then);

  final DashboardCardsModel _self;
  final $Res Function(DashboardCardsModel) _then;

/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? articlesPublished = null,Object? newUsers = null,Object? activeReaders = null,Object? reads = null,Object? comments = null,Object? reactions = null,Object? reposts = null,Object? openReports = freezed,Object? openTickets = freezed,Object? pendingVerifications = freezed,Object? suspendedNow = null,Object? openReportsOver24h = freezed,}) {
  return _then(_self.copyWith(
articlesPublished: null == articlesPublished ? _self.articlesPublished : articlesPublished // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,newUsers: null == newUsers ? _self.newUsers : newUsers // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,activeReaders: null == activeReaders ? _self.activeReaders : activeReaders // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,reads: null == reads ? _self.reads : reads // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,reposts: null == reposts ? _self.reposts : reposts // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,openReports: freezed == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int?,openTickets: freezed == openTickets ? _self.openTickets : openTickets // ignore: cast_nullable_to_non_nullable
as int?,pendingVerifications: freezed == pendingVerifications ? _self.pendingVerifications : pendingVerifications // ignore: cast_nullable_to_non_nullable
as int?,suspendedNow: null == suspendedNow ? _self.suspendedNow : suspendedNow // ignore: cast_nullable_to_non_nullable
as int,openReportsOver24h: freezed == openReportsOver24h ? _self.openReportsOver24h : openReportsOver24h // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get articlesPublished {
  
  return $DashboardValueModelCopyWith<$Res>(_self.articlesPublished, (value) {
    return _then(_self.copyWith(articlesPublished: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get newUsers {
  
  return $DashboardValueModelCopyWith<$Res>(_self.newUsers, (value) {
    return _then(_self.copyWith(newUsers: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get activeReaders {
  
  return $DashboardValueModelCopyWith<$Res>(_self.activeReaders, (value) {
    return _then(_self.copyWith(activeReaders: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get reads {
  
  return $DashboardValueModelCopyWith<$Res>(_self.reads, (value) {
    return _then(_self.copyWith(reads: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get comments {
  
  return $DashboardValueModelCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get reactions {
  
  return $DashboardValueModelCopyWith<$Res>(_self.reactions, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get reposts {
  
  return $DashboardValueModelCopyWith<$Res>(_self.reposts, (value) {
    return _then(_self.copyWith(reposts: value));
  });
}
}


/// Adds pattern-matching-related methods to [DashboardCardsModel].
extension DashboardCardsModelPatterns on DashboardCardsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardCardsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardCardsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardCardsModel value)  $default,){
final _that = this;
switch (_that) {
case _DashboardCardsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardCardsModel value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardCardsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DashboardValueModel articlesPublished,  DashboardValueModel newUsers,  DashboardValueModel activeReaders,  DashboardValueModel reads,  DashboardValueModel comments,  DashboardValueModel reactions,  DashboardValueModel reposts,  int? openReports,  int? openTickets,  int? pendingVerifications,  int suspendedNow,  int? openReportsOver24h)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardCardsModel() when $default != null:
return $default(_that.articlesPublished,_that.newUsers,_that.activeReaders,_that.reads,_that.comments,_that.reactions,_that.reposts,_that.openReports,_that.openTickets,_that.pendingVerifications,_that.suspendedNow,_that.openReportsOver24h);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DashboardValueModel articlesPublished,  DashboardValueModel newUsers,  DashboardValueModel activeReaders,  DashboardValueModel reads,  DashboardValueModel comments,  DashboardValueModel reactions,  DashboardValueModel reposts,  int? openReports,  int? openTickets,  int? pendingVerifications,  int suspendedNow,  int? openReportsOver24h)  $default,) {final _that = this;
switch (_that) {
case _DashboardCardsModel():
return $default(_that.articlesPublished,_that.newUsers,_that.activeReaders,_that.reads,_that.comments,_that.reactions,_that.reposts,_that.openReports,_that.openTickets,_that.pendingVerifications,_that.suspendedNow,_that.openReportsOver24h);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DashboardValueModel articlesPublished,  DashboardValueModel newUsers,  DashboardValueModel activeReaders,  DashboardValueModel reads,  DashboardValueModel comments,  DashboardValueModel reactions,  DashboardValueModel reposts,  int? openReports,  int? openTickets,  int? pendingVerifications,  int suspendedNow,  int? openReportsOver24h)?  $default,) {final _that = this;
switch (_that) {
case _DashboardCardsModel() when $default != null:
return $default(_that.articlesPublished,_that.newUsers,_that.activeReaders,_that.reads,_that.comments,_that.reactions,_that.reposts,_that.openReports,_that.openTickets,_that.pendingVerifications,_that.suspendedNow,_that.openReportsOver24h);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardCardsModel extends DashboardCardsModel {
  const _DashboardCardsModel({this.articlesPublished = const DashboardValueModel(), this.newUsers = const DashboardValueModel(), this.activeReaders = const DashboardValueModel(), this.reads = const DashboardValueModel(), this.comments = const DashboardValueModel(), this.reactions = const DashboardValueModel(), this.reposts = const DashboardValueModel(), this.openReports, this.openTickets, this.pendingVerifications, this.suspendedNow = 0, this.openReportsOver24h}): super._();
  factory _DashboardCardsModel.fromJson(Map<String, dynamic> json) => _$DashboardCardsModelFromJson(json);

@override@JsonKey() final  DashboardValueModel articlesPublished;
@override@JsonKey() final  DashboardValueModel newUsers;
@override@JsonKey() final  DashboardValueModel activeReaders;
@override@JsonKey() final  DashboardValueModel reads;
@override@JsonKey() final  DashboardValueModel comments;
@override@JsonKey() final  DashboardValueModel reactions;
@override@JsonKey() final  DashboardValueModel reposts;
@override final  int? openReports;
@override final  int? openTickets;
@override final  int? pendingVerifications;
@override@JsonKey() final  int suspendedNow;
@override final  int? openReportsOver24h;

/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardCardsModelCopyWith<_DashboardCardsModel> get copyWith => __$DashboardCardsModelCopyWithImpl<_DashboardCardsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardCardsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardCardsModel&&(identical(other.articlesPublished, articlesPublished) || other.articlesPublished == articlesPublished)&&(identical(other.newUsers, newUsers) || other.newUsers == newUsers)&&(identical(other.activeReaders, activeReaders) || other.activeReaders == activeReaders)&&(identical(other.reads, reads) || other.reads == reads)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.reactions, reactions) || other.reactions == reactions)&&(identical(other.reposts, reposts) || other.reposts == reposts)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.openTickets, openTickets) || other.openTickets == openTickets)&&(identical(other.pendingVerifications, pendingVerifications) || other.pendingVerifications == pendingVerifications)&&(identical(other.suspendedNow, suspendedNow) || other.suspendedNow == suspendedNow)&&(identical(other.openReportsOver24h, openReportsOver24h) || other.openReportsOver24h == openReportsOver24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,articlesPublished,newUsers,activeReaders,reads,comments,reactions,reposts,openReports,openTickets,pendingVerifications,suspendedNow,openReportsOver24h);

@override
String toString() {
  return 'DashboardCardsModel(articlesPublished: $articlesPublished, newUsers: $newUsers, activeReaders: $activeReaders, reads: $reads, comments: $comments, reactions: $reactions, reposts: $reposts, openReports: $openReports, openTickets: $openTickets, pendingVerifications: $pendingVerifications, suspendedNow: $suspendedNow, openReportsOver24h: $openReportsOver24h)';
}


}

/// @nodoc
abstract mixin class _$DashboardCardsModelCopyWith<$Res> implements $DashboardCardsModelCopyWith<$Res> {
  factory _$DashboardCardsModelCopyWith(_DashboardCardsModel value, $Res Function(_DashboardCardsModel) _then) = __$DashboardCardsModelCopyWithImpl;
@override @useResult
$Res call({
 DashboardValueModel articlesPublished, DashboardValueModel newUsers, DashboardValueModel activeReaders, DashboardValueModel reads, DashboardValueModel comments, DashboardValueModel reactions, DashboardValueModel reposts, int? openReports, int? openTickets, int? pendingVerifications, int suspendedNow, int? openReportsOver24h
});


@override $DashboardValueModelCopyWith<$Res> get articlesPublished;@override $DashboardValueModelCopyWith<$Res> get newUsers;@override $DashboardValueModelCopyWith<$Res> get activeReaders;@override $DashboardValueModelCopyWith<$Res> get reads;@override $DashboardValueModelCopyWith<$Res> get comments;@override $DashboardValueModelCopyWith<$Res> get reactions;@override $DashboardValueModelCopyWith<$Res> get reposts;

}
/// @nodoc
class __$DashboardCardsModelCopyWithImpl<$Res>
    implements _$DashboardCardsModelCopyWith<$Res> {
  __$DashboardCardsModelCopyWithImpl(this._self, this._then);

  final _DashboardCardsModel _self;
  final $Res Function(_DashboardCardsModel) _then;

/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? articlesPublished = null,Object? newUsers = null,Object? activeReaders = null,Object? reads = null,Object? comments = null,Object? reactions = null,Object? reposts = null,Object? openReports = freezed,Object? openTickets = freezed,Object? pendingVerifications = freezed,Object? suspendedNow = null,Object? openReportsOver24h = freezed,}) {
  return _then(_DashboardCardsModel(
articlesPublished: null == articlesPublished ? _self.articlesPublished : articlesPublished // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,newUsers: null == newUsers ? _self.newUsers : newUsers // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,activeReaders: null == activeReaders ? _self.activeReaders : activeReaders // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,reads: null == reads ? _self.reads : reads // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,reposts: null == reposts ? _self.reposts : reposts // ignore: cast_nullable_to_non_nullable
as DashboardValueModel,openReports: freezed == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int?,openTickets: freezed == openTickets ? _self.openTickets : openTickets // ignore: cast_nullable_to_non_nullable
as int?,pendingVerifications: freezed == pendingVerifications ? _self.pendingVerifications : pendingVerifications // ignore: cast_nullable_to_non_nullable
as int?,suspendedNow: null == suspendedNow ? _self.suspendedNow : suspendedNow // ignore: cast_nullable_to_non_nullable
as int,openReportsOver24h: freezed == openReportsOver24h ? _self.openReportsOver24h : openReportsOver24h // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get articlesPublished {
  
  return $DashboardValueModelCopyWith<$Res>(_self.articlesPublished, (value) {
    return _then(_self.copyWith(articlesPublished: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get newUsers {
  
  return $DashboardValueModelCopyWith<$Res>(_self.newUsers, (value) {
    return _then(_self.copyWith(newUsers: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get activeReaders {
  
  return $DashboardValueModelCopyWith<$Res>(_self.activeReaders, (value) {
    return _then(_self.copyWith(activeReaders: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get reads {
  
  return $DashboardValueModelCopyWith<$Res>(_self.reads, (value) {
    return _then(_self.copyWith(reads: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get comments {
  
  return $DashboardValueModelCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get reactions {
  
  return $DashboardValueModelCopyWith<$Res>(_self.reactions, (value) {
    return _then(_self.copyWith(reactions: value));
  });
}/// Create a copy of DashboardCardsModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardValueModelCopyWith<$Res> get reposts {
  
  return $DashboardValueModelCopyWith<$Res>(_self.reposts, (value) {
    return _then(_self.copyWith(reposts: value));
  });
}
}


/// @nodoc
mixin _$DashboardDayModel {

 String get date; int get newUsers; int get activeReaders; int get articlesPublished;
/// Create a copy of DashboardDayModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardDayModelCopyWith<DashboardDayModel> get copyWith => _$DashboardDayModelCopyWithImpl<DashboardDayModel>(this as DashboardDayModel, _$identity);

  /// Serializes this DashboardDayModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardDayModel&&(identical(other.date, date) || other.date == date)&&(identical(other.newUsers, newUsers) || other.newUsers == newUsers)&&(identical(other.activeReaders, activeReaders) || other.activeReaders == activeReaders)&&(identical(other.articlesPublished, articlesPublished) || other.articlesPublished == articlesPublished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,newUsers,activeReaders,articlesPublished);

@override
String toString() {
  return 'DashboardDayModel(date: $date, newUsers: $newUsers, activeReaders: $activeReaders, articlesPublished: $articlesPublished)';
}


}

/// @nodoc
abstract mixin class $DashboardDayModelCopyWith<$Res>  {
  factory $DashboardDayModelCopyWith(DashboardDayModel value, $Res Function(DashboardDayModel) _then) = _$DashboardDayModelCopyWithImpl;
@useResult
$Res call({
 String date, int newUsers, int activeReaders, int articlesPublished
});




}
/// @nodoc
class _$DashboardDayModelCopyWithImpl<$Res>
    implements $DashboardDayModelCopyWith<$Res> {
  _$DashboardDayModelCopyWithImpl(this._self, this._then);

  final DashboardDayModel _self;
  final $Res Function(DashboardDayModel) _then;

/// Create a copy of DashboardDayModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? newUsers = null,Object? activeReaders = null,Object? articlesPublished = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,newUsers: null == newUsers ? _self.newUsers : newUsers // ignore: cast_nullable_to_non_nullable
as int,activeReaders: null == activeReaders ? _self.activeReaders : activeReaders // ignore: cast_nullable_to_non_nullable
as int,articlesPublished: null == articlesPublished ? _self.articlesPublished : articlesPublished // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardDayModel].
extension DashboardDayModelPatterns on DashboardDayModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardDayModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardDayModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardDayModel value)  $default,){
final _that = this;
switch (_that) {
case _DashboardDayModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardDayModel value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardDayModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int newUsers,  int activeReaders,  int articlesPublished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardDayModel() when $default != null:
return $default(_that.date,_that.newUsers,_that.activeReaders,_that.articlesPublished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int newUsers,  int activeReaders,  int articlesPublished)  $default,) {final _that = this;
switch (_that) {
case _DashboardDayModel():
return $default(_that.date,_that.newUsers,_that.activeReaders,_that.articlesPublished);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int newUsers,  int activeReaders,  int articlesPublished)?  $default,) {final _that = this;
switch (_that) {
case _DashboardDayModel() when $default != null:
return $default(_that.date,_that.newUsers,_that.activeReaders,_that.articlesPublished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardDayModel extends DashboardDayModel {
  const _DashboardDayModel({required this.date, this.newUsers = 0, this.activeReaders = 0, this.articlesPublished = 0}): super._();
  factory _DashboardDayModel.fromJson(Map<String, dynamic> json) => _$DashboardDayModelFromJson(json);

@override final  String date;
@override@JsonKey() final  int newUsers;
@override@JsonKey() final  int activeReaders;
@override@JsonKey() final  int articlesPublished;

/// Create a copy of DashboardDayModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardDayModelCopyWith<_DashboardDayModel> get copyWith => __$DashboardDayModelCopyWithImpl<_DashboardDayModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardDayModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardDayModel&&(identical(other.date, date) || other.date == date)&&(identical(other.newUsers, newUsers) || other.newUsers == newUsers)&&(identical(other.activeReaders, activeReaders) || other.activeReaders == activeReaders)&&(identical(other.articlesPublished, articlesPublished) || other.articlesPublished == articlesPublished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,newUsers,activeReaders,articlesPublished);

@override
String toString() {
  return 'DashboardDayModel(date: $date, newUsers: $newUsers, activeReaders: $activeReaders, articlesPublished: $articlesPublished)';
}


}

/// @nodoc
abstract mixin class _$DashboardDayModelCopyWith<$Res> implements $DashboardDayModelCopyWith<$Res> {
  factory _$DashboardDayModelCopyWith(_DashboardDayModel value, $Res Function(_DashboardDayModel) _then) = __$DashboardDayModelCopyWithImpl;
@override @useResult
$Res call({
 String date, int newUsers, int activeReaders, int articlesPublished
});




}
/// @nodoc
class __$DashboardDayModelCopyWithImpl<$Res>
    implements _$DashboardDayModelCopyWith<$Res> {
  __$DashboardDayModelCopyWithImpl(this._self, this._then);

  final _DashboardDayModel _self;
  final $Res Function(_DashboardDayModel) _then;

/// Create a copy of DashboardDayModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? newUsers = null,Object? activeReaders = null,Object? articlesPublished = null,}) {
  return _then(_DashboardDayModel(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,newUsers: null == newUsers ? _self.newUsers : newUsers // ignore: cast_nullable_to_non_nullable
as int,activeReaders: null == activeReaders ? _self.activeReaders : activeReaders // ignore: cast_nullable_to_non_nullable
as int,articlesPublished: null == articlesPublished ? _self.articlesPublished : articlesPublished // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DashboardArticleModel {

 String get id; String get slug; String get title; String get language; AuthorModel? get author; FieldRefModel get field; DateTime get publishedAt; int get reads;
/// Create a copy of DashboardArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardArticleModelCopyWith<DashboardArticleModel> get copyWith => _$DashboardArticleModelCopyWithImpl<DashboardArticleModel>(this as DashboardArticleModel, _$identity);

  /// Serializes this DashboardArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.author, author) || other.author == author)&&(identical(other.field, field) || other.field == field)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reads, reads) || other.reads == reads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language,author,field,publishedAt,reads);

@override
String toString() {
  return 'DashboardArticleModel(id: $id, slug: $slug, title: $title, language: $language, author: $author, field: $field, publishedAt: $publishedAt, reads: $reads)';
}


}

/// @nodoc
abstract mixin class $DashboardArticleModelCopyWith<$Res>  {
  factory $DashboardArticleModelCopyWith(DashboardArticleModel value, $Res Function(DashboardArticleModel) _then) = _$DashboardArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String language, AuthorModel? author, FieldRefModel field, DateTime publishedAt, int reads
});


$AuthorModelCopyWith<$Res>? get author;$FieldRefModelCopyWith<$Res> get field;

}
/// @nodoc
class _$DashboardArticleModelCopyWithImpl<$Res>
    implements $DashboardArticleModelCopyWith<$Res> {
  _$DashboardArticleModelCopyWithImpl(this._self, this._then);

  final DashboardArticleModel _self;
  final $Res Function(DashboardArticleModel) _then;

/// Create a copy of DashboardArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,Object? author = freezed,Object? field = null,Object? publishedAt = null,Object? reads = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reads: null == reads ? _self.reads : reads // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of DashboardArticleModel
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
}/// Create a copy of DashboardArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// Adds pattern-matching-related methods to [DashboardArticleModel].
extension DashboardArticleModelPatterns on DashboardArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _DashboardArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language,  AuthorModel? author,  FieldRefModel field,  DateTime publishedAt,  int reads)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language,_that.author,_that.field,_that.publishedAt,_that.reads);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language,  AuthorModel? author,  FieldRefModel field,  DateTime publishedAt,  int reads)  $default,) {final _that = this;
switch (_that) {
case _DashboardArticleModel():
return $default(_that.id,_that.slug,_that.title,_that.language,_that.author,_that.field,_that.publishedAt,_that.reads);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String language,  AuthorModel? author,  FieldRefModel field,  DateTime publishedAt,  int reads)?  $default,) {final _that = this;
switch (_that) {
case _DashboardArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language,_that.author,_that.field,_that.publishedAt,_that.reads);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardArticleModel extends DashboardArticleModel {
  const _DashboardArticleModel({required this.id, required this.slug, this.title = '', this.language = 'ar-EG', this.author, required this.field, required this.publishedAt, this.reads = 0}): super._();
  factory _DashboardArticleModel.fromJson(Map<String, dynamic> json) => _$DashboardArticleModelFromJson(json);

@override final  String id;
@override final  String slug;
@override@JsonKey() final  String title;
@override@JsonKey() final  String language;
@override final  AuthorModel? author;
@override final  FieldRefModel field;
@override final  DateTime publishedAt;
@override@JsonKey() final  int reads;

/// Create a copy of DashboardArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardArticleModelCopyWith<_DashboardArticleModel> get copyWith => __$DashboardArticleModelCopyWithImpl<_DashboardArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.author, author) || other.author == author)&&(identical(other.field, field) || other.field == field)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.reads, reads) || other.reads == reads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language,author,field,publishedAt,reads);

@override
String toString() {
  return 'DashboardArticleModel(id: $id, slug: $slug, title: $title, language: $language, author: $author, field: $field, publishedAt: $publishedAt, reads: $reads)';
}


}

/// @nodoc
abstract mixin class _$DashboardArticleModelCopyWith<$Res> implements $DashboardArticleModelCopyWith<$Res> {
  factory _$DashboardArticleModelCopyWith(_DashboardArticleModel value, $Res Function(_DashboardArticleModel) _then) = __$DashboardArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String language, AuthorModel? author, FieldRefModel field, DateTime publishedAt, int reads
});


@override $AuthorModelCopyWith<$Res>? get author;@override $FieldRefModelCopyWith<$Res> get field;

}
/// @nodoc
class __$DashboardArticleModelCopyWithImpl<$Res>
    implements _$DashboardArticleModelCopyWith<$Res> {
  __$DashboardArticleModelCopyWithImpl(this._self, this._then);

  final _DashboardArticleModel _self;
  final $Res Function(_DashboardArticleModel) _then;

/// Create a copy of DashboardArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,Object? author = freezed,Object? field = null,Object? publishedAt = null,Object? reads = null,}) {
  return _then(_DashboardArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reads: null == reads ? _self.reads : reads // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of DashboardArticleModel
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
}/// Create a copy of DashboardArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}


/// @nodoc
mixin _$DashboardWriterModel {

 AuthorModel get writer; int get reads; int get articles;
/// Create a copy of DashboardWriterModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardWriterModelCopyWith<DashboardWriterModel> get copyWith => _$DashboardWriterModelCopyWithImpl<DashboardWriterModel>(this as DashboardWriterModel, _$identity);

  /// Serializes this DashboardWriterModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardWriterModel&&(identical(other.writer, writer) || other.writer == writer)&&(identical(other.reads, reads) || other.reads == reads)&&(identical(other.articles, articles) || other.articles == articles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,writer,reads,articles);

@override
String toString() {
  return 'DashboardWriterModel(writer: $writer, reads: $reads, articles: $articles)';
}


}

/// @nodoc
abstract mixin class $DashboardWriterModelCopyWith<$Res>  {
  factory $DashboardWriterModelCopyWith(DashboardWriterModel value, $Res Function(DashboardWriterModel) _then) = _$DashboardWriterModelCopyWithImpl;
@useResult
$Res call({
 AuthorModel writer, int reads, int articles
});


$AuthorModelCopyWith<$Res> get writer;

}
/// @nodoc
class _$DashboardWriterModelCopyWithImpl<$Res>
    implements $DashboardWriterModelCopyWith<$Res> {
  _$DashboardWriterModelCopyWithImpl(this._self, this._then);

  final DashboardWriterModel _self;
  final $Res Function(DashboardWriterModel) _then;

/// Create a copy of DashboardWriterModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? writer = null,Object? reads = null,Object? articles = null,}) {
  return _then(_self.copyWith(
writer: null == writer ? _self.writer : writer // ignore: cast_nullable_to_non_nullable
as AuthorModel,reads: null == reads ? _self.reads : reads // ignore: cast_nullable_to_non_nullable
as int,articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of DashboardWriterModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get writer {
  
  return $AuthorModelCopyWith<$Res>(_self.writer, (value) {
    return _then(_self.copyWith(writer: value));
  });
}
}


/// Adds pattern-matching-related methods to [DashboardWriterModel].
extension DashboardWriterModelPatterns on DashboardWriterModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardWriterModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardWriterModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardWriterModel value)  $default,){
final _that = this;
switch (_that) {
case _DashboardWriterModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardWriterModel value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardWriterModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthorModel writer,  int reads,  int articles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardWriterModel() when $default != null:
return $default(_that.writer,_that.reads,_that.articles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthorModel writer,  int reads,  int articles)  $default,) {final _that = this;
switch (_that) {
case _DashboardWriterModel():
return $default(_that.writer,_that.reads,_that.articles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthorModel writer,  int reads,  int articles)?  $default,) {final _that = this;
switch (_that) {
case _DashboardWriterModel() when $default != null:
return $default(_that.writer,_that.reads,_that.articles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardWriterModel extends DashboardWriterModel {
  const _DashboardWriterModel({required this.writer, this.reads = 0, this.articles = 0}): super._();
  factory _DashboardWriterModel.fromJson(Map<String, dynamic> json) => _$DashboardWriterModelFromJson(json);

@override final  AuthorModel writer;
@override@JsonKey() final  int reads;
@override@JsonKey() final  int articles;

/// Create a copy of DashboardWriterModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardWriterModelCopyWith<_DashboardWriterModel> get copyWith => __$DashboardWriterModelCopyWithImpl<_DashboardWriterModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardWriterModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardWriterModel&&(identical(other.writer, writer) || other.writer == writer)&&(identical(other.reads, reads) || other.reads == reads)&&(identical(other.articles, articles) || other.articles == articles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,writer,reads,articles);

@override
String toString() {
  return 'DashboardWriterModel(writer: $writer, reads: $reads, articles: $articles)';
}


}

/// @nodoc
abstract mixin class _$DashboardWriterModelCopyWith<$Res> implements $DashboardWriterModelCopyWith<$Res> {
  factory _$DashboardWriterModelCopyWith(_DashboardWriterModel value, $Res Function(_DashboardWriterModel) _then) = __$DashboardWriterModelCopyWithImpl;
@override @useResult
$Res call({
 AuthorModel writer, int reads, int articles
});


@override $AuthorModelCopyWith<$Res> get writer;

}
/// @nodoc
class __$DashboardWriterModelCopyWithImpl<$Res>
    implements _$DashboardWriterModelCopyWith<$Res> {
  __$DashboardWriterModelCopyWithImpl(this._self, this._then);

  final _DashboardWriterModel _self;
  final $Res Function(_DashboardWriterModel) _then;

/// Create a copy of DashboardWriterModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? writer = null,Object? reads = null,Object? articles = null,}) {
  return _then(_DashboardWriterModel(
writer: null == writer ? _self.writer : writer // ignore: cast_nullable_to_non_nullable
as AuthorModel,reads: null == reads ? _self.reads : reads // ignore: cast_nullable_to_non_nullable
as int,articles: null == articles ? _self.articles : articles // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of DashboardWriterModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get writer {
  
  return $AuthorModelCopyWith<$Res>(_self.writer, (value) {
    return _then(_self.copyWith(writer: value));
  });
}
}


/// @nodoc
mixin _$MissedSearchModel {

 String get query; String get language; int get count;
/// Create a copy of MissedSearchModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MissedSearchModelCopyWith<MissedSearchModel> get copyWith => _$MissedSearchModelCopyWithImpl<MissedSearchModel>(this as MissedSearchModel, _$identity);

  /// Serializes this MissedSearchModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MissedSearchModel&&(identical(other.query, query) || other.query == query)&&(identical(other.language, language) || other.language == language)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,language,count);

@override
String toString() {
  return 'MissedSearchModel(query: $query, language: $language, count: $count)';
}


}

/// @nodoc
abstract mixin class $MissedSearchModelCopyWith<$Res>  {
  factory $MissedSearchModelCopyWith(MissedSearchModel value, $Res Function(MissedSearchModel) _then) = _$MissedSearchModelCopyWithImpl;
@useResult
$Res call({
 String query, String language, int count
});




}
/// @nodoc
class _$MissedSearchModelCopyWithImpl<$Res>
    implements $MissedSearchModelCopyWith<$Res> {
  _$MissedSearchModelCopyWithImpl(this._self, this._then);

  final MissedSearchModel _self;
  final $Res Function(MissedSearchModel) _then;

/// Create a copy of MissedSearchModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? language = null,Object? count = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MissedSearchModel].
extension MissedSearchModelPatterns on MissedSearchModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MissedSearchModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MissedSearchModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MissedSearchModel value)  $default,){
final _that = this;
switch (_that) {
case _MissedSearchModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MissedSearchModel value)?  $default,){
final _that = this;
switch (_that) {
case _MissedSearchModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  String language,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MissedSearchModel() when $default != null:
return $default(_that.query,_that.language,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  String language,  int count)  $default,) {final _that = this;
switch (_that) {
case _MissedSearchModel():
return $default(_that.query,_that.language,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  String language,  int count)?  $default,) {final _that = this;
switch (_that) {
case _MissedSearchModel() when $default != null:
return $default(_that.query,_that.language,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MissedSearchModel extends MissedSearchModel {
  const _MissedSearchModel({required this.query, this.language = 'en', this.count = 0}): super._();
  factory _MissedSearchModel.fromJson(Map<String, dynamic> json) => _$MissedSearchModelFromJson(json);

@override final  String query;
@override@JsonKey() final  String language;
@override@JsonKey() final  int count;

/// Create a copy of MissedSearchModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MissedSearchModelCopyWith<_MissedSearchModel> get copyWith => __$MissedSearchModelCopyWithImpl<_MissedSearchModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MissedSearchModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MissedSearchModel&&(identical(other.query, query) || other.query == query)&&(identical(other.language, language) || other.language == language)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,language,count);

@override
String toString() {
  return 'MissedSearchModel(query: $query, language: $language, count: $count)';
}


}

/// @nodoc
abstract mixin class _$MissedSearchModelCopyWith<$Res> implements $MissedSearchModelCopyWith<$Res> {
  factory _$MissedSearchModelCopyWith(_MissedSearchModel value, $Res Function(_MissedSearchModel) _then) = __$MissedSearchModelCopyWithImpl;
@override @useResult
$Res call({
 String query, String language, int count
});




}
/// @nodoc
class __$MissedSearchModelCopyWithImpl<$Res>
    implements _$MissedSearchModelCopyWith<$Res> {
  __$MissedSearchModelCopyWithImpl(this._self, this._then);

  final _MissedSearchModel _self;
  final $Res Function(_MissedSearchModel) _then;

/// Create a copy of MissedSearchModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? language = null,Object? count = null,}) {
  return _then(_MissedSearchModel(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StreakRetentionModel {

 int get cohort; int get kept; double? get rate;
/// Create a copy of StreakRetentionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakRetentionModelCopyWith<StreakRetentionModel> get copyWith => _$StreakRetentionModelCopyWithImpl<StreakRetentionModel>(this as StreakRetentionModel, _$identity);

  /// Serializes this StreakRetentionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakRetentionModel&&(identical(other.cohort, cohort) || other.cohort == cohort)&&(identical(other.kept, kept) || other.kept == kept)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cohort,kept,rate);

@override
String toString() {
  return 'StreakRetentionModel(cohort: $cohort, kept: $kept, rate: $rate)';
}


}

/// @nodoc
abstract mixin class $StreakRetentionModelCopyWith<$Res>  {
  factory $StreakRetentionModelCopyWith(StreakRetentionModel value, $Res Function(StreakRetentionModel) _then) = _$StreakRetentionModelCopyWithImpl;
@useResult
$Res call({
 int cohort, int kept, double? rate
});




}
/// @nodoc
class _$StreakRetentionModelCopyWithImpl<$Res>
    implements $StreakRetentionModelCopyWith<$Res> {
  _$StreakRetentionModelCopyWithImpl(this._self, this._then);

  final StreakRetentionModel _self;
  final $Res Function(StreakRetentionModel) _then;

/// Create a copy of StreakRetentionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cohort = null,Object? kept = null,Object? rate = freezed,}) {
  return _then(_self.copyWith(
cohort: null == cohort ? _self.cohort : cohort // ignore: cast_nullable_to_non_nullable
as int,kept: null == kept ? _self.kept : kept // ignore: cast_nullable_to_non_nullable
as int,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [StreakRetentionModel].
extension StreakRetentionModelPatterns on StreakRetentionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakRetentionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakRetentionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakRetentionModel value)  $default,){
final _that = this;
switch (_that) {
case _StreakRetentionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakRetentionModel value)?  $default,){
final _that = this;
switch (_that) {
case _StreakRetentionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cohort,  int kept,  double? rate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakRetentionModel() when $default != null:
return $default(_that.cohort,_that.kept,_that.rate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cohort,  int kept,  double? rate)  $default,) {final _that = this;
switch (_that) {
case _StreakRetentionModel():
return $default(_that.cohort,_that.kept,_that.rate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cohort,  int kept,  double? rate)?  $default,) {final _that = this;
switch (_that) {
case _StreakRetentionModel() when $default != null:
return $default(_that.cohort,_that.kept,_that.rate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakRetentionModel extends StreakRetentionModel {
  const _StreakRetentionModel({this.cohort = 0, this.kept = 0, this.rate}): super._();
  factory _StreakRetentionModel.fromJson(Map<String, dynamic> json) => _$StreakRetentionModelFromJson(json);

@override@JsonKey() final  int cohort;
@override@JsonKey() final  int kept;
@override final  double? rate;

/// Create a copy of StreakRetentionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakRetentionModelCopyWith<_StreakRetentionModel> get copyWith => __$StreakRetentionModelCopyWithImpl<_StreakRetentionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakRetentionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakRetentionModel&&(identical(other.cohort, cohort) || other.cohort == cohort)&&(identical(other.kept, kept) || other.kept == kept)&&(identical(other.rate, rate) || other.rate == rate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cohort,kept,rate);

@override
String toString() {
  return 'StreakRetentionModel(cohort: $cohort, kept: $kept, rate: $rate)';
}


}

/// @nodoc
abstract mixin class _$StreakRetentionModelCopyWith<$Res> implements $StreakRetentionModelCopyWith<$Res> {
  factory _$StreakRetentionModelCopyWith(_StreakRetentionModel value, $Res Function(_StreakRetentionModel) _then) = __$StreakRetentionModelCopyWithImpl;
@override @useResult
$Res call({
 int cohort, int kept, double? rate
});




}
/// @nodoc
class __$StreakRetentionModelCopyWithImpl<$Res>
    implements _$StreakRetentionModelCopyWith<$Res> {
  __$StreakRetentionModelCopyWithImpl(this._self, this._then);

  final _StreakRetentionModel _self;
  final $Res Function(_StreakRetentionModel) _then;

/// Create a copy of StreakRetentionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cohort = null,Object? kept = null,Object? rate = freezed,}) {
  return _then(_StreakRetentionModel(
cohort: null == cohort ? _self.cohort : cohort // ignore: cast_nullable_to_non_nullable
as int,kept: null == kept ? _self.kept : kept // ignore: cast_nullable_to_non_nullable
as int,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$ContentPipelineModel {

 int get folders; int get seeded; int get published; DateTime? get lastSeedRunAt;
/// Create a copy of ContentPipelineModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentPipelineModelCopyWith<ContentPipelineModel> get copyWith => _$ContentPipelineModelCopyWithImpl<ContentPipelineModel>(this as ContentPipelineModel, _$identity);

  /// Serializes this ContentPipelineModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentPipelineModel&&(identical(other.folders, folders) || other.folders == folders)&&(identical(other.seeded, seeded) || other.seeded == seeded)&&(identical(other.published, published) || other.published == published)&&(identical(other.lastSeedRunAt, lastSeedRunAt) || other.lastSeedRunAt == lastSeedRunAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,folders,seeded,published,lastSeedRunAt);

@override
String toString() {
  return 'ContentPipelineModel(folders: $folders, seeded: $seeded, published: $published, lastSeedRunAt: $lastSeedRunAt)';
}


}

/// @nodoc
abstract mixin class $ContentPipelineModelCopyWith<$Res>  {
  factory $ContentPipelineModelCopyWith(ContentPipelineModel value, $Res Function(ContentPipelineModel) _then) = _$ContentPipelineModelCopyWithImpl;
@useResult
$Res call({
 int folders, int seeded, int published, DateTime? lastSeedRunAt
});




}
/// @nodoc
class _$ContentPipelineModelCopyWithImpl<$Res>
    implements $ContentPipelineModelCopyWith<$Res> {
  _$ContentPipelineModelCopyWithImpl(this._self, this._then);

  final ContentPipelineModel _self;
  final $Res Function(ContentPipelineModel) _then;

/// Create a copy of ContentPipelineModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? folders = null,Object? seeded = null,Object? published = null,Object? lastSeedRunAt = freezed,}) {
  return _then(_self.copyWith(
folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as int,seeded: null == seeded ? _self.seeded : seeded // ignore: cast_nullable_to_non_nullable
as int,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as int,lastSeedRunAt: freezed == lastSeedRunAt ? _self.lastSeedRunAt : lastSeedRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentPipelineModel].
extension ContentPipelineModelPatterns on ContentPipelineModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentPipelineModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentPipelineModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentPipelineModel value)  $default,){
final _that = this;
switch (_that) {
case _ContentPipelineModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentPipelineModel value)?  $default,){
final _that = this;
switch (_that) {
case _ContentPipelineModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int folders,  int seeded,  int published,  DateTime? lastSeedRunAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentPipelineModel() when $default != null:
return $default(_that.folders,_that.seeded,_that.published,_that.lastSeedRunAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int folders,  int seeded,  int published,  DateTime? lastSeedRunAt)  $default,) {final _that = this;
switch (_that) {
case _ContentPipelineModel():
return $default(_that.folders,_that.seeded,_that.published,_that.lastSeedRunAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int folders,  int seeded,  int published,  DateTime? lastSeedRunAt)?  $default,) {final _that = this;
switch (_that) {
case _ContentPipelineModel() when $default != null:
return $default(_that.folders,_that.seeded,_that.published,_that.lastSeedRunAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContentPipelineModel extends ContentPipelineModel {
  const _ContentPipelineModel({this.folders = 0, this.seeded = 0, this.published = 0, this.lastSeedRunAt}): super._();
  factory _ContentPipelineModel.fromJson(Map<String, dynamic> json) => _$ContentPipelineModelFromJson(json);

@override@JsonKey() final  int folders;
@override@JsonKey() final  int seeded;
@override@JsonKey() final  int published;
@override final  DateTime? lastSeedRunAt;

/// Create a copy of ContentPipelineModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentPipelineModelCopyWith<_ContentPipelineModel> get copyWith => __$ContentPipelineModelCopyWithImpl<_ContentPipelineModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContentPipelineModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentPipelineModel&&(identical(other.folders, folders) || other.folders == folders)&&(identical(other.seeded, seeded) || other.seeded == seeded)&&(identical(other.published, published) || other.published == published)&&(identical(other.lastSeedRunAt, lastSeedRunAt) || other.lastSeedRunAt == lastSeedRunAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,folders,seeded,published,lastSeedRunAt);

@override
String toString() {
  return 'ContentPipelineModel(folders: $folders, seeded: $seeded, published: $published, lastSeedRunAt: $lastSeedRunAt)';
}


}

/// @nodoc
abstract mixin class _$ContentPipelineModelCopyWith<$Res> implements $ContentPipelineModelCopyWith<$Res> {
  factory _$ContentPipelineModelCopyWith(_ContentPipelineModel value, $Res Function(_ContentPipelineModel) _then) = __$ContentPipelineModelCopyWithImpl;
@override @useResult
$Res call({
 int folders, int seeded, int published, DateTime? lastSeedRunAt
});




}
/// @nodoc
class __$ContentPipelineModelCopyWithImpl<$Res>
    implements _$ContentPipelineModelCopyWith<$Res> {
  __$ContentPipelineModelCopyWithImpl(this._self, this._then);

  final _ContentPipelineModel _self;
  final $Res Function(_ContentPipelineModel) _then;

/// Create a copy of ContentPipelineModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? folders = null,Object? seeded = null,Object? published = null,Object? lastSeedRunAt = freezed,}) {
  return _then(_ContentPipelineModel(
folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as int,seeded: null == seeded ? _self.seeded : seeded // ignore: cast_nullable_to_non_nullable
as int,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as int,lastSeedRunAt: freezed == lastSeedRunAt ? _self.lastSeedRunAt : lastSeedRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AdminDashboardModel {

 String get period; String get timeZone; String get fromDate; String get toDate; DateTime get generatedAt; DashboardCardsModel get cards; List<DashboardDayModel> get charts; List<DashboardArticleModel> get topArticles; List<DashboardWriterModel> get topWriters; List<MissedSearchModel> get missedSearches; StreakRetentionModel get streakRetention; ContentPipelineModel get contentPipeline;
/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminDashboardModelCopyWith<AdminDashboardModel> get copyWith => _$AdminDashboardModelCopyWithImpl<AdminDashboardModel>(this as AdminDashboardModel, _$identity);

  /// Serializes this AdminDashboardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminDashboardModel&&(identical(other.period, period) || other.period == period)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.cards, cards) || other.cards == cards)&&const DeepCollectionEquality().equals(other.charts, charts)&&const DeepCollectionEquality().equals(other.topArticles, topArticles)&&const DeepCollectionEquality().equals(other.topWriters, topWriters)&&const DeepCollectionEquality().equals(other.missedSearches, missedSearches)&&(identical(other.streakRetention, streakRetention) || other.streakRetention == streakRetention)&&(identical(other.contentPipeline, contentPipeline) || other.contentPipeline == contentPipeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,timeZone,fromDate,toDate,generatedAt,cards,const DeepCollectionEquality().hash(charts),const DeepCollectionEquality().hash(topArticles),const DeepCollectionEquality().hash(topWriters),const DeepCollectionEquality().hash(missedSearches),streakRetention,contentPipeline);

@override
String toString() {
  return 'AdminDashboardModel(period: $period, timeZone: $timeZone, fromDate: $fromDate, toDate: $toDate, generatedAt: $generatedAt, cards: $cards, charts: $charts, topArticles: $topArticles, topWriters: $topWriters, missedSearches: $missedSearches, streakRetention: $streakRetention, contentPipeline: $contentPipeline)';
}


}

/// @nodoc
abstract mixin class $AdminDashboardModelCopyWith<$Res>  {
  factory $AdminDashboardModelCopyWith(AdminDashboardModel value, $Res Function(AdminDashboardModel) _then) = _$AdminDashboardModelCopyWithImpl;
@useResult
$Res call({
 String period, String timeZone, String fromDate, String toDate, DateTime generatedAt, DashboardCardsModel cards, List<DashboardDayModel> charts, List<DashboardArticleModel> topArticles, List<DashboardWriterModel> topWriters, List<MissedSearchModel> missedSearches, StreakRetentionModel streakRetention, ContentPipelineModel contentPipeline
});


$DashboardCardsModelCopyWith<$Res> get cards;$StreakRetentionModelCopyWith<$Res> get streakRetention;$ContentPipelineModelCopyWith<$Res> get contentPipeline;

}
/// @nodoc
class _$AdminDashboardModelCopyWithImpl<$Res>
    implements $AdminDashboardModelCopyWith<$Res> {
  _$AdminDashboardModelCopyWithImpl(this._self, this._then);

  final AdminDashboardModel _self;
  final $Res Function(AdminDashboardModel) _then;

/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? timeZone = null,Object? fromDate = null,Object? toDate = null,Object? generatedAt = null,Object? cards = null,Object? charts = null,Object? topArticles = null,Object? topWriters = null,Object? missedSearches = null,Object? streakRetention = null,Object? contentPipeline = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,fromDate: null == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as String,toDate: null == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as DashboardCardsModel,charts: null == charts ? _self.charts : charts // ignore: cast_nullable_to_non_nullable
as List<DashboardDayModel>,topArticles: null == topArticles ? _self.topArticles : topArticles // ignore: cast_nullable_to_non_nullable
as List<DashboardArticleModel>,topWriters: null == topWriters ? _self.topWriters : topWriters // ignore: cast_nullable_to_non_nullable
as List<DashboardWriterModel>,missedSearches: null == missedSearches ? _self.missedSearches : missedSearches // ignore: cast_nullable_to_non_nullable
as List<MissedSearchModel>,streakRetention: null == streakRetention ? _self.streakRetention : streakRetention // ignore: cast_nullable_to_non_nullable
as StreakRetentionModel,contentPipeline: null == contentPipeline ? _self.contentPipeline : contentPipeline // ignore: cast_nullable_to_non_nullable
as ContentPipelineModel,
  ));
}
/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardCardsModelCopyWith<$Res> get cards {
  
  return $DashboardCardsModelCopyWith<$Res>(_self.cards, (value) {
    return _then(_self.copyWith(cards: value));
  });
}/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakRetentionModelCopyWith<$Res> get streakRetention {
  
  return $StreakRetentionModelCopyWith<$Res>(_self.streakRetention, (value) {
    return _then(_self.copyWith(streakRetention: value));
  });
}/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContentPipelineModelCopyWith<$Res> get contentPipeline {
  
  return $ContentPipelineModelCopyWith<$Res>(_self.contentPipeline, (value) {
    return _then(_self.copyWith(contentPipeline: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminDashboardModel].
extension AdminDashboardModelPatterns on AdminDashboardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminDashboardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminDashboardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminDashboardModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminDashboardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminDashboardModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminDashboardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String period,  String timeZone,  String fromDate,  String toDate,  DateTime generatedAt,  DashboardCardsModel cards,  List<DashboardDayModel> charts,  List<DashboardArticleModel> topArticles,  List<DashboardWriterModel> topWriters,  List<MissedSearchModel> missedSearches,  StreakRetentionModel streakRetention,  ContentPipelineModel contentPipeline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminDashboardModel() when $default != null:
return $default(_that.period,_that.timeZone,_that.fromDate,_that.toDate,_that.generatedAt,_that.cards,_that.charts,_that.topArticles,_that.topWriters,_that.missedSearches,_that.streakRetention,_that.contentPipeline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String period,  String timeZone,  String fromDate,  String toDate,  DateTime generatedAt,  DashboardCardsModel cards,  List<DashboardDayModel> charts,  List<DashboardArticleModel> topArticles,  List<DashboardWriterModel> topWriters,  List<MissedSearchModel> missedSearches,  StreakRetentionModel streakRetention,  ContentPipelineModel contentPipeline)  $default,) {final _that = this;
switch (_that) {
case _AdminDashboardModel():
return $default(_that.period,_that.timeZone,_that.fromDate,_that.toDate,_that.generatedAt,_that.cards,_that.charts,_that.topArticles,_that.topWriters,_that.missedSearches,_that.streakRetention,_that.contentPipeline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String period,  String timeZone,  String fromDate,  String toDate,  DateTime generatedAt,  DashboardCardsModel cards,  List<DashboardDayModel> charts,  List<DashboardArticleModel> topArticles,  List<DashboardWriterModel> topWriters,  List<MissedSearchModel> missedSearches,  StreakRetentionModel streakRetention,  ContentPipelineModel contentPipeline)?  $default,) {final _that = this;
switch (_that) {
case _AdminDashboardModel() when $default != null:
return $default(_that.period,_that.timeZone,_that.fromDate,_that.toDate,_that.generatedAt,_that.cards,_that.charts,_that.topArticles,_that.topWriters,_that.missedSearches,_that.streakRetention,_that.contentPipeline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminDashboardModel extends AdminDashboardModel {
  const _AdminDashboardModel({required this.period, this.timeZone = 'Africa/Cairo', this.fromDate = '', this.toDate = '', required this.generatedAt, this.cards = const DashboardCardsModel(), final  List<DashboardDayModel> charts = const <DashboardDayModel>[], final  List<DashboardArticleModel> topArticles = const <DashboardArticleModel>[], final  List<DashboardWriterModel> topWriters = const <DashboardWriterModel>[], final  List<MissedSearchModel> missedSearches = const <MissedSearchModel>[], this.streakRetention = const StreakRetentionModel(), this.contentPipeline = const ContentPipelineModel()}): _charts = charts,_topArticles = topArticles,_topWriters = topWriters,_missedSearches = missedSearches,super._();
  factory _AdminDashboardModel.fromJson(Map<String, dynamic> json) => _$AdminDashboardModelFromJson(json);

@override final  String period;
@override@JsonKey() final  String timeZone;
@override@JsonKey() final  String fromDate;
@override@JsonKey() final  String toDate;
@override final  DateTime generatedAt;
@override@JsonKey() final  DashboardCardsModel cards;
 final  List<DashboardDayModel> _charts;
@override@JsonKey() List<DashboardDayModel> get charts {
  if (_charts is EqualUnmodifiableListView) return _charts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_charts);
}

 final  List<DashboardArticleModel> _topArticles;
@override@JsonKey() List<DashboardArticleModel> get topArticles {
  if (_topArticles is EqualUnmodifiableListView) return _topArticles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topArticles);
}

 final  List<DashboardWriterModel> _topWriters;
@override@JsonKey() List<DashboardWriterModel> get topWriters {
  if (_topWriters is EqualUnmodifiableListView) return _topWriters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topWriters);
}

 final  List<MissedSearchModel> _missedSearches;
@override@JsonKey() List<MissedSearchModel> get missedSearches {
  if (_missedSearches is EqualUnmodifiableListView) return _missedSearches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missedSearches);
}

@override@JsonKey() final  StreakRetentionModel streakRetention;
@override@JsonKey() final  ContentPipelineModel contentPipeline;

/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminDashboardModelCopyWith<_AdminDashboardModel> get copyWith => __$AdminDashboardModelCopyWithImpl<_AdminDashboardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminDashboardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminDashboardModel&&(identical(other.period, period) || other.period == period)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.cards, cards) || other.cards == cards)&&const DeepCollectionEquality().equals(other._charts, _charts)&&const DeepCollectionEquality().equals(other._topArticles, _topArticles)&&const DeepCollectionEquality().equals(other._topWriters, _topWriters)&&const DeepCollectionEquality().equals(other._missedSearches, _missedSearches)&&(identical(other.streakRetention, streakRetention) || other.streakRetention == streakRetention)&&(identical(other.contentPipeline, contentPipeline) || other.contentPipeline == contentPipeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,timeZone,fromDate,toDate,generatedAt,cards,const DeepCollectionEquality().hash(_charts),const DeepCollectionEquality().hash(_topArticles),const DeepCollectionEquality().hash(_topWriters),const DeepCollectionEquality().hash(_missedSearches),streakRetention,contentPipeline);

@override
String toString() {
  return 'AdminDashboardModel(period: $period, timeZone: $timeZone, fromDate: $fromDate, toDate: $toDate, generatedAt: $generatedAt, cards: $cards, charts: $charts, topArticles: $topArticles, topWriters: $topWriters, missedSearches: $missedSearches, streakRetention: $streakRetention, contentPipeline: $contentPipeline)';
}


}

/// @nodoc
abstract mixin class _$AdminDashboardModelCopyWith<$Res> implements $AdminDashboardModelCopyWith<$Res> {
  factory _$AdminDashboardModelCopyWith(_AdminDashboardModel value, $Res Function(_AdminDashboardModel) _then) = __$AdminDashboardModelCopyWithImpl;
@override @useResult
$Res call({
 String period, String timeZone, String fromDate, String toDate, DateTime generatedAt, DashboardCardsModel cards, List<DashboardDayModel> charts, List<DashboardArticleModel> topArticles, List<DashboardWriterModel> topWriters, List<MissedSearchModel> missedSearches, StreakRetentionModel streakRetention, ContentPipelineModel contentPipeline
});


@override $DashboardCardsModelCopyWith<$Res> get cards;@override $StreakRetentionModelCopyWith<$Res> get streakRetention;@override $ContentPipelineModelCopyWith<$Res> get contentPipeline;

}
/// @nodoc
class __$AdminDashboardModelCopyWithImpl<$Res>
    implements _$AdminDashboardModelCopyWith<$Res> {
  __$AdminDashboardModelCopyWithImpl(this._self, this._then);

  final _AdminDashboardModel _self;
  final $Res Function(_AdminDashboardModel) _then;

/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? timeZone = null,Object? fromDate = null,Object? toDate = null,Object? generatedAt = null,Object? cards = null,Object? charts = null,Object? topArticles = null,Object? topWriters = null,Object? missedSearches = null,Object? streakRetention = null,Object? contentPipeline = null,}) {
  return _then(_AdminDashboardModel(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,fromDate: null == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as String,toDate: null == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as DashboardCardsModel,charts: null == charts ? _self._charts : charts // ignore: cast_nullable_to_non_nullable
as List<DashboardDayModel>,topArticles: null == topArticles ? _self._topArticles : topArticles // ignore: cast_nullable_to_non_nullable
as List<DashboardArticleModel>,topWriters: null == topWriters ? _self._topWriters : topWriters // ignore: cast_nullable_to_non_nullable
as List<DashboardWriterModel>,missedSearches: null == missedSearches ? _self._missedSearches : missedSearches // ignore: cast_nullable_to_non_nullable
as List<MissedSearchModel>,streakRetention: null == streakRetention ? _self.streakRetention : streakRetention // ignore: cast_nullable_to_non_nullable
as StreakRetentionModel,contentPipeline: null == contentPipeline ? _self.contentPipeline : contentPipeline // ignore: cast_nullable_to_non_nullable
as ContentPipelineModel,
  ));
}

/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardCardsModelCopyWith<$Res> get cards {
  
  return $DashboardCardsModelCopyWith<$Res>(_self.cards, (value) {
    return _then(_self.copyWith(cards: value));
  });
}/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakRetentionModelCopyWith<$Res> get streakRetention {
  
  return $StreakRetentionModelCopyWith<$Res>(_self.streakRetention, (value) {
    return _then(_self.copyWith(streakRetention: value));
  });
}/// Create a copy of AdminDashboardModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContentPipelineModelCopyWith<$Res> get contentPipeline {
  
  return $ContentPipelineModelCopyWith<$Res>(_self.contentPipeline, (value) {
    return _then(_self.copyWith(contentPipeline: value));
  });
}
}


/// @nodoc
mixin _$AdminUserModel {

 String get id; String get displayName; String get username; String? get avatarUrl; bool get isVerified; bool get isSystemAccount; List<String> get roles; List<String> get signInMethods; String? get phoneMasked; DateTime get joinedAt; DateTime? get lastSeenAt; int get publishedArticles; int get followers; String get status; DateTime? get suspendedUntil; int get openReports;// The page (`GET /admin/users/{id}`).
 String? get headline; String? get bio; List<ProfileLinkModel> get links; String get uiLanguage; String? get signUpMethod; bool get isStaff; AdminUserStatsModel? get stats; AdminUserAccessModel? get access; AdminUserActionsModel? get actions; AdminUserModerationModel? get moderation; AdminUserReportsModel? get reports; AdminVerificationSectionModel? get verification; AdminTicketSectionModel? get tickets; AdminAuditSectionModel? get audit;
/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserModelCopyWith<AdminUserModel> get copyWith => _$AdminUserModelCopyWithImpl<AdminUserModel>(this as AdminUserModel, _$identity);

  /// Serializes this AdminUserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isSystemAccount, isSystemAccount) || other.isSystemAccount == isSystemAccount)&&const DeepCollectionEquality().equals(other.roles, roles)&&const DeepCollectionEquality().equals(other.signInMethods, signInMethods)&&(identical(other.phoneMasked, phoneMasked) || other.phoneMasked == phoneMasked)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.publishedArticles, publishedArticles) || other.publishedArticles == publishedArticles)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.status, status) || other.status == status)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.links, links)&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.signUpMethod, signUpMethod) || other.signUpMethod == signUpMethod)&&(identical(other.isStaff, isStaff) || other.isStaff == isStaff)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.access, access) || other.access == access)&&(identical(other.actions, actions) || other.actions == actions)&&(identical(other.moderation, moderation) || other.moderation == moderation)&&(identical(other.reports, reports) || other.reports == reports)&&(identical(other.verification, verification) || other.verification == verification)&&(identical(other.tickets, tickets) || other.tickets == tickets)&&(identical(other.audit, audit) || other.audit == audit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,username,avatarUrl,isVerified,isSystemAccount,const DeepCollectionEquality().hash(roles),const DeepCollectionEquality().hash(signInMethods),phoneMasked,joinedAt,lastSeenAt,publishedArticles,followers,status,suspendedUntil,openReports,headline,bio,const DeepCollectionEquality().hash(links),uiLanguage,signUpMethod,isStaff,stats,access,actions,moderation,reports,verification,tickets,audit]);

@override
String toString() {
  return 'AdminUserModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, isSystemAccount: $isSystemAccount, roles: $roles, signInMethods: $signInMethods, phoneMasked: $phoneMasked, joinedAt: $joinedAt, lastSeenAt: $lastSeenAt, publishedArticles: $publishedArticles, followers: $followers, status: $status, suspendedUntil: $suspendedUntil, openReports: $openReports, headline: $headline, bio: $bio, links: $links, uiLanguage: $uiLanguage, signUpMethod: $signUpMethod, isStaff: $isStaff, stats: $stats, access: $access, actions: $actions, moderation: $moderation, reports: $reports, verification: $verification, tickets: $tickets, audit: $audit)';
}


}

/// @nodoc
abstract mixin class $AdminUserModelCopyWith<$Res>  {
  factory $AdminUserModelCopyWith(AdminUserModel value, $Res Function(AdminUserModel) _then) = _$AdminUserModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, bool isSystemAccount, List<String> roles, List<String> signInMethods, String? phoneMasked, DateTime joinedAt, DateTime? lastSeenAt, int publishedArticles, int followers, String status, DateTime? suspendedUntil, int openReports, String? headline, String? bio, List<ProfileLinkModel> links, String uiLanguage, String? signUpMethod, bool isStaff, AdminUserStatsModel? stats, AdminUserAccessModel? access, AdminUserActionsModel? actions, AdminUserModerationModel? moderation, AdminUserReportsModel? reports, AdminVerificationSectionModel? verification, AdminTicketSectionModel? tickets, AdminAuditSectionModel? audit
});


$AdminUserStatsModelCopyWith<$Res>? get stats;$AdminUserAccessModelCopyWith<$Res>? get access;$AdminUserActionsModelCopyWith<$Res>? get actions;$AdminUserModerationModelCopyWith<$Res>? get moderation;$AdminUserReportsModelCopyWith<$Res>? get reports;$AdminVerificationSectionModelCopyWith<$Res>? get verification;$AdminTicketSectionModelCopyWith<$Res>? get tickets;$AdminAuditSectionModelCopyWith<$Res>? get audit;

}
/// @nodoc
class _$AdminUserModelCopyWithImpl<$Res>
    implements $AdminUserModelCopyWith<$Res> {
  _$AdminUserModelCopyWithImpl(this._self, this._then);

  final AdminUserModel _self;
  final $Res Function(AdminUserModel) _then;

/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? isSystemAccount = null,Object? roles = null,Object? signInMethods = null,Object? phoneMasked = freezed,Object? joinedAt = null,Object? lastSeenAt = freezed,Object? publishedArticles = null,Object? followers = null,Object? status = null,Object? suspendedUntil = freezed,Object? openReports = null,Object? headline = freezed,Object? bio = freezed,Object? links = null,Object? uiLanguage = null,Object? signUpMethod = freezed,Object? isStaff = null,Object? stats = freezed,Object? access = freezed,Object? actions = freezed,Object? moderation = freezed,Object? reports = freezed,Object? verification = freezed,Object? tickets = freezed,Object? audit = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isSystemAccount: null == isSystemAccount ? _self.isSystemAccount : isSystemAccount // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,signInMethods: null == signInMethods ? _self.signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,phoneMasked: freezed == phoneMasked ? _self.phoneMasked : phoneMasked // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,publishedArticles: null == publishedArticles ? _self.publishedArticles : publishedArticles // ignore: cast_nullable_to_non_nullable
as int,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<ProfileLinkModel>,uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,signUpMethod: freezed == signUpMethod ? _self.signUpMethod : signUpMethod // ignore: cast_nullable_to_non_nullable
as String?,isStaff: null == isStaff ? _self.isStaff : isStaff // ignore: cast_nullable_to_non_nullable
as bool,stats: freezed == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as AdminUserStatsModel?,access: freezed == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as AdminUserAccessModel?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as AdminUserActionsModel?,moderation: freezed == moderation ? _self.moderation : moderation // ignore: cast_nullable_to_non_nullable
as AdminUserModerationModel?,reports: freezed == reports ? _self.reports : reports // ignore: cast_nullable_to_non_nullable
as AdminUserReportsModel?,verification: freezed == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as AdminVerificationSectionModel?,tickets: freezed == tickets ? _self.tickets : tickets // ignore: cast_nullable_to_non_nullable
as AdminTicketSectionModel?,audit: freezed == audit ? _self.audit : audit // ignore: cast_nullable_to_non_nullable
as AdminAuditSectionModel?,
  ));
}
/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserStatsModelCopyWith<$Res>? get stats {
    if (_self.stats == null) {
    return null;
  }

  return $AdminUserStatsModelCopyWith<$Res>(_self.stats!, (value) {
    return _then(_self.copyWith(stats: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserAccessModelCopyWith<$Res>? get access {
    if (_self.access == null) {
    return null;
  }

  return $AdminUserAccessModelCopyWith<$Res>(_self.access!, (value) {
    return _then(_self.copyWith(access: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserActionsModelCopyWith<$Res>? get actions {
    if (_self.actions == null) {
    return null;
  }

  return $AdminUserActionsModelCopyWith<$Res>(_self.actions!, (value) {
    return _then(_self.copyWith(actions: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserModerationModelCopyWith<$Res>? get moderation {
    if (_self.moderation == null) {
    return null;
  }

  return $AdminUserModerationModelCopyWith<$Res>(_self.moderation!, (value) {
    return _then(_self.copyWith(moderation: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserReportsModelCopyWith<$Res>? get reports {
    if (_self.reports == null) {
    return null;
  }

  return $AdminUserReportsModelCopyWith<$Res>(_self.reports!, (value) {
    return _then(_self.copyWith(reports: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminVerificationSectionModelCopyWith<$Res>? get verification {
    if (_self.verification == null) {
    return null;
  }

  return $AdminVerificationSectionModelCopyWith<$Res>(_self.verification!, (value) {
    return _then(_self.copyWith(verification: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminTicketSectionModelCopyWith<$Res>? get tickets {
    if (_self.tickets == null) {
    return null;
  }

  return $AdminTicketSectionModelCopyWith<$Res>(_self.tickets!, (value) {
    return _then(_self.copyWith(tickets: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminAuditSectionModelCopyWith<$Res>? get audit {
    if (_self.audit == null) {
    return null;
  }

  return $AdminAuditSectionModelCopyWith<$Res>(_self.audit!, (value) {
    return _then(_self.copyWith(audit: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminUserModel].
extension AdminUserModelPatterns on AdminUserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  bool isSystemAccount,  List<String> roles,  List<String> signInMethods,  String? phoneMasked,  DateTime joinedAt,  DateTime? lastSeenAt,  int publishedArticles,  int followers,  String status,  DateTime? suspendedUntil,  int openReports,  String? headline,  String? bio,  List<ProfileLinkModel> links,  String uiLanguage,  String? signUpMethod,  bool isStaff,  AdminUserStatsModel? stats,  AdminUserAccessModel? access,  AdminUserActionsModel? actions,  AdminUserModerationModel? moderation,  AdminUserReportsModel? reports,  AdminVerificationSectionModel? verification,  AdminTicketSectionModel? tickets,  AdminAuditSectionModel? audit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.isSystemAccount,_that.roles,_that.signInMethods,_that.phoneMasked,_that.joinedAt,_that.lastSeenAt,_that.publishedArticles,_that.followers,_that.status,_that.suspendedUntil,_that.openReports,_that.headline,_that.bio,_that.links,_that.uiLanguage,_that.signUpMethod,_that.isStaff,_that.stats,_that.access,_that.actions,_that.moderation,_that.reports,_that.verification,_that.tickets,_that.audit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  bool isSystemAccount,  List<String> roles,  List<String> signInMethods,  String? phoneMasked,  DateTime joinedAt,  DateTime? lastSeenAt,  int publishedArticles,  int followers,  String status,  DateTime? suspendedUntil,  int openReports,  String? headline,  String? bio,  List<ProfileLinkModel> links,  String uiLanguage,  String? signUpMethod,  bool isStaff,  AdminUserStatsModel? stats,  AdminUserAccessModel? access,  AdminUserActionsModel? actions,  AdminUserModerationModel? moderation,  AdminUserReportsModel? reports,  AdminVerificationSectionModel? verification,  AdminTicketSectionModel? tickets,  AdminAuditSectionModel? audit)  $default,) {final _that = this;
switch (_that) {
case _AdminUserModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.isSystemAccount,_that.roles,_that.signInMethods,_that.phoneMasked,_that.joinedAt,_that.lastSeenAt,_that.publishedArticles,_that.followers,_that.status,_that.suspendedUntil,_that.openReports,_that.headline,_that.bio,_that.links,_that.uiLanguage,_that.signUpMethod,_that.isStaff,_that.stats,_that.access,_that.actions,_that.moderation,_that.reports,_that.verification,_that.tickets,_that.audit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  bool isSystemAccount,  List<String> roles,  List<String> signInMethods,  String? phoneMasked,  DateTime joinedAt,  DateTime? lastSeenAt,  int publishedArticles,  int followers,  String status,  DateTime? suspendedUntil,  int openReports,  String? headline,  String? bio,  List<ProfileLinkModel> links,  String uiLanguage,  String? signUpMethod,  bool isStaff,  AdminUserStatsModel? stats,  AdminUserAccessModel? access,  AdminUserActionsModel? actions,  AdminUserModerationModel? moderation,  AdminUserReportsModel? reports,  AdminVerificationSectionModel? verification,  AdminTicketSectionModel? tickets,  AdminAuditSectionModel? audit)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.isSystemAccount,_that.roles,_that.signInMethods,_that.phoneMasked,_that.joinedAt,_that.lastSeenAt,_that.publishedArticles,_that.followers,_that.status,_that.suspendedUntil,_that.openReports,_that.headline,_that.bio,_that.links,_that.uiLanguage,_that.signUpMethod,_that.isStaff,_that.stats,_that.access,_that.actions,_that.moderation,_that.reports,_that.verification,_that.tickets,_that.audit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserModel extends AdminUserModel {
  const _AdminUserModel({required this.id, this.displayName = '', this.username = '', this.avatarUrl, this.isVerified = false, this.isSystemAccount = false, final  List<String> roles = const <String>[], final  List<String> signInMethods = const <String>[], this.phoneMasked, required this.joinedAt, this.lastSeenAt, this.publishedArticles = 0, this.followers = 0, this.status = 'active', this.suspendedUntil, this.openReports = 0, this.headline, this.bio, final  List<ProfileLinkModel> links = const <ProfileLinkModel>[], this.uiLanguage = 'ar', this.signUpMethod, this.isStaff = false, this.stats, this.access, this.actions, this.moderation, this.reports, this.verification, this.tickets, this.audit}): _roles = roles,_signInMethods = signInMethods,_links = links,super._();
  factory _AdminUserModel.fromJson(Map<String, dynamic> json) => _$AdminUserModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool isSystemAccount;
 final  List<String> _roles;
@override@JsonKey() List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

 final  List<String> _signInMethods;
@override@JsonKey() List<String> get signInMethods {
  if (_signInMethods is EqualUnmodifiableListView) return _signInMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_signInMethods);
}

@override final  String? phoneMasked;
@override final  DateTime joinedAt;
@override final  DateTime? lastSeenAt;
@override@JsonKey() final  int publishedArticles;
@override@JsonKey() final  int followers;
@override@JsonKey() final  String status;
@override final  DateTime? suspendedUntil;
@override@JsonKey() final  int openReports;
// The page (`GET /admin/users/{id}`).
@override final  String? headline;
@override final  String? bio;
 final  List<ProfileLinkModel> _links;
@override@JsonKey() List<ProfileLinkModel> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

@override@JsonKey() final  String uiLanguage;
@override final  String? signUpMethod;
@override@JsonKey() final  bool isStaff;
@override final  AdminUserStatsModel? stats;
@override final  AdminUserAccessModel? access;
@override final  AdminUserActionsModel? actions;
@override final  AdminUserModerationModel? moderation;
@override final  AdminUserReportsModel? reports;
@override final  AdminVerificationSectionModel? verification;
@override final  AdminTicketSectionModel? tickets;
@override final  AdminAuditSectionModel? audit;

/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserModelCopyWith<_AdminUserModel> get copyWith => __$AdminUserModelCopyWithImpl<_AdminUserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isSystemAccount, isSystemAccount) || other.isSystemAccount == isSystemAccount)&&const DeepCollectionEquality().equals(other._roles, _roles)&&const DeepCollectionEquality().equals(other._signInMethods, _signInMethods)&&(identical(other.phoneMasked, phoneMasked) || other.phoneMasked == phoneMasked)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.publishedArticles, publishedArticles) || other.publishedArticles == publishedArticles)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.status, status) || other.status == status)&&(identical(other.suspendedUntil, suspendedUntil) || other.suspendedUntil == suspendedUntil)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._links, _links)&&(identical(other.uiLanguage, uiLanguage) || other.uiLanguage == uiLanguage)&&(identical(other.signUpMethod, signUpMethod) || other.signUpMethod == signUpMethod)&&(identical(other.isStaff, isStaff) || other.isStaff == isStaff)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.access, access) || other.access == access)&&(identical(other.actions, actions) || other.actions == actions)&&(identical(other.moderation, moderation) || other.moderation == moderation)&&(identical(other.reports, reports) || other.reports == reports)&&(identical(other.verification, verification) || other.verification == verification)&&(identical(other.tickets, tickets) || other.tickets == tickets)&&(identical(other.audit, audit) || other.audit == audit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,username,avatarUrl,isVerified,isSystemAccount,const DeepCollectionEquality().hash(_roles),const DeepCollectionEquality().hash(_signInMethods),phoneMasked,joinedAt,lastSeenAt,publishedArticles,followers,status,suspendedUntil,openReports,headline,bio,const DeepCollectionEquality().hash(_links),uiLanguage,signUpMethod,isStaff,stats,access,actions,moderation,reports,verification,tickets,audit]);

@override
String toString() {
  return 'AdminUserModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, isSystemAccount: $isSystemAccount, roles: $roles, signInMethods: $signInMethods, phoneMasked: $phoneMasked, joinedAt: $joinedAt, lastSeenAt: $lastSeenAt, publishedArticles: $publishedArticles, followers: $followers, status: $status, suspendedUntil: $suspendedUntil, openReports: $openReports, headline: $headline, bio: $bio, links: $links, uiLanguage: $uiLanguage, signUpMethod: $signUpMethod, isStaff: $isStaff, stats: $stats, access: $access, actions: $actions, moderation: $moderation, reports: $reports, verification: $verification, tickets: $tickets, audit: $audit)';
}


}

/// @nodoc
abstract mixin class _$AdminUserModelCopyWith<$Res> implements $AdminUserModelCopyWith<$Res> {
  factory _$AdminUserModelCopyWith(_AdminUserModel value, $Res Function(_AdminUserModel) _then) = __$AdminUserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, bool isSystemAccount, List<String> roles, List<String> signInMethods, String? phoneMasked, DateTime joinedAt, DateTime? lastSeenAt, int publishedArticles, int followers, String status, DateTime? suspendedUntil, int openReports, String? headline, String? bio, List<ProfileLinkModel> links, String uiLanguage, String? signUpMethod, bool isStaff, AdminUserStatsModel? stats, AdminUserAccessModel? access, AdminUserActionsModel? actions, AdminUserModerationModel? moderation, AdminUserReportsModel? reports, AdminVerificationSectionModel? verification, AdminTicketSectionModel? tickets, AdminAuditSectionModel? audit
});


@override $AdminUserStatsModelCopyWith<$Res>? get stats;@override $AdminUserAccessModelCopyWith<$Res>? get access;@override $AdminUserActionsModelCopyWith<$Res>? get actions;@override $AdminUserModerationModelCopyWith<$Res>? get moderation;@override $AdminUserReportsModelCopyWith<$Res>? get reports;@override $AdminVerificationSectionModelCopyWith<$Res>? get verification;@override $AdminTicketSectionModelCopyWith<$Res>? get tickets;@override $AdminAuditSectionModelCopyWith<$Res>? get audit;

}
/// @nodoc
class __$AdminUserModelCopyWithImpl<$Res>
    implements _$AdminUserModelCopyWith<$Res> {
  __$AdminUserModelCopyWithImpl(this._self, this._then);

  final _AdminUserModel _self;
  final $Res Function(_AdminUserModel) _then;

/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? isSystemAccount = null,Object? roles = null,Object? signInMethods = null,Object? phoneMasked = freezed,Object? joinedAt = null,Object? lastSeenAt = freezed,Object? publishedArticles = null,Object? followers = null,Object? status = null,Object? suspendedUntil = freezed,Object? openReports = null,Object? headline = freezed,Object? bio = freezed,Object? links = null,Object? uiLanguage = null,Object? signUpMethod = freezed,Object? isStaff = null,Object? stats = freezed,Object? access = freezed,Object? actions = freezed,Object? moderation = freezed,Object? reports = freezed,Object? verification = freezed,Object? tickets = freezed,Object? audit = freezed,}) {
  return _then(_AdminUserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isSystemAccount: null == isSystemAccount ? _self.isSystemAccount : isSystemAccount // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,signInMethods: null == signInMethods ? _self._signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,phoneMasked: freezed == phoneMasked ? _self.phoneMasked : phoneMasked // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,publishedArticles: null == publishedArticles ? _self.publishedArticles : publishedArticles // ignore: cast_nullable_to_non_nullable
as int,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,suspendedUntil: freezed == suspendedUntil ? _self.suspendedUntil : suspendedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<ProfileLinkModel>,uiLanguage: null == uiLanguage ? _self.uiLanguage : uiLanguage // ignore: cast_nullable_to_non_nullable
as String,signUpMethod: freezed == signUpMethod ? _self.signUpMethod : signUpMethod // ignore: cast_nullable_to_non_nullable
as String?,isStaff: null == isStaff ? _self.isStaff : isStaff // ignore: cast_nullable_to_non_nullable
as bool,stats: freezed == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as AdminUserStatsModel?,access: freezed == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as AdminUserAccessModel?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as AdminUserActionsModel?,moderation: freezed == moderation ? _self.moderation : moderation // ignore: cast_nullable_to_non_nullable
as AdminUserModerationModel?,reports: freezed == reports ? _self.reports : reports // ignore: cast_nullable_to_non_nullable
as AdminUserReportsModel?,verification: freezed == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as AdminVerificationSectionModel?,tickets: freezed == tickets ? _self.tickets : tickets // ignore: cast_nullable_to_non_nullable
as AdminTicketSectionModel?,audit: freezed == audit ? _self.audit : audit // ignore: cast_nullable_to_non_nullable
as AdminAuditSectionModel?,
  ));
}

/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserStatsModelCopyWith<$Res>? get stats {
    if (_self.stats == null) {
    return null;
  }

  return $AdminUserStatsModelCopyWith<$Res>(_self.stats!, (value) {
    return _then(_self.copyWith(stats: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserAccessModelCopyWith<$Res>? get access {
    if (_self.access == null) {
    return null;
  }

  return $AdminUserAccessModelCopyWith<$Res>(_self.access!, (value) {
    return _then(_self.copyWith(access: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserActionsModelCopyWith<$Res>? get actions {
    if (_self.actions == null) {
    return null;
  }

  return $AdminUserActionsModelCopyWith<$Res>(_self.actions!, (value) {
    return _then(_self.copyWith(actions: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserModerationModelCopyWith<$Res>? get moderation {
    if (_self.moderation == null) {
    return null;
  }

  return $AdminUserModerationModelCopyWith<$Res>(_self.moderation!, (value) {
    return _then(_self.copyWith(moderation: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserReportsModelCopyWith<$Res>? get reports {
    if (_self.reports == null) {
    return null;
  }

  return $AdminUserReportsModelCopyWith<$Res>(_self.reports!, (value) {
    return _then(_self.copyWith(reports: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminVerificationSectionModelCopyWith<$Res>? get verification {
    if (_self.verification == null) {
    return null;
  }

  return $AdminVerificationSectionModelCopyWith<$Res>(_self.verification!, (value) {
    return _then(_self.copyWith(verification: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminTicketSectionModelCopyWith<$Res>? get tickets {
    if (_self.tickets == null) {
    return null;
  }

  return $AdminTicketSectionModelCopyWith<$Res>(_self.tickets!, (value) {
    return _then(_self.copyWith(tickets: value));
  });
}/// Create a copy of AdminUserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminAuditSectionModelCopyWith<$Res>? get audit {
    if (_self.audit == null) {
    return null;
  }

  return $AdminAuditSectionModelCopyWith<$Res>(_self.audit!, (value) {
    return _then(_self.copyWith(audit: value));
  });
}
}


/// @nodoc
mixin _$AdminUserStatsModel {

 int get drafts; int get comments; int get following; int get totalReads; int get articlesRead; int get currentStreak; int get longestStreak;
/// Create a copy of AdminUserStatsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserStatsModelCopyWith<AdminUserStatsModel> get copyWith => _$AdminUserStatsModelCopyWithImpl<AdminUserStatsModel>(this as AdminUserStatsModel, _$identity);

  /// Serializes this AdminUserStatsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserStatsModel&&(identical(other.drafts, drafts) || other.drafts == drafts)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.following, following) || other.following == following)&&(identical(other.totalReads, totalReads) || other.totalReads == totalReads)&&(identical(other.articlesRead, articlesRead) || other.articlesRead == articlesRead)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.longestStreak, longestStreak) || other.longestStreak == longestStreak));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,drafts,comments,following,totalReads,articlesRead,currentStreak,longestStreak);

@override
String toString() {
  return 'AdminUserStatsModel(drafts: $drafts, comments: $comments, following: $following, totalReads: $totalReads, articlesRead: $articlesRead, currentStreak: $currentStreak, longestStreak: $longestStreak)';
}


}

/// @nodoc
abstract mixin class $AdminUserStatsModelCopyWith<$Res>  {
  factory $AdminUserStatsModelCopyWith(AdminUserStatsModel value, $Res Function(AdminUserStatsModel) _then) = _$AdminUserStatsModelCopyWithImpl;
@useResult
$Res call({
 int drafts, int comments, int following, int totalReads, int articlesRead, int currentStreak, int longestStreak
});




}
/// @nodoc
class _$AdminUserStatsModelCopyWithImpl<$Res>
    implements $AdminUserStatsModelCopyWith<$Res> {
  _$AdminUserStatsModelCopyWithImpl(this._self, this._then);

  final AdminUserStatsModel _self;
  final $Res Function(AdminUserStatsModel) _then;

/// Create a copy of AdminUserStatsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? drafts = null,Object? comments = null,Object? following = null,Object? totalReads = null,Object? articlesRead = null,Object? currentStreak = null,Object? longestStreak = null,}) {
  return _then(_self.copyWith(
drafts: null == drafts ? _self.drafts : drafts // ignore: cast_nullable_to_non_nullable
as int,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,totalReads: null == totalReads ? _self.totalReads : totalReads // ignore: cast_nullable_to_non_nullable
as int,articlesRead: null == articlesRead ? _self.articlesRead : articlesRead // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,longestStreak: null == longestStreak ? _self.longestStreak : longestStreak // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserStatsModel].
extension AdminUserStatsModelPatterns on AdminUserStatsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserStatsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserStatsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserStatsModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserStatsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserStatsModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserStatsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int drafts,  int comments,  int following,  int totalReads,  int articlesRead,  int currentStreak,  int longestStreak)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserStatsModel() when $default != null:
return $default(_that.drafts,_that.comments,_that.following,_that.totalReads,_that.articlesRead,_that.currentStreak,_that.longestStreak);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int drafts,  int comments,  int following,  int totalReads,  int articlesRead,  int currentStreak,  int longestStreak)  $default,) {final _that = this;
switch (_that) {
case _AdminUserStatsModel():
return $default(_that.drafts,_that.comments,_that.following,_that.totalReads,_that.articlesRead,_that.currentStreak,_that.longestStreak);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int drafts,  int comments,  int following,  int totalReads,  int articlesRead,  int currentStreak,  int longestStreak)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserStatsModel() when $default != null:
return $default(_that.drafts,_that.comments,_that.following,_that.totalReads,_that.articlesRead,_that.currentStreak,_that.longestStreak);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserStatsModel extends AdminUserStatsModel {
  const _AdminUserStatsModel({this.drafts = 0, this.comments = 0, this.following = 0, this.totalReads = 0, this.articlesRead = 0, this.currentStreak = 0, this.longestStreak = 0}): super._();
  factory _AdminUserStatsModel.fromJson(Map<String, dynamic> json) => _$AdminUserStatsModelFromJson(json);

@override@JsonKey() final  int drafts;
@override@JsonKey() final  int comments;
@override@JsonKey() final  int following;
@override@JsonKey() final  int totalReads;
@override@JsonKey() final  int articlesRead;
@override@JsonKey() final  int currentStreak;
@override@JsonKey() final  int longestStreak;

/// Create a copy of AdminUserStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserStatsModelCopyWith<_AdminUserStatsModel> get copyWith => __$AdminUserStatsModelCopyWithImpl<_AdminUserStatsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserStatsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserStatsModel&&(identical(other.drafts, drafts) || other.drafts == drafts)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.following, following) || other.following == following)&&(identical(other.totalReads, totalReads) || other.totalReads == totalReads)&&(identical(other.articlesRead, articlesRead) || other.articlesRead == articlesRead)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.longestStreak, longestStreak) || other.longestStreak == longestStreak));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,drafts,comments,following,totalReads,articlesRead,currentStreak,longestStreak);

@override
String toString() {
  return 'AdminUserStatsModel(drafts: $drafts, comments: $comments, following: $following, totalReads: $totalReads, articlesRead: $articlesRead, currentStreak: $currentStreak, longestStreak: $longestStreak)';
}


}

/// @nodoc
abstract mixin class _$AdminUserStatsModelCopyWith<$Res> implements $AdminUserStatsModelCopyWith<$Res> {
  factory _$AdminUserStatsModelCopyWith(_AdminUserStatsModel value, $Res Function(_AdminUserStatsModel) _then) = __$AdminUserStatsModelCopyWithImpl;
@override @useResult
$Res call({
 int drafts, int comments, int following, int totalReads, int articlesRead, int currentStreak, int longestStreak
});




}
/// @nodoc
class __$AdminUserStatsModelCopyWithImpl<$Res>
    implements _$AdminUserStatsModelCopyWith<$Res> {
  __$AdminUserStatsModelCopyWithImpl(this._self, this._then);

  final _AdminUserStatsModel _self;
  final $Res Function(_AdminUserStatsModel) _then;

/// Create a copy of AdminUserStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drafts = null,Object? comments = null,Object? following = null,Object? totalReads = null,Object? articlesRead = null,Object? currentStreak = null,Object? longestStreak = null,}) {
  return _then(_AdminUserStatsModel(
drafts: null == drafts ? _self.drafts : drafts // ignore: cast_nullable_to_non_nullable
as int,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,totalReads: null == totalReads ? _self.totalReads : totalReads // ignore: cast_nullable_to_non_nullable
as int,articlesRead: null == articlesRead ? _self.articlesRead : articlesRead // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,longestStreak: null == longestStreak ? _self.longestStreak : longestStreak // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminUserAccessModel {

 int get activeSessions; bool get hasRecoveryPin; bool get recoveryDisabled; bool get mustChangePassword; bool get mustSetRecoveryPin; DateTime? get lockedOutUntil;
/// Create a copy of AdminUserAccessModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserAccessModelCopyWith<AdminUserAccessModel> get copyWith => _$AdminUserAccessModelCopyWithImpl<AdminUserAccessModel>(this as AdminUserAccessModel, _$identity);

  /// Serializes this AdminUserAccessModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserAccessModel&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions)&&(identical(other.hasRecoveryPin, hasRecoveryPin) || other.hasRecoveryPin == hasRecoveryPin)&&(identical(other.recoveryDisabled, recoveryDisabled) || other.recoveryDisabled == recoveryDisabled)&&(identical(other.mustChangePassword, mustChangePassword) || other.mustChangePassword == mustChangePassword)&&(identical(other.mustSetRecoveryPin, mustSetRecoveryPin) || other.mustSetRecoveryPin == mustSetRecoveryPin)&&(identical(other.lockedOutUntil, lockedOutUntil) || other.lockedOutUntil == lockedOutUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeSessions,hasRecoveryPin,recoveryDisabled,mustChangePassword,mustSetRecoveryPin,lockedOutUntil);

@override
String toString() {
  return 'AdminUserAccessModel(activeSessions: $activeSessions, hasRecoveryPin: $hasRecoveryPin, recoveryDisabled: $recoveryDisabled, mustChangePassword: $mustChangePassword, mustSetRecoveryPin: $mustSetRecoveryPin, lockedOutUntil: $lockedOutUntil)';
}


}

/// @nodoc
abstract mixin class $AdminUserAccessModelCopyWith<$Res>  {
  factory $AdminUserAccessModelCopyWith(AdminUserAccessModel value, $Res Function(AdminUserAccessModel) _then) = _$AdminUserAccessModelCopyWithImpl;
@useResult
$Res call({
 int activeSessions, bool hasRecoveryPin, bool recoveryDisabled, bool mustChangePassword, bool mustSetRecoveryPin, DateTime? lockedOutUntil
});




}
/// @nodoc
class _$AdminUserAccessModelCopyWithImpl<$Res>
    implements $AdminUserAccessModelCopyWith<$Res> {
  _$AdminUserAccessModelCopyWithImpl(this._self, this._then);

  final AdminUserAccessModel _self;
  final $Res Function(AdminUserAccessModel) _then;

/// Create a copy of AdminUserAccessModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeSessions = null,Object? hasRecoveryPin = null,Object? recoveryDisabled = null,Object? mustChangePassword = null,Object? mustSetRecoveryPin = null,Object? lockedOutUntil = freezed,}) {
  return _then(_self.copyWith(
activeSessions: null == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int,hasRecoveryPin: null == hasRecoveryPin ? _self.hasRecoveryPin : hasRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,recoveryDisabled: null == recoveryDisabled ? _self.recoveryDisabled : recoveryDisabled // ignore: cast_nullable_to_non_nullable
as bool,mustChangePassword: null == mustChangePassword ? _self.mustChangePassword : mustChangePassword // ignore: cast_nullable_to_non_nullable
as bool,mustSetRecoveryPin: null == mustSetRecoveryPin ? _self.mustSetRecoveryPin : mustSetRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,lockedOutUntil: freezed == lockedOutUntil ? _self.lockedOutUntil : lockedOutUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserAccessModel].
extension AdminUserAccessModelPatterns on AdminUserAccessModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserAccessModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserAccessModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserAccessModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserAccessModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserAccessModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserAccessModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int activeSessions,  bool hasRecoveryPin,  bool recoveryDisabled,  bool mustChangePassword,  bool mustSetRecoveryPin,  DateTime? lockedOutUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserAccessModel() when $default != null:
return $default(_that.activeSessions,_that.hasRecoveryPin,_that.recoveryDisabled,_that.mustChangePassword,_that.mustSetRecoveryPin,_that.lockedOutUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int activeSessions,  bool hasRecoveryPin,  bool recoveryDisabled,  bool mustChangePassword,  bool mustSetRecoveryPin,  DateTime? lockedOutUntil)  $default,) {final _that = this;
switch (_that) {
case _AdminUserAccessModel():
return $default(_that.activeSessions,_that.hasRecoveryPin,_that.recoveryDisabled,_that.mustChangePassword,_that.mustSetRecoveryPin,_that.lockedOutUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int activeSessions,  bool hasRecoveryPin,  bool recoveryDisabled,  bool mustChangePassword,  bool mustSetRecoveryPin,  DateTime? lockedOutUntil)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserAccessModel() when $default != null:
return $default(_that.activeSessions,_that.hasRecoveryPin,_that.recoveryDisabled,_that.mustChangePassword,_that.mustSetRecoveryPin,_that.lockedOutUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserAccessModel extends AdminUserAccessModel {
  const _AdminUserAccessModel({this.activeSessions = 0, this.hasRecoveryPin = false, this.recoveryDisabled = false, this.mustChangePassword = false, this.mustSetRecoveryPin = false, this.lockedOutUntil}): super._();
  factory _AdminUserAccessModel.fromJson(Map<String, dynamic> json) => _$AdminUserAccessModelFromJson(json);

@override@JsonKey() final  int activeSessions;
@override@JsonKey() final  bool hasRecoveryPin;
@override@JsonKey() final  bool recoveryDisabled;
@override@JsonKey() final  bool mustChangePassword;
@override@JsonKey() final  bool mustSetRecoveryPin;
@override final  DateTime? lockedOutUntil;

/// Create a copy of AdminUserAccessModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserAccessModelCopyWith<_AdminUserAccessModel> get copyWith => __$AdminUserAccessModelCopyWithImpl<_AdminUserAccessModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserAccessModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserAccessModel&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions)&&(identical(other.hasRecoveryPin, hasRecoveryPin) || other.hasRecoveryPin == hasRecoveryPin)&&(identical(other.recoveryDisabled, recoveryDisabled) || other.recoveryDisabled == recoveryDisabled)&&(identical(other.mustChangePassword, mustChangePassword) || other.mustChangePassword == mustChangePassword)&&(identical(other.mustSetRecoveryPin, mustSetRecoveryPin) || other.mustSetRecoveryPin == mustSetRecoveryPin)&&(identical(other.lockedOutUntil, lockedOutUntil) || other.lockedOutUntil == lockedOutUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeSessions,hasRecoveryPin,recoveryDisabled,mustChangePassword,mustSetRecoveryPin,lockedOutUntil);

@override
String toString() {
  return 'AdminUserAccessModel(activeSessions: $activeSessions, hasRecoveryPin: $hasRecoveryPin, recoveryDisabled: $recoveryDisabled, mustChangePassword: $mustChangePassword, mustSetRecoveryPin: $mustSetRecoveryPin, lockedOutUntil: $lockedOutUntil)';
}


}

/// @nodoc
abstract mixin class _$AdminUserAccessModelCopyWith<$Res> implements $AdminUserAccessModelCopyWith<$Res> {
  factory _$AdminUserAccessModelCopyWith(_AdminUserAccessModel value, $Res Function(_AdminUserAccessModel) _then) = __$AdminUserAccessModelCopyWithImpl;
@override @useResult
$Res call({
 int activeSessions, bool hasRecoveryPin, bool recoveryDisabled, bool mustChangePassword, bool mustSetRecoveryPin, DateTime? lockedOutUntil
});




}
/// @nodoc
class __$AdminUserAccessModelCopyWithImpl<$Res>
    implements _$AdminUserAccessModelCopyWith<$Res> {
  __$AdminUserAccessModelCopyWithImpl(this._self, this._then);

  final _AdminUserAccessModel _self;
  final $Res Function(_AdminUserAccessModel) _then;

/// Create a copy of AdminUserAccessModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeSessions = null,Object? hasRecoveryPin = null,Object? recoveryDisabled = null,Object? mustChangePassword = null,Object? mustSetRecoveryPin = null,Object? lockedOutUntil = freezed,}) {
  return _then(_AdminUserAccessModel(
activeSessions: null == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int,hasRecoveryPin: null == hasRecoveryPin ? _self.hasRecoveryPin : hasRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,recoveryDisabled: null == recoveryDisabled ? _self.recoveryDisabled : recoveryDisabled // ignore: cast_nullable_to_non_nullable
as bool,mustChangePassword: null == mustChangePassword ? _self.mustChangePassword : mustChangePassword // ignore: cast_nullable_to_non_nullable
as bool,mustSetRecoveryPin: null == mustSetRecoveryPin ? _self.mustSetRecoveryPin : mustSetRecoveryPin // ignore: cast_nullable_to_non_nullable
as bool,lockedOutUntil: freezed == lockedOutUntil ? _self.lockedOutUntil : lockedOutUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AdminUserActionsModel {

 bool get canSuspend; bool get canWarn; bool get canLogoutAll; bool get canResetPassword; bool get canRemoveBadge; bool get canClearProfile; bool get canRestoreContent; bool get canRevealPhone;
/// Create a copy of AdminUserActionsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserActionsModelCopyWith<AdminUserActionsModel> get copyWith => _$AdminUserActionsModelCopyWithImpl<AdminUserActionsModel>(this as AdminUserActionsModel, _$identity);

  /// Serializes this AdminUserActionsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserActionsModel&&(identical(other.canSuspend, canSuspend) || other.canSuspend == canSuspend)&&(identical(other.canWarn, canWarn) || other.canWarn == canWarn)&&(identical(other.canLogoutAll, canLogoutAll) || other.canLogoutAll == canLogoutAll)&&(identical(other.canResetPassword, canResetPassword) || other.canResetPassword == canResetPassword)&&(identical(other.canRemoveBadge, canRemoveBadge) || other.canRemoveBadge == canRemoveBadge)&&(identical(other.canClearProfile, canClearProfile) || other.canClearProfile == canClearProfile)&&(identical(other.canRestoreContent, canRestoreContent) || other.canRestoreContent == canRestoreContent)&&(identical(other.canRevealPhone, canRevealPhone) || other.canRevealPhone == canRevealPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canSuspend,canWarn,canLogoutAll,canResetPassword,canRemoveBadge,canClearProfile,canRestoreContent,canRevealPhone);

@override
String toString() {
  return 'AdminUserActionsModel(canSuspend: $canSuspend, canWarn: $canWarn, canLogoutAll: $canLogoutAll, canResetPassword: $canResetPassword, canRemoveBadge: $canRemoveBadge, canClearProfile: $canClearProfile, canRestoreContent: $canRestoreContent, canRevealPhone: $canRevealPhone)';
}


}

/// @nodoc
abstract mixin class $AdminUserActionsModelCopyWith<$Res>  {
  factory $AdminUserActionsModelCopyWith(AdminUserActionsModel value, $Res Function(AdminUserActionsModel) _then) = _$AdminUserActionsModelCopyWithImpl;
@useResult
$Res call({
 bool canSuspend, bool canWarn, bool canLogoutAll, bool canResetPassword, bool canRemoveBadge, bool canClearProfile, bool canRestoreContent, bool canRevealPhone
});




}
/// @nodoc
class _$AdminUserActionsModelCopyWithImpl<$Res>
    implements $AdminUserActionsModelCopyWith<$Res> {
  _$AdminUserActionsModelCopyWithImpl(this._self, this._then);

  final AdminUserActionsModel _self;
  final $Res Function(AdminUserActionsModel) _then;

/// Create a copy of AdminUserActionsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canSuspend = null,Object? canWarn = null,Object? canLogoutAll = null,Object? canResetPassword = null,Object? canRemoveBadge = null,Object? canClearProfile = null,Object? canRestoreContent = null,Object? canRevealPhone = null,}) {
  return _then(_self.copyWith(
canSuspend: null == canSuspend ? _self.canSuspend : canSuspend // ignore: cast_nullable_to_non_nullable
as bool,canWarn: null == canWarn ? _self.canWarn : canWarn // ignore: cast_nullable_to_non_nullable
as bool,canLogoutAll: null == canLogoutAll ? _self.canLogoutAll : canLogoutAll // ignore: cast_nullable_to_non_nullable
as bool,canResetPassword: null == canResetPassword ? _self.canResetPassword : canResetPassword // ignore: cast_nullable_to_non_nullable
as bool,canRemoveBadge: null == canRemoveBadge ? _self.canRemoveBadge : canRemoveBadge // ignore: cast_nullable_to_non_nullable
as bool,canClearProfile: null == canClearProfile ? _self.canClearProfile : canClearProfile // ignore: cast_nullable_to_non_nullable
as bool,canRestoreContent: null == canRestoreContent ? _self.canRestoreContent : canRestoreContent // ignore: cast_nullable_to_non_nullable
as bool,canRevealPhone: null == canRevealPhone ? _self.canRevealPhone : canRevealPhone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserActionsModel].
extension AdminUserActionsModelPatterns on AdminUserActionsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserActionsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserActionsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserActionsModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserActionsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserActionsModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserActionsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool canSuspend,  bool canWarn,  bool canLogoutAll,  bool canResetPassword,  bool canRemoveBadge,  bool canClearProfile,  bool canRestoreContent,  bool canRevealPhone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserActionsModel() when $default != null:
return $default(_that.canSuspend,_that.canWarn,_that.canLogoutAll,_that.canResetPassword,_that.canRemoveBadge,_that.canClearProfile,_that.canRestoreContent,_that.canRevealPhone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool canSuspend,  bool canWarn,  bool canLogoutAll,  bool canResetPassword,  bool canRemoveBadge,  bool canClearProfile,  bool canRestoreContent,  bool canRevealPhone)  $default,) {final _that = this;
switch (_that) {
case _AdminUserActionsModel():
return $default(_that.canSuspend,_that.canWarn,_that.canLogoutAll,_that.canResetPassword,_that.canRemoveBadge,_that.canClearProfile,_that.canRestoreContent,_that.canRevealPhone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool canSuspend,  bool canWarn,  bool canLogoutAll,  bool canResetPassword,  bool canRemoveBadge,  bool canClearProfile,  bool canRestoreContent,  bool canRevealPhone)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserActionsModel() when $default != null:
return $default(_that.canSuspend,_that.canWarn,_that.canLogoutAll,_that.canResetPassword,_that.canRemoveBadge,_that.canClearProfile,_that.canRestoreContent,_that.canRevealPhone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserActionsModel extends AdminUserActionsModel {
  const _AdminUserActionsModel({this.canSuspend = false, this.canWarn = false, this.canLogoutAll = false, this.canResetPassword = false, this.canRemoveBadge = false, this.canClearProfile = false, this.canRestoreContent = false, this.canRevealPhone = false}): super._();
  factory _AdminUserActionsModel.fromJson(Map<String, dynamic> json) => _$AdminUserActionsModelFromJson(json);

@override@JsonKey() final  bool canSuspend;
@override@JsonKey() final  bool canWarn;
@override@JsonKey() final  bool canLogoutAll;
@override@JsonKey() final  bool canResetPassword;
@override@JsonKey() final  bool canRemoveBadge;
@override@JsonKey() final  bool canClearProfile;
@override@JsonKey() final  bool canRestoreContent;
@override@JsonKey() final  bool canRevealPhone;

/// Create a copy of AdminUserActionsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserActionsModelCopyWith<_AdminUserActionsModel> get copyWith => __$AdminUserActionsModelCopyWithImpl<_AdminUserActionsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserActionsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserActionsModel&&(identical(other.canSuspend, canSuspend) || other.canSuspend == canSuspend)&&(identical(other.canWarn, canWarn) || other.canWarn == canWarn)&&(identical(other.canLogoutAll, canLogoutAll) || other.canLogoutAll == canLogoutAll)&&(identical(other.canResetPassword, canResetPassword) || other.canResetPassword == canResetPassword)&&(identical(other.canRemoveBadge, canRemoveBadge) || other.canRemoveBadge == canRemoveBadge)&&(identical(other.canClearProfile, canClearProfile) || other.canClearProfile == canClearProfile)&&(identical(other.canRestoreContent, canRestoreContent) || other.canRestoreContent == canRestoreContent)&&(identical(other.canRevealPhone, canRevealPhone) || other.canRevealPhone == canRevealPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canSuspend,canWarn,canLogoutAll,canResetPassword,canRemoveBadge,canClearProfile,canRestoreContent,canRevealPhone);

@override
String toString() {
  return 'AdminUserActionsModel(canSuspend: $canSuspend, canWarn: $canWarn, canLogoutAll: $canLogoutAll, canResetPassword: $canResetPassword, canRemoveBadge: $canRemoveBadge, canClearProfile: $canClearProfile, canRestoreContent: $canRestoreContent, canRevealPhone: $canRevealPhone)';
}


}

/// @nodoc
abstract mixin class _$AdminUserActionsModelCopyWith<$Res> implements $AdminUserActionsModelCopyWith<$Res> {
  factory _$AdminUserActionsModelCopyWith(_AdminUserActionsModel value, $Res Function(_AdminUserActionsModel) _then) = __$AdminUserActionsModelCopyWithImpl;
@override @useResult
$Res call({
 bool canSuspend, bool canWarn, bool canLogoutAll, bool canResetPassword, bool canRemoveBadge, bool canClearProfile, bool canRestoreContent, bool canRevealPhone
});




}
/// @nodoc
class __$AdminUserActionsModelCopyWithImpl<$Res>
    implements _$AdminUserActionsModelCopyWith<$Res> {
  __$AdminUserActionsModelCopyWithImpl(this._self, this._then);

  final _AdminUserActionsModel _self;
  final $Res Function(_AdminUserActionsModel) _then;

/// Create a copy of AdminUserActionsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canSuspend = null,Object? canWarn = null,Object? canLogoutAll = null,Object? canResetPassword = null,Object? canRemoveBadge = null,Object? canClearProfile = null,Object? canRestoreContent = null,Object? canRevealPhone = null,}) {
  return _then(_AdminUserActionsModel(
canSuspend: null == canSuspend ? _self.canSuspend : canSuspend // ignore: cast_nullable_to_non_nullable
as bool,canWarn: null == canWarn ? _self.canWarn : canWarn // ignore: cast_nullable_to_non_nullable
as bool,canLogoutAll: null == canLogoutAll ? _self.canLogoutAll : canLogoutAll // ignore: cast_nullable_to_non_nullable
as bool,canResetPassword: null == canResetPassword ? _self.canResetPassword : canResetPassword // ignore: cast_nullable_to_non_nullable
as bool,canRemoveBadge: null == canRemoveBadge ? _self.canRemoveBadge : canRemoveBadge // ignore: cast_nullable_to_non_nullable
as bool,canClearProfile: null == canClearProfile ? _self.canClearProfile : canClearProfile // ignore: cast_nullable_to_non_nullable
as bool,canRestoreContent: null == canRestoreContent ? _self.canRestoreContent : canRestoreContent // ignore: cast_nullable_to_non_nullable
as bool,canRevealPhone: null == canRevealPhone ? _self.canRevealPhone : canRevealPhone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AdminUserModerationModel {

 int get warnings; int get suspensions; int get hiddenArticles; int get hiddenComments; int get hiddenWithAccount; List<ModerationActionModel> get history; int get historyTotal;
/// Create a copy of AdminUserModerationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserModerationModelCopyWith<AdminUserModerationModel> get copyWith => _$AdminUserModerationModelCopyWithImpl<AdminUserModerationModel>(this as AdminUserModerationModel, _$identity);

  /// Serializes this AdminUserModerationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserModerationModel&&(identical(other.warnings, warnings) || other.warnings == warnings)&&(identical(other.suspensions, suspensions) || other.suspensions == suspensions)&&(identical(other.hiddenArticles, hiddenArticles) || other.hiddenArticles == hiddenArticles)&&(identical(other.hiddenComments, hiddenComments) || other.hiddenComments == hiddenComments)&&(identical(other.hiddenWithAccount, hiddenWithAccount) || other.hiddenWithAccount == hiddenWithAccount)&&const DeepCollectionEquality().equals(other.history, history)&&(identical(other.historyTotal, historyTotal) || other.historyTotal == historyTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,warnings,suspensions,hiddenArticles,hiddenComments,hiddenWithAccount,const DeepCollectionEquality().hash(history),historyTotal);

@override
String toString() {
  return 'AdminUserModerationModel(warnings: $warnings, suspensions: $suspensions, hiddenArticles: $hiddenArticles, hiddenComments: $hiddenComments, hiddenWithAccount: $hiddenWithAccount, history: $history, historyTotal: $historyTotal)';
}


}

/// @nodoc
abstract mixin class $AdminUserModerationModelCopyWith<$Res>  {
  factory $AdminUserModerationModelCopyWith(AdminUserModerationModel value, $Res Function(AdminUserModerationModel) _then) = _$AdminUserModerationModelCopyWithImpl;
@useResult
$Res call({
 int warnings, int suspensions, int hiddenArticles, int hiddenComments, int hiddenWithAccount, List<ModerationActionModel> history, int historyTotal
});




}
/// @nodoc
class _$AdminUserModerationModelCopyWithImpl<$Res>
    implements $AdminUserModerationModelCopyWith<$Res> {
  _$AdminUserModerationModelCopyWithImpl(this._self, this._then);

  final AdminUserModerationModel _self;
  final $Res Function(AdminUserModerationModel) _then;

/// Create a copy of AdminUserModerationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? warnings = null,Object? suspensions = null,Object? hiddenArticles = null,Object? hiddenComments = null,Object? hiddenWithAccount = null,Object? history = null,Object? historyTotal = null,}) {
  return _then(_self.copyWith(
warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as int,suspensions: null == suspensions ? _self.suspensions : suspensions // ignore: cast_nullable_to_non_nullable
as int,hiddenArticles: null == hiddenArticles ? _self.hiddenArticles : hiddenArticles // ignore: cast_nullable_to_non_nullable
as int,hiddenComments: null == hiddenComments ? _self.hiddenComments : hiddenComments // ignore: cast_nullable_to_non_nullable
as int,hiddenWithAccount: null == hiddenWithAccount ? _self.hiddenWithAccount : hiddenWithAccount // ignore: cast_nullable_to_non_nullable
as int,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<ModerationActionModel>,historyTotal: null == historyTotal ? _self.historyTotal : historyTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserModerationModel].
extension AdminUserModerationModelPatterns on AdminUserModerationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserModerationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserModerationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserModerationModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserModerationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserModerationModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserModerationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int warnings,  int suspensions,  int hiddenArticles,  int hiddenComments,  int hiddenWithAccount,  List<ModerationActionModel> history,  int historyTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserModerationModel() when $default != null:
return $default(_that.warnings,_that.suspensions,_that.hiddenArticles,_that.hiddenComments,_that.hiddenWithAccount,_that.history,_that.historyTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int warnings,  int suspensions,  int hiddenArticles,  int hiddenComments,  int hiddenWithAccount,  List<ModerationActionModel> history,  int historyTotal)  $default,) {final _that = this;
switch (_that) {
case _AdminUserModerationModel():
return $default(_that.warnings,_that.suspensions,_that.hiddenArticles,_that.hiddenComments,_that.hiddenWithAccount,_that.history,_that.historyTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int warnings,  int suspensions,  int hiddenArticles,  int hiddenComments,  int hiddenWithAccount,  List<ModerationActionModel> history,  int historyTotal)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserModerationModel() when $default != null:
return $default(_that.warnings,_that.suspensions,_that.hiddenArticles,_that.hiddenComments,_that.hiddenWithAccount,_that.history,_that.historyTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserModerationModel extends AdminUserModerationModel {
  const _AdminUserModerationModel({this.warnings = 0, this.suspensions = 0, this.hiddenArticles = 0, this.hiddenComments = 0, this.hiddenWithAccount = 0, final  List<ModerationActionModel> history = const <ModerationActionModel>[], this.historyTotal = 0}): _history = history,super._();
  factory _AdminUserModerationModel.fromJson(Map<String, dynamic> json) => _$AdminUserModerationModelFromJson(json);

@override@JsonKey() final  int warnings;
@override@JsonKey() final  int suspensions;
@override@JsonKey() final  int hiddenArticles;
@override@JsonKey() final  int hiddenComments;
@override@JsonKey() final  int hiddenWithAccount;
 final  List<ModerationActionModel> _history;
@override@JsonKey() List<ModerationActionModel> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

@override@JsonKey() final  int historyTotal;

/// Create a copy of AdminUserModerationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserModerationModelCopyWith<_AdminUserModerationModel> get copyWith => __$AdminUserModerationModelCopyWithImpl<_AdminUserModerationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserModerationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserModerationModel&&(identical(other.warnings, warnings) || other.warnings == warnings)&&(identical(other.suspensions, suspensions) || other.suspensions == suspensions)&&(identical(other.hiddenArticles, hiddenArticles) || other.hiddenArticles == hiddenArticles)&&(identical(other.hiddenComments, hiddenComments) || other.hiddenComments == hiddenComments)&&(identical(other.hiddenWithAccount, hiddenWithAccount) || other.hiddenWithAccount == hiddenWithAccount)&&const DeepCollectionEquality().equals(other._history, _history)&&(identical(other.historyTotal, historyTotal) || other.historyTotal == historyTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,warnings,suspensions,hiddenArticles,hiddenComments,hiddenWithAccount,const DeepCollectionEquality().hash(_history),historyTotal);

@override
String toString() {
  return 'AdminUserModerationModel(warnings: $warnings, suspensions: $suspensions, hiddenArticles: $hiddenArticles, hiddenComments: $hiddenComments, hiddenWithAccount: $hiddenWithAccount, history: $history, historyTotal: $historyTotal)';
}


}

/// @nodoc
abstract mixin class _$AdminUserModerationModelCopyWith<$Res> implements $AdminUserModerationModelCopyWith<$Res> {
  factory _$AdminUserModerationModelCopyWith(_AdminUserModerationModel value, $Res Function(_AdminUserModerationModel) _then) = __$AdminUserModerationModelCopyWithImpl;
@override @useResult
$Res call({
 int warnings, int suspensions, int hiddenArticles, int hiddenComments, int hiddenWithAccount, List<ModerationActionModel> history, int historyTotal
});




}
/// @nodoc
class __$AdminUserModerationModelCopyWithImpl<$Res>
    implements _$AdminUserModerationModelCopyWith<$Res> {
  __$AdminUserModerationModelCopyWithImpl(this._self, this._then);

  final _AdminUserModerationModel _self;
  final $Res Function(_AdminUserModerationModel) _then;

/// Create a copy of AdminUserModerationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? warnings = null,Object? suspensions = null,Object? hiddenArticles = null,Object? hiddenComments = null,Object? hiddenWithAccount = null,Object? history = null,Object? historyTotal = null,}) {
  return _then(_AdminUserModerationModel(
warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as int,suspensions: null == suspensions ? _self.suspensions : suspensions // ignore: cast_nullable_to_non_nullable
as int,hiddenArticles: null == hiddenArticles ? _self.hiddenArticles : hiddenArticles // ignore: cast_nullable_to_non_nullable
as int,hiddenComments: null == hiddenComments ? _self.hiddenComments : hiddenComments // ignore: cast_nullable_to_non_nullable
as int,hiddenWithAccount: null == hiddenWithAccount ? _self.hiddenWithAccount : hiddenWithAccount // ignore: cast_nullable_to_non_nullable
as int,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<ModerationActionModel>,historyTotal: null == historyTotal ? _self.historyTotal : historyTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminUserReportModel {

 String get id; String get targetType; String get targetId; String? get targetLabel; String get reason; String? get details; String get status; DateTime get createdAt; UserSummaryModel? get reporter;
/// Create a copy of AdminUserReportModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserReportModelCopyWith<AdminUserReportModel> get copyWith => _$AdminUserReportModelCopyWithImpl<AdminUserReportModel>(this as AdminUserReportModel, _$identity);

  /// Serializes this AdminUserReportModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reporter, reporter) || other.reporter == reporter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetId,targetLabel,reason,details,status,createdAt,reporter);

@override
String toString() {
  return 'AdminUserReportModel(id: $id, targetType: $targetType, targetId: $targetId, targetLabel: $targetLabel, reason: $reason, details: $details, status: $status, createdAt: $createdAt, reporter: $reporter)';
}


}

/// @nodoc
abstract mixin class $AdminUserReportModelCopyWith<$Res>  {
  factory $AdminUserReportModelCopyWith(AdminUserReportModel value, $Res Function(AdminUserReportModel) _then) = _$AdminUserReportModelCopyWithImpl;
@useResult
$Res call({
 String id, String targetType, String targetId, String? targetLabel, String reason, String? details, String status, DateTime createdAt, UserSummaryModel? reporter
});


$UserSummaryModelCopyWith<$Res>? get reporter;

}
/// @nodoc
class _$AdminUserReportModelCopyWithImpl<$Res>
    implements $AdminUserReportModelCopyWith<$Res> {
  _$AdminUserReportModelCopyWithImpl(this._self, this._then);

  final AdminUserReportModel _self;
  final $Res Function(AdminUserReportModel) _then;

/// Create a copy of AdminUserReportModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targetType = null,Object? targetId = null,Object? targetLabel = freezed,Object? reason = null,Object? details = freezed,Object? status = null,Object? createdAt = null,Object? reporter = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reporter: freezed == reporter ? _self.reporter : reporter // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,
  ));
}
/// Create a copy of AdminUserReportModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get reporter {
    if (_self.reporter == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.reporter!, (value) {
    return _then(_self.copyWith(reporter: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminUserReportModel].
extension AdminUserReportModelPatterns on AdminUserReportModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserReportModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserReportModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserReportModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserReportModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserReportModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserReportModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String targetType,  String targetId,  String? targetLabel,  String reason,  String? details,  String status,  DateTime createdAt,  UserSummaryModel? reporter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserReportModel() when $default != null:
return $default(_that.id,_that.targetType,_that.targetId,_that.targetLabel,_that.reason,_that.details,_that.status,_that.createdAt,_that.reporter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String targetType,  String targetId,  String? targetLabel,  String reason,  String? details,  String status,  DateTime createdAt,  UserSummaryModel? reporter)  $default,) {final _that = this;
switch (_that) {
case _AdminUserReportModel():
return $default(_that.id,_that.targetType,_that.targetId,_that.targetLabel,_that.reason,_that.details,_that.status,_that.createdAt,_that.reporter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String targetType,  String targetId,  String? targetLabel,  String reason,  String? details,  String status,  DateTime createdAt,  UserSummaryModel? reporter)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserReportModel() when $default != null:
return $default(_that.id,_that.targetType,_that.targetId,_that.targetLabel,_that.reason,_that.details,_that.status,_that.createdAt,_that.reporter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserReportModel extends AdminUserReportModel {
  const _AdminUserReportModel({required this.id, required this.targetType, required this.targetId, this.targetLabel, this.reason = 'other', this.details, this.status = 'open', required this.createdAt, this.reporter}): super._();
  factory _AdminUserReportModel.fromJson(Map<String, dynamic> json) => _$AdminUserReportModelFromJson(json);

@override final  String id;
@override final  String targetType;
@override final  String targetId;
@override final  String? targetLabel;
@override@JsonKey() final  String reason;
@override final  String? details;
@override@JsonKey() final  String status;
@override final  DateTime createdAt;
@override final  UserSummaryModel? reporter;

/// Create a copy of AdminUserReportModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserReportModelCopyWith<_AdminUserReportModel> get copyWith => __$AdminUserReportModelCopyWithImpl<_AdminUserReportModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserReportModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reporter, reporter) || other.reporter == reporter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetId,targetLabel,reason,details,status,createdAt,reporter);

@override
String toString() {
  return 'AdminUserReportModel(id: $id, targetType: $targetType, targetId: $targetId, targetLabel: $targetLabel, reason: $reason, details: $details, status: $status, createdAt: $createdAt, reporter: $reporter)';
}


}

/// @nodoc
abstract mixin class _$AdminUserReportModelCopyWith<$Res> implements $AdminUserReportModelCopyWith<$Res> {
  factory _$AdminUserReportModelCopyWith(_AdminUserReportModel value, $Res Function(_AdminUserReportModel) _then) = __$AdminUserReportModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String targetType, String targetId, String? targetLabel, String reason, String? details, String status, DateTime createdAt, UserSummaryModel? reporter
});


@override $UserSummaryModelCopyWith<$Res>? get reporter;

}
/// @nodoc
class __$AdminUserReportModelCopyWithImpl<$Res>
    implements _$AdminUserReportModelCopyWith<$Res> {
  __$AdminUserReportModelCopyWithImpl(this._self, this._then);

  final _AdminUserReportModel _self;
  final $Res Function(_AdminUserReportModel) _then;

/// Create a copy of AdminUserReportModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targetType = null,Object? targetId = null,Object? targetLabel = freezed,Object? reason = null,Object? details = freezed,Object? status = null,Object? createdAt = null,Object? reporter = freezed,}) {
  return _then(_AdminUserReportModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reporter: freezed == reporter ? _self.reporter : reporter // ignore: cast_nullable_to_non_nullable
as UserSummaryModel?,
  ));
}

/// Create a copy of AdminUserReportModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryModelCopyWith<$Res>? get reporter {
    if (_self.reporter == null) {
    return null;
  }

  return $UserSummaryModelCopyWith<$Res>(_self.reporter!, (value) {
    return _then(_self.copyWith(reporter: value));
  });
}
}


/// @nodoc
mixin _$AdminUserReportsModel {

 List<AdminUserReportModel> get against; int get againstTotal; List<AdminUserReportModel> get filed; int get filedTotal;
/// Create a copy of AdminUserReportsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserReportsModelCopyWith<AdminUserReportsModel> get copyWith => _$AdminUserReportsModelCopyWithImpl<AdminUserReportsModel>(this as AdminUserReportsModel, _$identity);

  /// Serializes this AdminUserReportsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserReportsModel&&const DeepCollectionEquality().equals(other.against, against)&&(identical(other.againstTotal, againstTotal) || other.againstTotal == againstTotal)&&const DeepCollectionEquality().equals(other.filed, filed)&&(identical(other.filedTotal, filedTotal) || other.filedTotal == filedTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(against),againstTotal,const DeepCollectionEquality().hash(filed),filedTotal);

@override
String toString() {
  return 'AdminUserReportsModel(against: $against, againstTotal: $againstTotal, filed: $filed, filedTotal: $filedTotal)';
}


}

/// @nodoc
abstract mixin class $AdminUserReportsModelCopyWith<$Res>  {
  factory $AdminUserReportsModelCopyWith(AdminUserReportsModel value, $Res Function(AdminUserReportsModel) _then) = _$AdminUserReportsModelCopyWithImpl;
@useResult
$Res call({
 List<AdminUserReportModel> against, int againstTotal, List<AdminUserReportModel> filed, int filedTotal
});




}
/// @nodoc
class _$AdminUserReportsModelCopyWithImpl<$Res>
    implements $AdminUserReportsModelCopyWith<$Res> {
  _$AdminUserReportsModelCopyWithImpl(this._self, this._then);

  final AdminUserReportsModel _self;
  final $Res Function(AdminUserReportsModel) _then;

/// Create a copy of AdminUserReportsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? against = null,Object? againstTotal = null,Object? filed = null,Object? filedTotal = null,}) {
  return _then(_self.copyWith(
against: null == against ? _self.against : against // ignore: cast_nullable_to_non_nullable
as List<AdminUserReportModel>,againstTotal: null == againstTotal ? _self.againstTotal : againstTotal // ignore: cast_nullable_to_non_nullable
as int,filed: null == filed ? _self.filed : filed // ignore: cast_nullable_to_non_nullable
as List<AdminUserReportModel>,filedTotal: null == filedTotal ? _self.filedTotal : filedTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserReportsModel].
extension AdminUserReportsModelPatterns on AdminUserReportsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserReportsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserReportsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserReportsModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserReportsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserReportsModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserReportsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminUserReportModel> against,  int againstTotal,  List<AdminUserReportModel> filed,  int filedTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserReportsModel() when $default != null:
return $default(_that.against,_that.againstTotal,_that.filed,_that.filedTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminUserReportModel> against,  int againstTotal,  List<AdminUserReportModel> filed,  int filedTotal)  $default,) {final _that = this;
switch (_that) {
case _AdminUserReportsModel():
return $default(_that.against,_that.againstTotal,_that.filed,_that.filedTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminUserReportModel> against,  int againstTotal,  List<AdminUserReportModel> filed,  int filedTotal)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserReportsModel() when $default != null:
return $default(_that.against,_that.againstTotal,_that.filed,_that.filedTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserReportsModel implements AdminUserReportsModel {
  const _AdminUserReportsModel({final  List<AdminUserReportModel> against = const <AdminUserReportModel>[], this.againstTotal = 0, final  List<AdminUserReportModel> filed = const <AdminUserReportModel>[], this.filedTotal = 0}): _against = against,_filed = filed;
  factory _AdminUserReportsModel.fromJson(Map<String, dynamic> json) => _$AdminUserReportsModelFromJson(json);

 final  List<AdminUserReportModel> _against;
@override@JsonKey() List<AdminUserReportModel> get against {
  if (_against is EqualUnmodifiableListView) return _against;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_against);
}

@override@JsonKey() final  int againstTotal;
 final  List<AdminUserReportModel> _filed;
@override@JsonKey() List<AdminUserReportModel> get filed {
  if (_filed is EqualUnmodifiableListView) return _filed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filed);
}

@override@JsonKey() final  int filedTotal;

/// Create a copy of AdminUserReportsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserReportsModelCopyWith<_AdminUserReportsModel> get copyWith => __$AdminUserReportsModelCopyWithImpl<_AdminUserReportsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserReportsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserReportsModel&&const DeepCollectionEquality().equals(other._against, _against)&&(identical(other.againstTotal, againstTotal) || other.againstTotal == againstTotal)&&const DeepCollectionEquality().equals(other._filed, _filed)&&(identical(other.filedTotal, filedTotal) || other.filedTotal == filedTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_against),againstTotal,const DeepCollectionEquality().hash(_filed),filedTotal);

@override
String toString() {
  return 'AdminUserReportsModel(against: $against, againstTotal: $againstTotal, filed: $filed, filedTotal: $filedTotal)';
}


}

/// @nodoc
abstract mixin class _$AdminUserReportsModelCopyWith<$Res> implements $AdminUserReportsModelCopyWith<$Res> {
  factory _$AdminUserReportsModelCopyWith(_AdminUserReportsModel value, $Res Function(_AdminUserReportsModel) _then) = __$AdminUserReportsModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminUserReportModel> against, int againstTotal, List<AdminUserReportModel> filed, int filedTotal
});




}
/// @nodoc
class __$AdminUserReportsModelCopyWithImpl<$Res>
    implements _$AdminUserReportsModelCopyWith<$Res> {
  __$AdminUserReportsModelCopyWithImpl(this._self, this._then);

  final _AdminUserReportsModel _self;
  final $Res Function(_AdminUserReportsModel) _then;

/// Create a copy of AdminUserReportsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? against = null,Object? againstTotal = null,Object? filed = null,Object? filedTotal = null,}) {
  return _then(_AdminUserReportsModel(
against: null == against ? _self._against : against // ignore: cast_nullable_to_non_nullable
as List<AdminUserReportModel>,againstTotal: null == againstTotal ? _self.againstTotal : againstTotal // ignore: cast_nullable_to_non_nullable
as int,filed: null == filed ? _self._filed : filed // ignore: cast_nullable_to_non_nullable
as List<AdminUserReportModel>,filedTotal: null == filedTotal ? _self.filedTotal : filedTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminVerificationSectionModel {

 List<AdminVerificationRequestModel> get items; int get total;
/// Create a copy of AdminVerificationSectionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminVerificationSectionModelCopyWith<AdminVerificationSectionModel> get copyWith => _$AdminVerificationSectionModelCopyWithImpl<AdminVerificationSectionModel>(this as AdminVerificationSectionModel, _$identity);

  /// Serializes this AdminVerificationSectionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminVerificationSectionModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),total);

@override
String toString() {
  return 'AdminVerificationSectionModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class $AdminVerificationSectionModelCopyWith<$Res>  {
  factory $AdminVerificationSectionModelCopyWith(AdminVerificationSectionModel value, $Res Function(AdminVerificationSectionModel) _then) = _$AdminVerificationSectionModelCopyWithImpl;
@useResult
$Res call({
 List<AdminVerificationRequestModel> items, int total
});




}
/// @nodoc
class _$AdminVerificationSectionModelCopyWithImpl<$Res>
    implements $AdminVerificationSectionModelCopyWith<$Res> {
  _$AdminVerificationSectionModelCopyWithImpl(this._self, this._then);

  final AdminVerificationSectionModel _self;
  final $Res Function(AdminVerificationSectionModel) _then;

/// Create a copy of AdminVerificationSectionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminVerificationRequestModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminVerificationSectionModel].
extension AdminVerificationSectionModelPatterns on AdminVerificationSectionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminVerificationSectionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminVerificationSectionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminVerificationSectionModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationSectionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminVerificationSectionModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationSectionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminVerificationRequestModel> items,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminVerificationSectionModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminVerificationRequestModel> items,  int total)  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationSectionModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminVerificationRequestModel> items,  int total)?  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationSectionModel() when $default != null:
return $default(_that.items,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminVerificationSectionModel implements AdminVerificationSectionModel {
  const _AdminVerificationSectionModel({final  List<AdminVerificationRequestModel> items = const <AdminVerificationRequestModel>[], this.total = 0}): _items = items;
  factory _AdminVerificationSectionModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationSectionModelFromJson(json);

 final  List<AdminVerificationRequestModel> _items;
@override@JsonKey() List<AdminVerificationRequestModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int total;

/// Create a copy of AdminVerificationSectionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminVerificationSectionModelCopyWith<_AdminVerificationSectionModel> get copyWith => __$AdminVerificationSectionModelCopyWithImpl<_AdminVerificationSectionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminVerificationSectionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminVerificationSectionModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total);

@override
String toString() {
  return 'AdminVerificationSectionModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class _$AdminVerificationSectionModelCopyWith<$Res> implements $AdminVerificationSectionModelCopyWith<$Res> {
  factory _$AdminVerificationSectionModelCopyWith(_AdminVerificationSectionModel value, $Res Function(_AdminVerificationSectionModel) _then) = __$AdminVerificationSectionModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminVerificationRequestModel> items, int total
});




}
/// @nodoc
class __$AdminVerificationSectionModelCopyWithImpl<$Res>
    implements _$AdminVerificationSectionModelCopyWith<$Res> {
  __$AdminVerificationSectionModelCopyWithImpl(this._self, this._then);

  final _AdminVerificationSectionModel _self;
  final $Res Function(_AdminVerificationSectionModel) _then;

/// Create a copy of AdminVerificationSectionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,}) {
  return _then(_AdminVerificationSectionModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminVerificationRequestModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminTicketSectionModel {

 List<AdminTicketModel> get items; int get total;
/// Create a copy of AdminTicketSectionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTicketSectionModelCopyWith<AdminTicketSectionModel> get copyWith => _$AdminTicketSectionModelCopyWithImpl<AdminTicketSectionModel>(this as AdminTicketSectionModel, _$identity);

  /// Serializes this AdminTicketSectionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTicketSectionModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),total);

@override
String toString() {
  return 'AdminTicketSectionModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class $AdminTicketSectionModelCopyWith<$Res>  {
  factory $AdminTicketSectionModelCopyWith(AdminTicketSectionModel value, $Res Function(AdminTicketSectionModel) _then) = _$AdminTicketSectionModelCopyWithImpl;
@useResult
$Res call({
 List<AdminTicketModel> items, int total
});




}
/// @nodoc
class _$AdminTicketSectionModelCopyWithImpl<$Res>
    implements $AdminTicketSectionModelCopyWith<$Res> {
  _$AdminTicketSectionModelCopyWithImpl(this._self, this._then);

  final AdminTicketSectionModel _self;
  final $Res Function(AdminTicketSectionModel) _then;

/// Create a copy of AdminTicketSectionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminTicketModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTicketSectionModel].
extension AdminTicketSectionModelPatterns on AdminTicketSectionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTicketSectionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTicketSectionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTicketSectionModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminTicketSectionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTicketSectionModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTicketSectionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminTicketModel> items,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTicketSectionModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminTicketModel> items,  int total)  $default,) {final _that = this;
switch (_that) {
case _AdminTicketSectionModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminTicketModel> items,  int total)?  $default,) {final _that = this;
switch (_that) {
case _AdminTicketSectionModel() when $default != null:
return $default(_that.items,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminTicketSectionModel implements AdminTicketSectionModel {
  const _AdminTicketSectionModel({final  List<AdminTicketModel> items = const <AdminTicketModel>[], this.total = 0}): _items = items;
  factory _AdminTicketSectionModel.fromJson(Map<String, dynamic> json) => _$AdminTicketSectionModelFromJson(json);

 final  List<AdminTicketModel> _items;
@override@JsonKey() List<AdminTicketModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int total;

/// Create a copy of AdminTicketSectionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTicketSectionModelCopyWith<_AdminTicketSectionModel> get copyWith => __$AdminTicketSectionModelCopyWithImpl<_AdminTicketSectionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminTicketSectionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTicketSectionModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total);

@override
String toString() {
  return 'AdminTicketSectionModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class _$AdminTicketSectionModelCopyWith<$Res> implements $AdminTicketSectionModelCopyWith<$Res> {
  factory _$AdminTicketSectionModelCopyWith(_AdminTicketSectionModel value, $Res Function(_AdminTicketSectionModel) _then) = __$AdminTicketSectionModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminTicketModel> items, int total
});




}
/// @nodoc
class __$AdminTicketSectionModelCopyWithImpl<$Res>
    implements _$AdminTicketSectionModelCopyWith<$Res> {
  __$AdminTicketSectionModelCopyWithImpl(this._self, this._then);

  final _AdminTicketSectionModel _self;
  final $Res Function(_AdminTicketSectionModel) _then;

/// Create a copy of AdminTicketSectionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,}) {
  return _then(_AdminTicketSectionModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminTicketModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AuditUserModel {

 String get id; String get displayName; String get username;
/// Create a copy of AuditUserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditUserModelCopyWith<AuditUserModel> get copyWith => _$AuditUserModelCopyWithImpl<AuditUserModel>(this as AuditUserModel, _$identity);

  /// Serializes this AuditUserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username);

@override
String toString() {
  return 'AuditUserModel(id: $id, displayName: $displayName, username: $username)';
}


}

/// @nodoc
abstract mixin class $AuditUserModelCopyWith<$Res>  {
  factory $AuditUserModelCopyWith(AuditUserModel value, $Res Function(AuditUserModel) _then) = _$AuditUserModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username
});




}
/// @nodoc
class _$AuditUserModelCopyWithImpl<$Res>
    implements $AuditUserModelCopyWith<$Res> {
  _$AuditUserModelCopyWithImpl(this._self, this._then);

  final AuditUserModel _self;
  final $Res Function(AuditUserModel) _then;

/// Create a copy of AuditUserModel
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


/// Adds pattern-matching-related methods to [AuditUserModel].
extension AuditUserModelPatterns on AuditUserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditUserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditUserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditUserModel value)  $default,){
final _that = this;
switch (_that) {
case _AuditUserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditUserModel value)?  $default,){
final _that = this;
switch (_that) {
case _AuditUserModel() when $default != null:
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
case _AuditUserModel() when $default != null:
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
case _AuditUserModel():
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
case _AuditUserModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditUserModel implements AuditUserModel {
  const _AuditUserModel({required this.id, this.displayName = '', this.username = ''});
  factory _AuditUserModel.fromJson(Map<String, dynamic> json) => _$AuditUserModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String username;

/// Create a copy of AuditUserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditUserModelCopyWith<_AuditUserModel> get copyWith => __$AuditUserModelCopyWithImpl<_AuditUserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditUserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username);

@override
String toString() {
  return 'AuditUserModel(id: $id, displayName: $displayName, username: $username)';
}


}

/// @nodoc
abstract mixin class _$AuditUserModelCopyWith<$Res> implements $AuditUserModelCopyWith<$Res> {
  factory _$AuditUserModelCopyWith(_AuditUserModel value, $Res Function(_AuditUserModel) _then) = __$AuditUserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username
});




}
/// @nodoc
class __$AuditUserModelCopyWithImpl<$Res>
    implements _$AuditUserModelCopyWith<$Res> {
  __$AuditUserModelCopyWithImpl(this._self, this._then);

  final _AuditUserModel _self;
  final $Res Function(_AuditUserModel) _then;

/// Create a copy of AuditUserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,}) {
  return _then(_AuditUserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AuditEntryModel {

 String get id; String get action; AuditUserModel? get actor; String? get details; DateTime get createdAt;
/// Create a copy of AuditEntryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditEntryModelCopyWith<AuditEntryModel> get copyWith => _$AuditEntryModelCopyWithImpl<AuditEntryModel>(this as AuditEntryModel, _$identity);

  /// Serializes this AuditEntryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,actor,details,createdAt);

@override
String toString() {
  return 'AuditEntryModel(id: $id, action: $action, actor: $actor, details: $details, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AuditEntryModelCopyWith<$Res>  {
  factory $AuditEntryModelCopyWith(AuditEntryModel value, $Res Function(AuditEntryModel) _then) = _$AuditEntryModelCopyWithImpl;
@useResult
$Res call({
 String id, String action, AuditUserModel? actor, String? details, DateTime createdAt
});


$AuditUserModelCopyWith<$Res>? get actor;

}
/// @nodoc
class _$AuditEntryModelCopyWithImpl<$Res>
    implements $AuditEntryModelCopyWith<$Res> {
  _$AuditEntryModelCopyWithImpl(this._self, this._then);

  final AuditEntryModel _self;
  final $Res Function(AuditEntryModel) _then;

/// Create a copy of AuditEntryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? actor = freezed,Object? details = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as AuditUserModel?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of AuditEntryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditUserModelCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $AuditUserModelCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuditEntryModel].
extension AuditEntryModelPatterns on AuditEntryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditEntryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditEntryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditEntryModel value)  $default,){
final _that = this;
switch (_that) {
case _AuditEntryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditEntryModel value)?  $default,){
final _that = this;
switch (_that) {
case _AuditEntryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String action,  AuditUserModel? actor,  String? details,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditEntryModel() when $default != null:
return $default(_that.id,_that.action,_that.actor,_that.details,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String action,  AuditUserModel? actor,  String? details,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AuditEntryModel():
return $default(_that.id,_that.action,_that.actor,_that.details,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String action,  AuditUserModel? actor,  String? details,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AuditEntryModel() when $default != null:
return $default(_that.id,_that.action,_that.actor,_that.details,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditEntryModel extends AuditEntryModel {
  const _AuditEntryModel({required this.id, this.action = '', this.actor, this.details, required this.createdAt}): super._();
  factory _AuditEntryModel.fromJson(Map<String, dynamic> json) => _$AuditEntryModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String action;
@override final  AuditUserModel? actor;
@override final  String? details;
@override final  DateTime createdAt;

/// Create a copy of AuditEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditEntryModelCopyWith<_AuditEntryModel> get copyWith => __$AuditEntryModelCopyWithImpl<_AuditEntryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditEntryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,actor,details,createdAt);

@override
String toString() {
  return 'AuditEntryModel(id: $id, action: $action, actor: $actor, details: $details, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AuditEntryModelCopyWith<$Res> implements $AuditEntryModelCopyWith<$Res> {
  factory _$AuditEntryModelCopyWith(_AuditEntryModel value, $Res Function(_AuditEntryModel) _then) = __$AuditEntryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String action, AuditUserModel? actor, String? details, DateTime createdAt
});


@override $AuditUserModelCopyWith<$Res>? get actor;

}
/// @nodoc
class __$AuditEntryModelCopyWithImpl<$Res>
    implements _$AuditEntryModelCopyWith<$Res> {
  __$AuditEntryModelCopyWithImpl(this._self, this._then);

  final _AuditEntryModel _self;
  final $Res Function(_AuditEntryModel) _then;

/// Create a copy of AuditEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? actor = freezed,Object? details = freezed,Object? createdAt = null,}) {
  return _then(_AuditEntryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as AuditUserModel?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of AuditEntryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditUserModelCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $AuditUserModelCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}
}


/// @nodoc
mixin _$AdminAuditSectionModel {

 List<AuditEntryModel> get items; int get total;
/// Create a copy of AdminAuditSectionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminAuditSectionModelCopyWith<AdminAuditSectionModel> get copyWith => _$AdminAuditSectionModelCopyWithImpl<AdminAuditSectionModel>(this as AdminAuditSectionModel, _$identity);

  /// Serializes this AdminAuditSectionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminAuditSectionModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),total);

@override
String toString() {
  return 'AdminAuditSectionModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class $AdminAuditSectionModelCopyWith<$Res>  {
  factory $AdminAuditSectionModelCopyWith(AdminAuditSectionModel value, $Res Function(AdminAuditSectionModel) _then) = _$AdminAuditSectionModelCopyWithImpl;
@useResult
$Res call({
 List<AuditEntryModel> items, int total
});




}
/// @nodoc
class _$AdminAuditSectionModelCopyWithImpl<$Res>
    implements $AdminAuditSectionModelCopyWith<$Res> {
  _$AdminAuditSectionModelCopyWithImpl(this._self, this._then);

  final AdminAuditSectionModel _self;
  final $Res Function(AdminAuditSectionModel) _then;

/// Create a copy of AdminAuditSectionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AuditEntryModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminAuditSectionModel].
extension AdminAuditSectionModelPatterns on AdminAuditSectionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminAuditSectionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminAuditSectionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminAuditSectionModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminAuditSectionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminAuditSectionModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminAuditSectionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AuditEntryModel> items,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminAuditSectionModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AuditEntryModel> items,  int total)  $default,) {final _that = this;
switch (_that) {
case _AdminAuditSectionModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AuditEntryModel> items,  int total)?  $default,) {final _that = this;
switch (_that) {
case _AdminAuditSectionModel() when $default != null:
return $default(_that.items,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminAuditSectionModel implements AdminAuditSectionModel {
  const _AdminAuditSectionModel({final  List<AuditEntryModel> items = const <AuditEntryModel>[], this.total = 0}): _items = items;
  factory _AdminAuditSectionModel.fromJson(Map<String, dynamic> json) => _$AdminAuditSectionModelFromJson(json);

 final  List<AuditEntryModel> _items;
@override@JsonKey() List<AuditEntryModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int total;

/// Create a copy of AdminAuditSectionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminAuditSectionModelCopyWith<_AdminAuditSectionModel> get copyWith => __$AdminAuditSectionModelCopyWithImpl<_AdminAuditSectionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminAuditSectionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminAuditSectionModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total);

@override
String toString() {
  return 'AdminAuditSectionModel(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class _$AdminAuditSectionModelCopyWith<$Res> implements $AdminAuditSectionModelCopyWith<$Res> {
  factory _$AdminAuditSectionModelCopyWith(_AdminAuditSectionModel value, $Res Function(_AdminAuditSectionModel) _then) = __$AdminAuditSectionModelCopyWithImpl;
@override @useResult
$Res call({
 List<AuditEntryModel> items, int total
});




}
/// @nodoc
class __$AdminAuditSectionModelCopyWithImpl<$Res>
    implements _$AdminAuditSectionModelCopyWith<$Res> {
  __$AdminAuditSectionModelCopyWithImpl(this._self, this._then);

  final _AdminAuditSectionModel _self;
  final $Res Function(_AdminAuditSectionModel) _then;

/// Create a copy of AdminAuditSectionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,}) {
  return _then(_AdminAuditSectionModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AuditEntryModel>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminUserPageModel {

 List<AdminUserModel> get items; int get page; int get pageSize; int get totalCount; int get totalPages;
/// Create a copy of AdminUserPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserPageModelCopyWith<AdminUserPageModel> get copyWith => _$AdminUserPageModelCopyWithImpl<AdminUserPageModel>(this as AdminUserPageModel, _$identity);

  /// Serializes this AdminUserPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminUserPageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class $AdminUserPageModelCopyWith<$Res>  {
  factory $AdminUserPageModelCopyWith(AdminUserPageModel value, $Res Function(AdminUserPageModel) _then) = _$AdminUserPageModelCopyWithImpl;
@useResult
$Res call({
 List<AdminUserModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class _$AdminUserPageModelCopyWithImpl<$Res>
    implements $AdminUserPageModelCopyWith<$Res> {
  _$AdminUserPageModelCopyWithImpl(this._self, this._then);

  final AdminUserPageModel _self;
  final $Res Function(AdminUserPageModel) _then;

/// Create a copy of AdminUserPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminUserModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserPageModel].
extension AdminUserPageModelPatterns on AdminUserPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserPageModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminUserModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminUserModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)  $default,) {final _that = this;
switch (_that) {
case _AdminUserPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminUserModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserPageModel() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.totalCount,_that.totalPages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminUserPageModel extends AdminUserPageModel {
  const _AdminUserPageModel({final  List<AdminUserModel> items = const <AdminUserModel>[], this.page = 1, this.pageSize = 50, this.totalCount = 0, this.totalPages = 0}): _items = items,super._();
  factory _AdminUserPageModel.fromJson(Map<String, dynamic> json) => _$AdminUserPageModelFromJson(json);

 final  List<AdminUserModel> _items;
@override@JsonKey() List<AdminUserModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  int pageSize;
@override@JsonKey() final  int totalCount;
@override@JsonKey() final  int totalPages;

/// Create a copy of AdminUserPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserPageModelCopyWith<_AdminUserPageModel> get copyWith => __$AdminUserPageModelCopyWithImpl<_AdminUserPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminUserPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminUserPageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class _$AdminUserPageModelCopyWith<$Res> implements $AdminUserPageModelCopyWith<$Res> {
  factory _$AdminUserPageModelCopyWith(_AdminUserPageModel value, $Res Function(_AdminUserPageModel) _then) = __$AdminUserPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminUserModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class __$AdminUserPageModelCopyWithImpl<$Res>
    implements _$AdminUserPageModelCopyWith<$Res> {
  __$AdminUserPageModelCopyWithImpl(this._self, this._then);

  final _AdminUserPageModel _self;
  final $Res Function(_AdminUserPageModel) _then;

/// Create a copy of AdminUserPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_AdminUserPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminUserModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminPhoneModel {

 String? get phoneNumber;
/// Create a copy of AdminPhoneModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminPhoneModelCopyWith<AdminPhoneModel> get copyWith => _$AdminPhoneModelCopyWithImpl<AdminPhoneModel>(this as AdminPhoneModel, _$identity);

  /// Serializes this AdminPhoneModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminPhoneModel&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber);

@override
String toString() {
  return 'AdminPhoneModel(phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class $AdminPhoneModelCopyWith<$Res>  {
  factory $AdminPhoneModelCopyWith(AdminPhoneModel value, $Res Function(AdminPhoneModel) _then) = _$AdminPhoneModelCopyWithImpl;
@useResult
$Res call({
 String? phoneNumber
});




}
/// @nodoc
class _$AdminPhoneModelCopyWithImpl<$Res>
    implements $AdminPhoneModelCopyWith<$Res> {
  _$AdminPhoneModelCopyWithImpl(this._self, this._then);

  final AdminPhoneModel _self;
  final $Res Function(AdminPhoneModel) _then;

/// Create a copy of AdminPhoneModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phoneNumber = freezed,}) {
  return _then(_self.copyWith(
phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminPhoneModel].
extension AdminPhoneModelPatterns on AdminPhoneModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminPhoneModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminPhoneModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminPhoneModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminPhoneModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminPhoneModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminPhoneModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? phoneNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminPhoneModel() when $default != null:
return $default(_that.phoneNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? phoneNumber)  $default,) {final _that = this;
switch (_that) {
case _AdminPhoneModel():
return $default(_that.phoneNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? phoneNumber)?  $default,) {final _that = this;
switch (_that) {
case _AdminPhoneModel() when $default != null:
return $default(_that.phoneNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminPhoneModel implements AdminPhoneModel {
  const _AdminPhoneModel({this.phoneNumber});
  factory _AdminPhoneModel.fromJson(Map<String, dynamic> json) => _$AdminPhoneModelFromJson(json);

@override final  String? phoneNumber;

/// Create a copy of AdminPhoneModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminPhoneModelCopyWith<_AdminPhoneModel> get copyWith => __$AdminPhoneModelCopyWithImpl<_AdminPhoneModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminPhoneModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminPhoneModel&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber);

@override
String toString() {
  return 'AdminPhoneModel(phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class _$AdminPhoneModelCopyWith<$Res> implements $AdminPhoneModelCopyWith<$Res> {
  factory _$AdminPhoneModelCopyWith(_AdminPhoneModel value, $Res Function(_AdminPhoneModel) _then) = __$AdminPhoneModelCopyWithImpl;
@override @useResult
$Res call({
 String? phoneNumber
});




}
/// @nodoc
class __$AdminPhoneModelCopyWithImpl<$Res>
    implements _$AdminPhoneModelCopyWith<$Res> {
  __$AdminPhoneModelCopyWithImpl(this._self, this._then);

  final _AdminPhoneModel _self;
  final $Res Function(_AdminPhoneModel) _then;

/// Create a copy of AdminPhoneModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phoneNumber = freezed,}) {
  return _then(_AdminPhoneModel(
phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TemporaryPasswordModel {

 String get temporaryPassword;
/// Create a copy of TemporaryPasswordModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemporaryPasswordModelCopyWith<TemporaryPasswordModel> get copyWith => _$TemporaryPasswordModelCopyWithImpl<TemporaryPasswordModel>(this as TemporaryPasswordModel, _$identity);

  /// Serializes this TemporaryPasswordModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemporaryPasswordModel&&(identical(other.temporaryPassword, temporaryPassword) || other.temporaryPassword == temporaryPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,temporaryPassword);

@override
String toString() {
  return 'TemporaryPasswordModel(temporaryPassword: $temporaryPassword)';
}


}

/// @nodoc
abstract mixin class $TemporaryPasswordModelCopyWith<$Res>  {
  factory $TemporaryPasswordModelCopyWith(TemporaryPasswordModel value, $Res Function(TemporaryPasswordModel) _then) = _$TemporaryPasswordModelCopyWithImpl;
@useResult
$Res call({
 String temporaryPassword
});




}
/// @nodoc
class _$TemporaryPasswordModelCopyWithImpl<$Res>
    implements $TemporaryPasswordModelCopyWith<$Res> {
  _$TemporaryPasswordModelCopyWithImpl(this._self, this._then);

  final TemporaryPasswordModel _self;
  final $Res Function(TemporaryPasswordModel) _then;

/// Create a copy of TemporaryPasswordModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? temporaryPassword = null,}) {
  return _then(_self.copyWith(
temporaryPassword: null == temporaryPassword ? _self.temporaryPassword : temporaryPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TemporaryPasswordModel].
extension TemporaryPasswordModelPatterns on TemporaryPasswordModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemporaryPasswordModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemporaryPasswordModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemporaryPasswordModel value)  $default,){
final _that = this;
switch (_that) {
case _TemporaryPasswordModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemporaryPasswordModel value)?  $default,){
final _that = this;
switch (_that) {
case _TemporaryPasswordModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String temporaryPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TemporaryPasswordModel() when $default != null:
return $default(_that.temporaryPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String temporaryPassword)  $default,) {final _that = this;
switch (_that) {
case _TemporaryPasswordModel():
return $default(_that.temporaryPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String temporaryPassword)?  $default,) {final _that = this;
switch (_that) {
case _TemporaryPasswordModel() when $default != null:
return $default(_that.temporaryPassword);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TemporaryPasswordModel implements TemporaryPasswordModel {
  const _TemporaryPasswordModel({this.temporaryPassword = ''});
  factory _TemporaryPasswordModel.fromJson(Map<String, dynamic> json) => _$TemporaryPasswordModelFromJson(json);

@override@JsonKey() final  String temporaryPassword;

/// Create a copy of TemporaryPasswordModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemporaryPasswordModelCopyWith<_TemporaryPasswordModel> get copyWith => __$TemporaryPasswordModelCopyWithImpl<_TemporaryPasswordModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemporaryPasswordModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemporaryPasswordModel&&(identical(other.temporaryPassword, temporaryPassword) || other.temporaryPassword == temporaryPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,temporaryPassword);

@override
String toString() {
  return 'TemporaryPasswordModel(temporaryPassword: $temporaryPassword)';
}


}

/// @nodoc
abstract mixin class _$TemporaryPasswordModelCopyWith<$Res> implements $TemporaryPasswordModelCopyWith<$Res> {
  factory _$TemporaryPasswordModelCopyWith(_TemporaryPasswordModel value, $Res Function(_TemporaryPasswordModel) _then) = __$TemporaryPasswordModelCopyWithImpl;
@override @useResult
$Res call({
 String temporaryPassword
});




}
/// @nodoc
class __$TemporaryPasswordModelCopyWithImpl<$Res>
    implements _$TemporaryPasswordModelCopyWith<$Res> {
  __$TemporaryPasswordModelCopyWithImpl(this._self, this._then);

  final _TemporaryPasswordModel _self;
  final $Res Function(_TemporaryPasswordModel) _then;

/// Create a copy of TemporaryPasswordModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? temporaryPassword = null,}) {
  return _then(_TemporaryPasswordModel(
temporaryPassword: null == temporaryPassword ? _self.temporaryPassword : temporaryPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AdminArticleRowModel {

 String get id; String get slug; String get status; String get title; String get language; AuthorModel? get author; FieldRefModel get field; FieldRefModel? get topic;// Null: archived without ever being published (as built).
 DateTime? get publishedAt; int get readCount; int get reactionCount; int get commentCount; DateTime? get hiddenAt; DateTime? get featuredAt; int get openReports; int get reportCount;
/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminArticleRowModelCopyWith<AdminArticleRowModel> get copyWith => _$AdminArticleRowModelCopyWithImpl<AdminArticleRowModel>(this as AdminArticleRowModel, _$identity);

  /// Serializes this AdminArticleRowModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminArticleRowModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.author, author) || other.author == author)&&(identical(other.field, field) || other.field == field)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.readCount, readCount) || other.readCount == readCount)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.hiddenAt, hiddenAt) || other.hiddenAt == hiddenAt)&&(identical(other.featuredAt, featuredAt) || other.featuredAt == featuredAt)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,status,title,language,author,field,topic,publishedAt,readCount,reactionCount,commentCount,hiddenAt,featuredAt,openReports,reportCount);

@override
String toString() {
  return 'AdminArticleRowModel(id: $id, slug: $slug, status: $status, title: $title, language: $language, author: $author, field: $field, topic: $topic, publishedAt: $publishedAt, readCount: $readCount, reactionCount: $reactionCount, commentCount: $commentCount, hiddenAt: $hiddenAt, featuredAt: $featuredAt, openReports: $openReports, reportCount: $reportCount)';
}


}

/// @nodoc
abstract mixin class $AdminArticleRowModelCopyWith<$Res>  {
  factory $AdminArticleRowModelCopyWith(AdminArticleRowModel value, $Res Function(AdminArticleRowModel) _then) = _$AdminArticleRowModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String status, String title, String language, AuthorModel? author, FieldRefModel field, FieldRefModel? topic, DateTime? publishedAt, int readCount, int reactionCount, int commentCount, DateTime? hiddenAt, DateTime? featuredAt, int openReports, int reportCount
});


$AuthorModelCopyWith<$Res>? get author;$FieldRefModelCopyWith<$Res> get field;$FieldRefModelCopyWith<$Res>? get topic;

}
/// @nodoc
class _$AdminArticleRowModelCopyWithImpl<$Res>
    implements $AdminArticleRowModelCopyWith<$Res> {
  _$AdminArticleRowModelCopyWithImpl(this._self, this._then);

  final AdminArticleRowModel _self;
  final $Res Function(AdminArticleRowModel) _then;

/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? status = null,Object? title = null,Object? language = null,Object? author = freezed,Object? field = null,Object? topic = freezed,Object? publishedAt = freezed,Object? readCount = null,Object? reactionCount = null,Object? commentCount = null,Object? hiddenAt = freezed,Object? featuredAt = freezed,Object? openReports = null,Object? reportCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,hiddenAt: freezed == hiddenAt ? _self.hiddenAt : hiddenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,featuredAt: freezed == featuredAt ? _self.featuredAt : featuredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AdminArticleRowModel
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
}/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminArticleRowModel].
extension AdminArticleRowModelPatterns on AdminArticleRowModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminArticleRowModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminArticleRowModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminArticleRowModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminArticleRowModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminArticleRowModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminArticleRowModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String status,  String title,  String language,  AuthorModel? author,  FieldRefModel field,  FieldRefModel? topic,  DateTime? publishedAt,  int readCount,  int reactionCount,  int commentCount,  DateTime? hiddenAt,  DateTime? featuredAt,  int openReports,  int reportCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminArticleRowModel() when $default != null:
return $default(_that.id,_that.slug,_that.status,_that.title,_that.language,_that.author,_that.field,_that.topic,_that.publishedAt,_that.readCount,_that.reactionCount,_that.commentCount,_that.hiddenAt,_that.featuredAt,_that.openReports,_that.reportCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String status,  String title,  String language,  AuthorModel? author,  FieldRefModel field,  FieldRefModel? topic,  DateTime? publishedAt,  int readCount,  int reactionCount,  int commentCount,  DateTime? hiddenAt,  DateTime? featuredAt,  int openReports,  int reportCount)  $default,) {final _that = this;
switch (_that) {
case _AdminArticleRowModel():
return $default(_that.id,_that.slug,_that.status,_that.title,_that.language,_that.author,_that.field,_that.topic,_that.publishedAt,_that.readCount,_that.reactionCount,_that.commentCount,_that.hiddenAt,_that.featuredAt,_that.openReports,_that.reportCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String status,  String title,  String language,  AuthorModel? author,  FieldRefModel field,  FieldRefModel? topic,  DateTime? publishedAt,  int readCount,  int reactionCount,  int commentCount,  DateTime? hiddenAt,  DateTime? featuredAt,  int openReports,  int reportCount)?  $default,) {final _that = this;
switch (_that) {
case _AdminArticleRowModel() when $default != null:
return $default(_that.id,_that.slug,_that.status,_that.title,_that.language,_that.author,_that.field,_that.topic,_that.publishedAt,_that.readCount,_that.reactionCount,_that.commentCount,_that.hiddenAt,_that.featuredAt,_that.openReports,_that.reportCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminArticleRowModel extends AdminArticleRowModel {
  const _AdminArticleRowModel({required this.id, required this.slug, this.status = 'published', this.title = '', this.language = 'ar-EG', this.author, required this.field, this.topic, this.publishedAt, this.readCount = 0, this.reactionCount = 0, this.commentCount = 0, this.hiddenAt, this.featuredAt, this.openReports = 0, this.reportCount = 0}): super._();
  factory _AdminArticleRowModel.fromJson(Map<String, dynamic> json) => _$AdminArticleRowModelFromJson(json);

@override final  String id;
@override final  String slug;
@override@JsonKey() final  String status;
@override@JsonKey() final  String title;
@override@JsonKey() final  String language;
@override final  AuthorModel? author;
@override final  FieldRefModel field;
@override final  FieldRefModel? topic;
// Null: archived without ever being published (as built).
@override final  DateTime? publishedAt;
@override@JsonKey() final  int readCount;
@override@JsonKey() final  int reactionCount;
@override@JsonKey() final  int commentCount;
@override final  DateTime? hiddenAt;
@override final  DateTime? featuredAt;
@override@JsonKey() final  int openReports;
@override@JsonKey() final  int reportCount;

/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminArticleRowModelCopyWith<_AdminArticleRowModel> get copyWith => __$AdminArticleRowModelCopyWithImpl<_AdminArticleRowModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminArticleRowModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminArticleRowModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.author, author) || other.author == author)&&(identical(other.field, field) || other.field == field)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.readCount, readCount) || other.readCount == readCount)&&(identical(other.reactionCount, reactionCount) || other.reactionCount == reactionCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.hiddenAt, hiddenAt) || other.hiddenAt == hiddenAt)&&(identical(other.featuredAt, featuredAt) || other.featuredAt == featuredAt)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,status,title,language,author,field,topic,publishedAt,readCount,reactionCount,commentCount,hiddenAt,featuredAt,openReports,reportCount);

@override
String toString() {
  return 'AdminArticleRowModel(id: $id, slug: $slug, status: $status, title: $title, language: $language, author: $author, field: $field, topic: $topic, publishedAt: $publishedAt, readCount: $readCount, reactionCount: $reactionCount, commentCount: $commentCount, hiddenAt: $hiddenAt, featuredAt: $featuredAt, openReports: $openReports, reportCount: $reportCount)';
}


}

/// @nodoc
abstract mixin class _$AdminArticleRowModelCopyWith<$Res> implements $AdminArticleRowModelCopyWith<$Res> {
  factory _$AdminArticleRowModelCopyWith(_AdminArticleRowModel value, $Res Function(_AdminArticleRowModel) _then) = __$AdminArticleRowModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String status, String title, String language, AuthorModel? author, FieldRefModel field, FieldRefModel? topic, DateTime? publishedAt, int readCount, int reactionCount, int commentCount, DateTime? hiddenAt, DateTime? featuredAt, int openReports, int reportCount
});


@override $AuthorModelCopyWith<$Res>? get author;@override $FieldRefModelCopyWith<$Res> get field;@override $FieldRefModelCopyWith<$Res>? get topic;

}
/// @nodoc
class __$AdminArticleRowModelCopyWithImpl<$Res>
    implements _$AdminArticleRowModelCopyWith<$Res> {
  __$AdminArticleRowModelCopyWithImpl(this._self, this._then);

  final _AdminArticleRowModel _self;
  final $Res Function(_AdminArticleRowModel) _then;

/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? status = null,Object? title = null,Object? language = null,Object? author = freezed,Object? field = null,Object? topic = freezed,Object? publishedAt = freezed,Object? readCount = null,Object? reactionCount = null,Object? commentCount = null,Object? hiddenAt = freezed,Object? featuredAt = freezed,Object? openReports = null,Object? reportCount = null,}) {
  return _then(_AdminArticleRowModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as FieldRefModel,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as FieldRefModel?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readCount: null == readCount ? _self.readCount : readCount // ignore: cast_nullable_to_non_nullable
as int,reactionCount: null == reactionCount ? _self.reactionCount : reactionCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,hiddenAt: freezed == hiddenAt ? _self.hiddenAt : hiddenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,featuredAt: freezed == featuredAt ? _self.featuredAt : featuredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AdminArticleRowModel
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
}/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res> get field {
  
  return $FieldRefModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of AdminArticleRowModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FieldRefModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $FieldRefModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}
}


/// @nodoc
mixin _$AdminArticlePageModel {

 List<AdminArticleRowModel> get items; int get page; int get pageSize; int get totalCount; int get totalPages;
/// Create a copy of AdminArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminArticlePageModelCopyWith<AdminArticlePageModel> get copyWith => _$AdminArticlePageModelCopyWithImpl<AdminArticlePageModel>(this as AdminArticlePageModel, _$identity);

  /// Serializes this AdminArticlePageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminArticlePageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminArticlePageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class $AdminArticlePageModelCopyWith<$Res>  {
  factory $AdminArticlePageModelCopyWith(AdminArticlePageModel value, $Res Function(AdminArticlePageModel) _then) = _$AdminArticlePageModelCopyWithImpl;
@useResult
$Res call({
 List<AdminArticleRowModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class _$AdminArticlePageModelCopyWithImpl<$Res>
    implements $AdminArticlePageModelCopyWith<$Res> {
  _$AdminArticlePageModelCopyWithImpl(this._self, this._then);

  final AdminArticlePageModel _self;
  final $Res Function(AdminArticlePageModel) _then;

/// Create a copy of AdminArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminArticleRowModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminArticlePageModel].
extension AdminArticlePageModelPatterns on AdminArticlePageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminArticlePageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminArticlePageModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminArticlePageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminArticlePageModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminArticleRowModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminArticlePageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminArticleRowModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)  $default,) {final _that = this;
switch (_that) {
case _AdminArticlePageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminArticleRowModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,) {final _that = this;
switch (_that) {
case _AdminArticlePageModel() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.totalCount,_that.totalPages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminArticlePageModel extends AdminArticlePageModel {
  const _AdminArticlePageModel({final  List<AdminArticleRowModel> items = const <AdminArticleRowModel>[], this.page = 1, this.pageSize = 50, this.totalCount = 0, this.totalPages = 0}): _items = items,super._();
  factory _AdminArticlePageModel.fromJson(Map<String, dynamic> json) => _$AdminArticlePageModelFromJson(json);

 final  List<AdminArticleRowModel> _items;
@override@JsonKey() List<AdminArticleRowModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  int pageSize;
@override@JsonKey() final  int totalCount;
@override@JsonKey() final  int totalPages;

/// Create a copy of AdminArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminArticlePageModelCopyWith<_AdminArticlePageModel> get copyWith => __$AdminArticlePageModelCopyWithImpl<_AdminArticlePageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminArticlePageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminArticlePageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminArticlePageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class _$AdminArticlePageModelCopyWith<$Res> implements $AdminArticlePageModelCopyWith<$Res> {
  factory _$AdminArticlePageModelCopyWith(_AdminArticlePageModel value, $Res Function(_AdminArticlePageModel) _then) = __$AdminArticlePageModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminArticleRowModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class __$AdminArticlePageModelCopyWithImpl<$Res>
    implements _$AdminArticlePageModelCopyWith<$Res> {
  __$AdminArticlePageModelCopyWithImpl(this._self, this._then);

  final _AdminArticlePageModel _self;
  final $Res Function(_AdminArticlePageModel) _then;

/// Create a copy of AdminArticlePageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_AdminArticlePageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminArticleRowModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminCommentArticleModel {

 String get id; String get slug; String get title; String get language;
/// Create a copy of AdminCommentArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminCommentArticleModelCopyWith<AdminCommentArticleModel> get copyWith => _$AdminCommentArticleModelCopyWithImpl<AdminCommentArticleModel>(this as AdminCommentArticleModel, _$identity);

  /// Serializes this AdminCommentArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminCommentArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language);

@override
String toString() {
  return 'AdminCommentArticleModel(id: $id, slug: $slug, title: $title, language: $language)';
}


}

/// @nodoc
abstract mixin class $AdminCommentArticleModelCopyWith<$Res>  {
  factory $AdminCommentArticleModelCopyWith(AdminCommentArticleModel value, $Res Function(AdminCommentArticleModel) _then) = _$AdminCommentArticleModelCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String language
});




}
/// @nodoc
class _$AdminCommentArticleModelCopyWithImpl<$Res>
    implements $AdminCommentArticleModelCopyWith<$Res> {
  _$AdminCommentArticleModelCopyWithImpl(this._self, this._then);

  final AdminCommentArticleModel _self;
  final $Res Function(AdminCommentArticleModel) _then;

/// Create a copy of AdminCommentArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminCommentArticleModel].
extension AdminCommentArticleModelPatterns on AdminCommentArticleModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminCommentArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminCommentArticleModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminCommentArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminCommentArticleModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminCommentArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminCommentArticleModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminCommentArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String language)  $default,) {final _that = this;
switch (_that) {
case _AdminCommentArticleModel():
return $default(_that.id,_that.slug,_that.title,_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String language)?  $default,) {final _that = this;
switch (_that) {
case _AdminCommentArticleModel() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminCommentArticleModel implements AdminCommentArticleModel {
  const _AdminCommentArticleModel({required this.id, this.slug = '', this.title = '', this.language = 'ar-EG'});
  factory _AdminCommentArticleModel.fromJson(Map<String, dynamic> json) => _$AdminCommentArticleModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String slug;
@override@JsonKey() final  String title;
@override@JsonKey() final  String language;

/// Create a copy of AdminCommentArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminCommentArticleModelCopyWith<_AdminCommentArticleModel> get copyWith => __$AdminCommentArticleModelCopyWithImpl<_AdminCommentArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminCommentArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminCommentArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,language);

@override
String toString() {
  return 'AdminCommentArticleModel(id: $id, slug: $slug, title: $title, language: $language)';
}


}

/// @nodoc
abstract mixin class _$AdminCommentArticleModelCopyWith<$Res> implements $AdminCommentArticleModelCopyWith<$Res> {
  factory _$AdminCommentArticleModelCopyWith(_AdminCommentArticleModel value, $Res Function(_AdminCommentArticleModel) _then) = __$AdminCommentArticleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String language
});




}
/// @nodoc
class __$AdminCommentArticleModelCopyWithImpl<$Res>
    implements _$AdminCommentArticleModelCopyWith<$Res> {
  __$AdminCommentArticleModelCopyWithImpl(this._self, this._then);

  final _AdminCommentArticleModel _self;
  final $Res Function(_AdminCommentArticleModel) _then;

/// Create a copy of AdminCommentArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? language = null,}) {
  return _then(_AdminCommentArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AdminCommentRowModel {

 String get id; String get body; AuthorModel? get author; AdminCommentArticleModel get article; String? get parentId; DateTime get createdAt; DateTime? get editedAt; DateTime? get hiddenAt; int get likeCount; int get replyCount; int get openReports; int get reportCount;
/// Create a copy of AdminCommentRowModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminCommentRowModelCopyWith<AdminCommentRowModel> get copyWith => _$AdminCommentRowModelCopyWithImpl<AdminCommentRowModel>(this as AdminCommentRowModel, _$identity);

  /// Serializes this AdminCommentRowModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminCommentRowModel&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.article, article) || other.article == article)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.hiddenAt, hiddenAt) || other.hiddenAt == hiddenAt)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,body,author,article,parentId,createdAt,editedAt,hiddenAt,likeCount,replyCount,openReports,reportCount);

@override
String toString() {
  return 'AdminCommentRowModel(id: $id, body: $body, author: $author, article: $article, parentId: $parentId, createdAt: $createdAt, editedAt: $editedAt, hiddenAt: $hiddenAt, likeCount: $likeCount, replyCount: $replyCount, openReports: $openReports, reportCount: $reportCount)';
}


}

/// @nodoc
abstract mixin class $AdminCommentRowModelCopyWith<$Res>  {
  factory $AdminCommentRowModelCopyWith(AdminCommentRowModel value, $Res Function(AdminCommentRowModel) _then) = _$AdminCommentRowModelCopyWithImpl;
@useResult
$Res call({
 String id, String body, AuthorModel? author, AdminCommentArticleModel article, String? parentId, DateTime createdAt, DateTime? editedAt, DateTime? hiddenAt, int likeCount, int replyCount, int openReports, int reportCount
});


$AuthorModelCopyWith<$Res>? get author;$AdminCommentArticleModelCopyWith<$Res> get article;

}
/// @nodoc
class _$AdminCommentRowModelCopyWithImpl<$Res>
    implements $AdminCommentRowModelCopyWith<$Res> {
  _$AdminCommentRowModelCopyWithImpl(this._self, this._then);

  final AdminCommentRowModel _self;
  final $Res Function(AdminCommentRowModel) _then;

/// Create a copy of AdminCommentRowModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? body = null,Object? author = freezed,Object? article = null,Object? parentId = freezed,Object? createdAt = null,Object? editedAt = freezed,Object? hiddenAt = freezed,Object? likeCount = null,Object? replyCount = null,Object? openReports = null,Object? reportCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as AdminCommentArticleModel,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hiddenAt: freezed == hiddenAt ? _self.hiddenAt : hiddenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AdminCommentRowModel
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
}/// Create a copy of AdminCommentRowModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminCommentArticleModelCopyWith<$Res> get article {
  
  return $AdminCommentArticleModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminCommentRowModel].
extension AdminCommentRowModelPatterns on AdminCommentRowModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminCommentRowModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminCommentRowModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminCommentRowModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminCommentRowModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminCommentRowModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminCommentRowModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String body,  AuthorModel? author,  AdminCommentArticleModel article,  String? parentId,  DateTime createdAt,  DateTime? editedAt,  DateTime? hiddenAt,  int likeCount,  int replyCount,  int openReports,  int reportCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminCommentRowModel() when $default != null:
return $default(_that.id,_that.body,_that.author,_that.article,_that.parentId,_that.createdAt,_that.editedAt,_that.hiddenAt,_that.likeCount,_that.replyCount,_that.openReports,_that.reportCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String body,  AuthorModel? author,  AdminCommentArticleModel article,  String? parentId,  DateTime createdAt,  DateTime? editedAt,  DateTime? hiddenAt,  int likeCount,  int replyCount,  int openReports,  int reportCount)  $default,) {final _that = this;
switch (_that) {
case _AdminCommentRowModel():
return $default(_that.id,_that.body,_that.author,_that.article,_that.parentId,_that.createdAt,_that.editedAt,_that.hiddenAt,_that.likeCount,_that.replyCount,_that.openReports,_that.reportCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String body,  AuthorModel? author,  AdminCommentArticleModel article,  String? parentId,  DateTime createdAt,  DateTime? editedAt,  DateTime? hiddenAt,  int likeCount,  int replyCount,  int openReports,  int reportCount)?  $default,) {final _that = this;
switch (_that) {
case _AdminCommentRowModel() when $default != null:
return $default(_that.id,_that.body,_that.author,_that.article,_that.parentId,_that.createdAt,_that.editedAt,_that.hiddenAt,_that.likeCount,_that.replyCount,_that.openReports,_that.reportCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminCommentRowModel extends AdminCommentRowModel {
  const _AdminCommentRowModel({required this.id, this.body = '', this.author, required this.article, this.parentId, required this.createdAt, this.editedAt, this.hiddenAt, this.likeCount = 0, this.replyCount = 0, this.openReports = 0, this.reportCount = 0}): super._();
  factory _AdminCommentRowModel.fromJson(Map<String, dynamic> json) => _$AdminCommentRowModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String body;
@override final  AuthorModel? author;
@override final  AdminCommentArticleModel article;
@override final  String? parentId;
@override final  DateTime createdAt;
@override final  DateTime? editedAt;
@override final  DateTime? hiddenAt;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int replyCount;
@override@JsonKey() final  int openReports;
@override@JsonKey() final  int reportCount;

/// Create a copy of AdminCommentRowModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminCommentRowModelCopyWith<_AdminCommentRowModel> get copyWith => __$AdminCommentRowModelCopyWithImpl<_AdminCommentRowModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminCommentRowModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminCommentRowModel&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.article, article) || other.article == article)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.hiddenAt, hiddenAt) || other.hiddenAt == hiddenAt)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.openReports, openReports) || other.openReports == openReports)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,body,author,article,parentId,createdAt,editedAt,hiddenAt,likeCount,replyCount,openReports,reportCount);

@override
String toString() {
  return 'AdminCommentRowModel(id: $id, body: $body, author: $author, article: $article, parentId: $parentId, createdAt: $createdAt, editedAt: $editedAt, hiddenAt: $hiddenAt, likeCount: $likeCount, replyCount: $replyCount, openReports: $openReports, reportCount: $reportCount)';
}


}

/// @nodoc
abstract mixin class _$AdminCommentRowModelCopyWith<$Res> implements $AdminCommentRowModelCopyWith<$Res> {
  factory _$AdminCommentRowModelCopyWith(_AdminCommentRowModel value, $Res Function(_AdminCommentRowModel) _then) = __$AdminCommentRowModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String body, AuthorModel? author, AdminCommentArticleModel article, String? parentId, DateTime createdAt, DateTime? editedAt, DateTime? hiddenAt, int likeCount, int replyCount, int openReports, int reportCount
});


@override $AuthorModelCopyWith<$Res>? get author;@override $AdminCommentArticleModelCopyWith<$Res> get article;

}
/// @nodoc
class __$AdminCommentRowModelCopyWithImpl<$Res>
    implements _$AdminCommentRowModelCopyWith<$Res> {
  __$AdminCommentRowModelCopyWithImpl(this._self, this._then);

  final _AdminCommentRowModel _self;
  final $Res Function(_AdminCommentRowModel) _then;

/// Create a copy of AdminCommentRowModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? body = null,Object? author = freezed,Object? article = null,Object? parentId = freezed,Object? createdAt = null,Object? editedAt = freezed,Object? hiddenAt = freezed,Object? likeCount = null,Object? replyCount = null,Object? openReports = null,Object? reportCount = null,}) {
  return _then(_AdminCommentRowModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel?,article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as AdminCommentArticleModel,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hiddenAt: freezed == hiddenAt ? _self.hiddenAt : hiddenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AdminCommentRowModel
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
}/// Create a copy of AdminCommentRowModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminCommentArticleModelCopyWith<$Res> get article {
  
  return $AdminCommentArticleModelCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// @nodoc
mixin _$AdminCommentPageModel {

 List<AdminCommentRowModel> get items; int get page; int get pageSize; int get totalCount; int get totalPages;
/// Create a copy of AdminCommentPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminCommentPageModelCopyWith<AdminCommentPageModel> get copyWith => _$AdminCommentPageModelCopyWithImpl<AdminCommentPageModel>(this as AdminCommentPageModel, _$identity);

  /// Serializes this AdminCommentPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminCommentPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminCommentPageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class $AdminCommentPageModelCopyWith<$Res>  {
  factory $AdminCommentPageModelCopyWith(AdminCommentPageModel value, $Res Function(AdminCommentPageModel) _then) = _$AdminCommentPageModelCopyWithImpl;
@useResult
$Res call({
 List<AdminCommentRowModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class _$AdminCommentPageModelCopyWithImpl<$Res>
    implements $AdminCommentPageModelCopyWith<$Res> {
  _$AdminCommentPageModelCopyWithImpl(this._self, this._then);

  final AdminCommentPageModel _self;
  final $Res Function(AdminCommentPageModel) _then;

/// Create a copy of AdminCommentPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminCommentRowModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminCommentPageModel].
extension AdminCommentPageModelPatterns on AdminCommentPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminCommentPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminCommentPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminCommentPageModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminCommentPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminCommentPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminCommentPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminCommentRowModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminCommentPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminCommentRowModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)  $default,) {final _that = this;
switch (_that) {
case _AdminCommentPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminCommentRowModel> items,  int page,  int pageSize,  int totalCount,  int totalPages)?  $default,) {final _that = this;
switch (_that) {
case _AdminCommentPageModel() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.totalCount,_that.totalPages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminCommentPageModel extends AdminCommentPageModel {
  const _AdminCommentPageModel({final  List<AdminCommentRowModel> items = const <AdminCommentRowModel>[], this.page = 1, this.pageSize = 50, this.totalCount = 0, this.totalPages = 0}): _items = items,super._();
  factory _AdminCommentPageModel.fromJson(Map<String, dynamic> json) => _$AdminCommentPageModelFromJson(json);

 final  List<AdminCommentRowModel> _items;
@override@JsonKey() List<AdminCommentRowModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  int pageSize;
@override@JsonKey() final  int totalCount;
@override@JsonKey() final  int totalPages;

/// Create a copy of AdminCommentPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminCommentPageModelCopyWith<_AdminCommentPageModel> get copyWith => __$AdminCommentPageModelCopyWithImpl<_AdminCommentPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminCommentPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminCommentPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,totalCount,totalPages);

@override
String toString() {
  return 'AdminCommentPageModel(items: $items, page: $page, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class _$AdminCommentPageModelCopyWith<$Res> implements $AdminCommentPageModelCopyWith<$Res> {
  factory _$AdminCommentPageModelCopyWith(_AdminCommentPageModel value, $Res Function(_AdminCommentPageModel) _then) = __$AdminCommentPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminCommentRowModel> items, int page, int pageSize, int totalCount, int totalPages
});




}
/// @nodoc
class __$AdminCommentPageModelCopyWithImpl<$Res>
    implements _$AdminCommentPageModelCopyWith<$Res> {
  __$AdminCommentPageModelCopyWithImpl(this._self, this._then);

  final _AdminCommentPageModel _self;
  final $Res Function(_AdminCommentPageModel) _then;

/// Create a copy of AdminCommentPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? totalCount = null,Object? totalPages = null,}) {
  return _then(_AdminCommentPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminCommentRowModel>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AdminVerificationUserModel {

 String get id; String get displayName; String get username; String? get avatarUrl; bool get isVerified; String? get headline;
/// Create a copy of AdminVerificationUserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminVerificationUserModelCopyWith<AdminVerificationUserModel> get copyWith => _$AdminVerificationUserModelCopyWithImpl<AdminVerificationUserModel>(this as AdminVerificationUserModel, _$identity);

  /// Serializes this AdminVerificationUserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminVerificationUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified,headline);

@override
String toString() {
  return 'AdminVerificationUserModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, headline: $headline)';
}


}

/// @nodoc
abstract mixin class $AdminVerificationUserModelCopyWith<$Res>  {
  factory $AdminVerificationUserModelCopyWith(AdminVerificationUserModel value, $Res Function(AdminVerificationUserModel) _then) = _$AdminVerificationUserModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, String? headline
});




}
/// @nodoc
class _$AdminVerificationUserModelCopyWithImpl<$Res>
    implements $AdminVerificationUserModelCopyWith<$Res> {
  _$AdminVerificationUserModelCopyWithImpl(this._self, this._then);

  final AdminVerificationUserModel _self;
  final $Res Function(AdminVerificationUserModel) _then;

/// Create a copy of AdminVerificationUserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? headline = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminVerificationUserModel].
extension AdminVerificationUserModelPatterns on AdminVerificationUserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminVerificationUserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminVerificationUserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminVerificationUserModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationUserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminVerificationUserModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationUserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? headline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminVerificationUserModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.headline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? headline)  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationUserModel():
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.headline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String username,  String? avatarUrl,  bool isVerified,  String? headline)?  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationUserModel() when $default != null:
return $default(_that.id,_that.displayName,_that.username,_that.avatarUrl,_that.isVerified,_that.headline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminVerificationUserModel extends AdminVerificationUserModel {
  const _AdminVerificationUserModel({required this.id, this.displayName = '', this.username = '', this.avatarUrl, this.isVerified = false, this.headline}): super._();
  factory _AdminVerificationUserModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationUserModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;
@override final  String? headline;

/// Create a copy of AdminVerificationUserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminVerificationUserModelCopyWith<_AdminVerificationUserModel> get copyWith => __$AdminVerificationUserModelCopyWithImpl<_AdminVerificationUserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminVerificationUserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminVerificationUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,username,avatarUrl,isVerified,headline);

@override
String toString() {
  return 'AdminVerificationUserModel(id: $id, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified, headline: $headline)';
}


}

/// @nodoc
abstract mixin class _$AdminVerificationUserModelCopyWith<$Res> implements $AdminVerificationUserModelCopyWith<$Res> {
  factory _$AdminVerificationUserModelCopyWith(_AdminVerificationUserModel value, $Res Function(_AdminVerificationUserModel) _then) = __$AdminVerificationUserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String username, String? avatarUrl, bool isVerified, String? headline
});




}
/// @nodoc
class __$AdminVerificationUserModelCopyWithImpl<$Res>
    implements _$AdminVerificationUserModelCopyWith<$Res> {
  __$AdminVerificationUserModelCopyWithImpl(this._self, this._then);

  final _AdminVerificationUserModel _self;
  final $Res Function(_AdminVerificationUserModel) _then;

/// Create a copy of AdminVerificationUserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? username = null,Object? avatarUrl = freezed,Object? isVerified = null,Object? headline = freezed,}) {
  return _then(_AdminVerificationUserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VerificationProofModel {

 String get fileName; String get contentType; int get sizeBytes;
/// Create a copy of VerificationProofModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationProofModelCopyWith<VerificationProofModel> get copyWith => _$VerificationProofModelCopyWithImpl<VerificationProofModel>(this as VerificationProofModel, _$identity);

  /// Serializes this VerificationProofModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationProofModel&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,contentType,sizeBytes);

@override
String toString() {
  return 'VerificationProofModel(fileName: $fileName, contentType: $contentType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $VerificationProofModelCopyWith<$Res>  {
  factory $VerificationProofModelCopyWith(VerificationProofModel value, $Res Function(VerificationProofModel) _then) = _$VerificationProofModelCopyWithImpl;
@useResult
$Res call({
 String fileName, String contentType, int sizeBytes
});




}
/// @nodoc
class _$VerificationProofModelCopyWithImpl<$Res>
    implements $VerificationProofModelCopyWith<$Res> {
  _$VerificationProofModelCopyWithImpl(this._self, this._then);

  final VerificationProofModel _self;
  final $Res Function(VerificationProofModel) _then;

/// Create a copy of VerificationProofModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? contentType = null,Object? sizeBytes = null,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationProofModel].
extension VerificationProofModelPatterns on VerificationProofModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationProofModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationProofModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationProofModel value)  $default,){
final _that = this;
switch (_that) {
case _VerificationProofModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationProofModel value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationProofModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  String contentType,  int sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationProofModel() when $default != null:
return $default(_that.fileName,_that.contentType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  String contentType,  int sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _VerificationProofModel():
return $default(_that.fileName,_that.contentType,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  String contentType,  int sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _VerificationProofModel() when $default != null:
return $default(_that.fileName,_that.contentType,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationProofModel implements VerificationProofModel {
  const _VerificationProofModel({this.fileName = '', this.contentType = 'application/octet-stream', this.sizeBytes = 0});
  factory _VerificationProofModel.fromJson(Map<String, dynamic> json) => _$VerificationProofModelFromJson(json);

@override@JsonKey() final  String fileName;
@override@JsonKey() final  String contentType;
@override@JsonKey() final  int sizeBytes;

/// Create a copy of VerificationProofModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationProofModelCopyWith<_VerificationProofModel> get copyWith => __$VerificationProofModelCopyWithImpl<_VerificationProofModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationProofModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationProofModel&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,contentType,sizeBytes);

@override
String toString() {
  return 'VerificationProofModel(fileName: $fileName, contentType: $contentType, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$VerificationProofModelCopyWith<$Res> implements $VerificationProofModelCopyWith<$Res> {
  factory _$VerificationProofModelCopyWith(_VerificationProofModel value, $Res Function(_VerificationProofModel) _then) = __$VerificationProofModelCopyWithImpl;
@override @useResult
$Res call({
 String fileName, String contentType, int sizeBytes
});




}
/// @nodoc
class __$VerificationProofModelCopyWithImpl<$Res>
    implements _$VerificationProofModelCopyWith<$Res> {
  __$VerificationProofModelCopyWithImpl(this._self, this._then);

  final _VerificationProofModel _self;
  final $Res Function(_VerificationProofModel) _then;

/// Create a copy of VerificationProofModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? contentType = null,Object? sizeBytes = null,}) {
  return _then(_VerificationProofModel(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$VerificationDeciderModel {

 String get id; String get username;
/// Create a copy of VerificationDeciderModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationDeciderModelCopyWith<VerificationDeciderModel> get copyWith => _$VerificationDeciderModelCopyWithImpl<VerificationDeciderModel>(this as VerificationDeciderModel, _$identity);

  /// Serializes this VerificationDeciderModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationDeciderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username);

@override
String toString() {
  return 'VerificationDeciderModel(id: $id, username: $username)';
}


}

/// @nodoc
abstract mixin class $VerificationDeciderModelCopyWith<$Res>  {
  factory $VerificationDeciderModelCopyWith(VerificationDeciderModel value, $Res Function(VerificationDeciderModel) _then) = _$VerificationDeciderModelCopyWithImpl;
@useResult
$Res call({
 String id, String username
});




}
/// @nodoc
class _$VerificationDeciderModelCopyWithImpl<$Res>
    implements $VerificationDeciderModelCopyWith<$Res> {
  _$VerificationDeciderModelCopyWithImpl(this._self, this._then);

  final VerificationDeciderModel _self;
  final $Res Function(VerificationDeciderModel) _then;

/// Create a copy of VerificationDeciderModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationDeciderModel].
extension VerificationDeciderModelPatterns on VerificationDeciderModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationDeciderModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationDeciderModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationDeciderModel value)  $default,){
final _that = this;
switch (_that) {
case _VerificationDeciderModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationDeciderModel value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationDeciderModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationDeciderModel() when $default != null:
return $default(_that.id,_that.username);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username)  $default,) {final _that = this;
switch (_that) {
case _VerificationDeciderModel():
return $default(_that.id,_that.username);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username)?  $default,) {final _that = this;
switch (_that) {
case _VerificationDeciderModel() when $default != null:
return $default(_that.id,_that.username);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationDeciderModel implements VerificationDeciderModel {
  const _VerificationDeciderModel({required this.id, this.username = ''});
  factory _VerificationDeciderModel.fromJson(Map<String, dynamic> json) => _$VerificationDeciderModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String username;

/// Create a copy of VerificationDeciderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationDeciderModelCopyWith<_VerificationDeciderModel> get copyWith => __$VerificationDeciderModelCopyWithImpl<_VerificationDeciderModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationDeciderModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationDeciderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username);

@override
String toString() {
  return 'VerificationDeciderModel(id: $id, username: $username)';
}


}

/// @nodoc
abstract mixin class _$VerificationDeciderModelCopyWith<$Res> implements $VerificationDeciderModelCopyWith<$Res> {
  factory _$VerificationDeciderModelCopyWith(_VerificationDeciderModel value, $Res Function(_VerificationDeciderModel) _then) = __$VerificationDeciderModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String username
});




}
/// @nodoc
class __$VerificationDeciderModelCopyWithImpl<$Res>
    implements _$VerificationDeciderModelCopyWith<$Res> {
  __$VerificationDeciderModelCopyWithImpl(this._self, this._then);

  final _VerificationDeciderModel _self;
  final $Res Function(_VerificationDeciderModel) _then;

/// Create a copy of VerificationDeciderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,}) {
  return _then(_VerificationDeciderModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AdminVerificationRequestModel {

 String get id; String get status; AdminVerificationUserModel get user; VerificationFieldModel get field; String get jobTitle; String? get proofUrl; VerificationProofModel? get proof; String? get note; DateTime get submittedAt; DateTime? get decidedAt; VerificationDeciderModel? get decidedBy; String? get rejectionReason;
/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminVerificationRequestModelCopyWith<AdminVerificationRequestModel> get copyWith => _$AdminVerificationRequestModelCopyWithImpl<AdminVerificationRequestModel>(this as AdminVerificationRequestModel, _$identity);

  /// Serializes this AdminVerificationRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminVerificationRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.field, field) || other.field == field)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.proofUrl, proofUrl) || other.proofUrl == proofUrl)&&(identical(other.proof, proof) || other.proof == proof)&&(identical(other.note, note) || other.note == note)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,user,field,jobTitle,proofUrl,proof,note,submittedAt,decidedAt,decidedBy,rejectionReason);

@override
String toString() {
  return 'AdminVerificationRequestModel(id: $id, status: $status, user: $user, field: $field, jobTitle: $jobTitle, proofUrl: $proofUrl, proof: $proof, note: $note, submittedAt: $submittedAt, decidedAt: $decidedAt, decidedBy: $decidedBy, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class $AdminVerificationRequestModelCopyWith<$Res>  {
  factory $AdminVerificationRequestModelCopyWith(AdminVerificationRequestModel value, $Res Function(AdminVerificationRequestModel) _then) = _$AdminVerificationRequestModelCopyWithImpl;
@useResult
$Res call({
 String id, String status, AdminVerificationUserModel user, VerificationFieldModel field, String jobTitle, String? proofUrl, VerificationProofModel? proof, String? note, DateTime submittedAt, DateTime? decidedAt, VerificationDeciderModel? decidedBy, String? rejectionReason
});


$AdminVerificationUserModelCopyWith<$Res> get user;$VerificationFieldModelCopyWith<$Res> get field;$VerificationProofModelCopyWith<$Res>? get proof;$VerificationDeciderModelCopyWith<$Res>? get decidedBy;

}
/// @nodoc
class _$AdminVerificationRequestModelCopyWithImpl<$Res>
    implements $AdminVerificationRequestModelCopyWith<$Res> {
  _$AdminVerificationRequestModelCopyWithImpl(this._self, this._then);

  final AdminVerificationRequestModel _self;
  final $Res Function(AdminVerificationRequestModel) _then;

/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? user = null,Object? field = null,Object? jobTitle = null,Object? proofUrl = freezed,Object? proof = freezed,Object? note = freezed,Object? submittedAt = null,Object? decidedAt = freezed,Object? decidedBy = freezed,Object? rejectionReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AdminVerificationUserModel,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as VerificationFieldModel,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,proofUrl: freezed == proofUrl ? _self.proofUrl : proofUrl // ignore: cast_nullable_to_non_nullable
as String?,proof: freezed == proof ? _self.proof : proof // ignore: cast_nullable_to_non_nullable
as VerificationProofModel?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as VerificationDeciderModel?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminVerificationUserModelCopyWith<$Res> get user {
  
  return $AdminVerificationUserModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationFieldModelCopyWith<$Res> get field {
  
  return $VerificationFieldModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationProofModelCopyWith<$Res>? get proof {
    if (_self.proof == null) {
    return null;
  }

  return $VerificationProofModelCopyWith<$Res>(_self.proof!, (value) {
    return _then(_self.copyWith(proof: value));
  });
}/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationDeciderModelCopyWith<$Res>? get decidedBy {
    if (_self.decidedBy == null) {
    return null;
  }

  return $VerificationDeciderModelCopyWith<$Res>(_self.decidedBy!, (value) {
    return _then(_self.copyWith(decidedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminVerificationRequestModel].
extension AdminVerificationRequestModelPatterns on AdminVerificationRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminVerificationRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminVerificationRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminVerificationRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminVerificationRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  AdminVerificationUserModel user,  VerificationFieldModel field,  String jobTitle,  String? proofUrl,  VerificationProofModel? proof,  String? note,  DateTime submittedAt,  DateTime? decidedAt,  VerificationDeciderModel? decidedBy,  String? rejectionReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminVerificationRequestModel() when $default != null:
return $default(_that.id,_that.status,_that.user,_that.field,_that.jobTitle,_that.proofUrl,_that.proof,_that.note,_that.submittedAt,_that.decidedAt,_that.decidedBy,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  AdminVerificationUserModel user,  VerificationFieldModel field,  String jobTitle,  String? proofUrl,  VerificationProofModel? proof,  String? note,  DateTime submittedAt,  DateTime? decidedAt,  VerificationDeciderModel? decidedBy,  String? rejectionReason)  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationRequestModel():
return $default(_that.id,_that.status,_that.user,_that.field,_that.jobTitle,_that.proofUrl,_that.proof,_that.note,_that.submittedAt,_that.decidedAt,_that.decidedBy,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  AdminVerificationUserModel user,  VerificationFieldModel field,  String jobTitle,  String? proofUrl,  VerificationProofModel? proof,  String? note,  DateTime submittedAt,  DateTime? decidedAt,  VerificationDeciderModel? decidedBy,  String? rejectionReason)?  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationRequestModel() when $default != null:
return $default(_that.id,_that.status,_that.user,_that.field,_that.jobTitle,_that.proofUrl,_that.proof,_that.note,_that.submittedAt,_that.decidedAt,_that.decidedBy,_that.rejectionReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminVerificationRequestModel extends AdminVerificationRequestModel {
  const _AdminVerificationRequestModel({required this.id, required this.status, required this.user, required this.field, this.jobTitle = '', this.proofUrl, this.proof, this.note, required this.submittedAt, this.decidedAt, this.decidedBy, this.rejectionReason}): super._();
  factory _AdminVerificationRequestModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationRequestModelFromJson(json);

@override final  String id;
@override final  String status;
@override final  AdminVerificationUserModel user;
@override final  VerificationFieldModel field;
@override@JsonKey() final  String jobTitle;
@override final  String? proofUrl;
@override final  VerificationProofModel? proof;
@override final  String? note;
@override final  DateTime submittedAt;
@override final  DateTime? decidedAt;
@override final  VerificationDeciderModel? decidedBy;
@override final  String? rejectionReason;

/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminVerificationRequestModelCopyWith<_AdminVerificationRequestModel> get copyWith => __$AdminVerificationRequestModelCopyWithImpl<_AdminVerificationRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminVerificationRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminVerificationRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.field, field) || other.field == field)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.proofUrl, proofUrl) || other.proofUrl == proofUrl)&&(identical(other.proof, proof) || other.proof == proof)&&(identical(other.note, note) || other.note == note)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,user,field,jobTitle,proofUrl,proof,note,submittedAt,decidedAt,decidedBy,rejectionReason);

@override
String toString() {
  return 'AdminVerificationRequestModel(id: $id, status: $status, user: $user, field: $field, jobTitle: $jobTitle, proofUrl: $proofUrl, proof: $proof, note: $note, submittedAt: $submittedAt, decidedAt: $decidedAt, decidedBy: $decidedBy, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class _$AdminVerificationRequestModelCopyWith<$Res> implements $AdminVerificationRequestModelCopyWith<$Res> {
  factory _$AdminVerificationRequestModelCopyWith(_AdminVerificationRequestModel value, $Res Function(_AdminVerificationRequestModel) _then) = __$AdminVerificationRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, AdminVerificationUserModel user, VerificationFieldModel field, String jobTitle, String? proofUrl, VerificationProofModel? proof, String? note, DateTime submittedAt, DateTime? decidedAt, VerificationDeciderModel? decidedBy, String? rejectionReason
});


@override $AdminVerificationUserModelCopyWith<$Res> get user;@override $VerificationFieldModelCopyWith<$Res> get field;@override $VerificationProofModelCopyWith<$Res>? get proof;@override $VerificationDeciderModelCopyWith<$Res>? get decidedBy;

}
/// @nodoc
class __$AdminVerificationRequestModelCopyWithImpl<$Res>
    implements _$AdminVerificationRequestModelCopyWith<$Res> {
  __$AdminVerificationRequestModelCopyWithImpl(this._self, this._then);

  final _AdminVerificationRequestModel _self;
  final $Res Function(_AdminVerificationRequestModel) _then;

/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? user = null,Object? field = null,Object? jobTitle = null,Object? proofUrl = freezed,Object? proof = freezed,Object? note = freezed,Object? submittedAt = null,Object? decidedAt = freezed,Object? decidedBy = freezed,Object? rejectionReason = freezed,}) {
  return _then(_AdminVerificationRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AdminVerificationUserModel,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as VerificationFieldModel,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,proofUrl: freezed == proofUrl ? _self.proofUrl : proofUrl // ignore: cast_nullable_to_non_nullable
as String?,proof: freezed == proof ? _self.proof : proof // ignore: cast_nullable_to_non_nullable
as VerificationProofModel?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as VerificationDeciderModel?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminVerificationUserModelCopyWith<$Res> get user {
  
  return $AdminVerificationUserModelCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationFieldModelCopyWith<$Res> get field {
  
  return $VerificationFieldModelCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationProofModelCopyWith<$Res>? get proof {
    if (_self.proof == null) {
    return null;
  }

  return $VerificationProofModelCopyWith<$Res>(_self.proof!, (value) {
    return _then(_self.copyWith(proof: value));
  });
}/// Create a copy of AdminVerificationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationDeciderModelCopyWith<$Res>? get decidedBy {
    if (_self.decidedBy == null) {
    return null;
  }

  return $VerificationDeciderModelCopyWith<$Res>(_self.decidedBy!, (value) {
    return _then(_self.copyWith(decidedBy: value));
  });
}
}


/// @nodoc
mixin _$AdminVerificationPageModel {

 List<AdminVerificationRequestModel> get items; String? get nextCursor;
/// Create a copy of AdminVerificationPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminVerificationPageModelCopyWith<AdminVerificationPageModel> get copyWith => _$AdminVerificationPageModelCopyWithImpl<AdminVerificationPageModel>(this as AdminVerificationPageModel, _$identity);

  /// Serializes this AdminVerificationPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminVerificationPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'AdminVerificationPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $AdminVerificationPageModelCopyWith<$Res>  {
  factory $AdminVerificationPageModelCopyWith(AdminVerificationPageModel value, $Res Function(AdminVerificationPageModel) _then) = _$AdminVerificationPageModelCopyWithImpl;
@useResult
$Res call({
 List<AdminVerificationRequestModel> items, String? nextCursor
});




}
/// @nodoc
class _$AdminVerificationPageModelCopyWithImpl<$Res>
    implements $AdminVerificationPageModelCopyWith<$Res> {
  _$AdminVerificationPageModelCopyWithImpl(this._self, this._then);

  final AdminVerificationPageModel _self;
  final $Res Function(AdminVerificationPageModel) _then;

/// Create a copy of AdminVerificationPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdminVerificationRequestModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminVerificationPageModel].
extension AdminVerificationPageModelPatterns on AdminVerificationPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminVerificationPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminVerificationPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminVerificationPageModel value)  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminVerificationPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdminVerificationPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdminVerificationRequestModel> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminVerificationPageModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdminVerificationRequestModel> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationPageModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdminVerificationRequestModel> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _AdminVerificationPageModel() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminVerificationPageModel implements AdminVerificationPageModel {
  const _AdminVerificationPageModel({final  List<AdminVerificationRequestModel> items = const <AdminVerificationRequestModel>[], this.nextCursor}): _items = items;
  factory _AdminVerificationPageModel.fromJson(Map<String, dynamic> json) => _$AdminVerificationPageModelFromJson(json);

 final  List<AdminVerificationRequestModel> _items;
@override@JsonKey() List<AdminVerificationRequestModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of AdminVerificationPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminVerificationPageModelCopyWith<_AdminVerificationPageModel> get copyWith => __$AdminVerificationPageModelCopyWithImpl<_AdminVerificationPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminVerificationPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminVerificationPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'AdminVerificationPageModel(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$AdminVerificationPageModelCopyWith<$Res> implements $AdminVerificationPageModelCopyWith<$Res> {
  factory _$AdminVerificationPageModelCopyWith(_AdminVerificationPageModel value, $Res Function(_AdminVerificationPageModel) _then) = __$AdminVerificationPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdminVerificationRequestModel> items, String? nextCursor
});




}
/// @nodoc
class __$AdminVerificationPageModelCopyWithImpl<$Res>
    implements _$AdminVerificationPageModelCopyWith<$Res> {
  __$AdminVerificationPageModelCopyWithImpl(this._self, this._then);

  final _AdminVerificationPageModel _self;
  final $Res Function(_AdminVerificationPageModel) _then;

/// Create a copy of AdminVerificationPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_AdminVerificationPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdminVerificationRequestModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RejectVerificationRequest {

 String get reason;
/// Create a copy of RejectVerificationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RejectVerificationRequestCopyWith<RejectVerificationRequest> get copyWith => _$RejectVerificationRequestCopyWithImpl<RejectVerificationRequest>(this as RejectVerificationRequest, _$identity);

  /// Serializes this RejectVerificationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RejectVerificationRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'RejectVerificationRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $RejectVerificationRequestCopyWith<$Res>  {
  factory $RejectVerificationRequestCopyWith(RejectVerificationRequest value, $Res Function(RejectVerificationRequest) _then) = _$RejectVerificationRequestCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$RejectVerificationRequestCopyWithImpl<$Res>
    implements $RejectVerificationRequestCopyWith<$Res> {
  _$RejectVerificationRequestCopyWithImpl(this._self, this._then);

  final RejectVerificationRequest _self;
  final $Res Function(RejectVerificationRequest) _then;

/// Create a copy of RejectVerificationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RejectVerificationRequest].
extension RejectVerificationRequestPatterns on RejectVerificationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RejectVerificationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RejectVerificationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RejectVerificationRequest value)  $default,){
final _that = this;
switch (_that) {
case _RejectVerificationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RejectVerificationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RejectVerificationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RejectVerificationRequest() when $default != null:
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reason)  $default,) {final _that = this;
switch (_that) {
case _RejectVerificationRequest():
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reason)?  $default,) {final _that = this;
switch (_that) {
case _RejectVerificationRequest() when $default != null:
return $default(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RejectVerificationRequest implements RejectVerificationRequest {
  const _RejectVerificationRequest({required this.reason});
  factory _RejectVerificationRequest.fromJson(Map<String, dynamic> json) => _$RejectVerificationRequestFromJson(json);

@override final  String reason;

/// Create a copy of RejectVerificationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RejectVerificationRequestCopyWith<_RejectVerificationRequest> get copyWith => __$RejectVerificationRequestCopyWithImpl<_RejectVerificationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RejectVerificationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RejectVerificationRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'RejectVerificationRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$RejectVerificationRequestCopyWith<$Res> implements $RejectVerificationRequestCopyWith<$Res> {
  factory _$RejectVerificationRequestCopyWith(_RejectVerificationRequest value, $Res Function(_RejectVerificationRequest) _then) = __$RejectVerificationRequestCopyWithImpl;
@override @useResult
$Res call({
 String reason
});




}
/// @nodoc
class __$RejectVerificationRequestCopyWithImpl<$Res>
    implements _$RejectVerificationRequestCopyWith<$Res> {
  __$RejectVerificationRequestCopyWithImpl(this._self, this._then);

  final _RejectVerificationRequest _self;
  final $Res Function(_RejectVerificationRequest) _then;

/// Create a copy of RejectVerificationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(_RejectVerificationRequest(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
