// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobDto {

/// The API's primary key is a `Guid`, serialised as a lowercase-hex
/// string like `"6e8d9f34-..."`. It travels through the app as a
/// `String` and is used verbatim as the URL path segment for
/// `/jobs/:id`. The JSON key is `id`, which matches the Dart field
/// name — no `@JsonKey(name: ...)` needed.
 String get id; String get title;/// API JSON key: `companyName`. Flutter's `Job` model calls this
/// `company` — the rename lives in `Job.fromDto`, not here.
/// The Dart field name and JSON key already match, so no
/// `@JsonKey(name: ...)` override is required. See README 2.2, Q2.
 String get companyName; String get location;/// The API returns a description string on the list endpoint too, so
/// we can capture it eagerly rather than making a second call per card.
/// `@Default('')` reproduces the previous hand-written tolerance
/// for a missing `description` key: Freezed forwards the default
/// through both `JobDto()` construction AND
/// `json_serializable`'s generated `fromJson`, so a missing key
/// yields `''` instead of a runtime type error.
 String get description;/// The API's `JobType` enum comes over as a Pascal-cased String
/// (`"FullTime"`, `"PartTime"`, `"Contract"`, `"Internship"`) thanks
/// to `JsonStringEnumConverter` in `Program.cs`. Kept as the raw
/// string here; the Flutter-friendly re-hyphenation ("Full-time")
/// is a concern of `Job.fromDto`.
 String get type;/// ISO-8601 date-time. Kept as `String` on the DTO because the DTO's
/// only job is to mirror the wire shape faithfully — parsing to
/// `DateTime` is a modelling decision that belongs on the way OUT of
/// the DTO, not here.
 String get postedAt;/// A pre-formatted display string. When the employer omitted salary
/// entirely the API sends the literal `"Salary not specified"` (see
/// `JobResponse.FromListing`). The Flutter model prefers `null` for
/// that case so `Job.displaySalary` can render "Market-related";
/// that translation happens in `Job.fromDto`.
 String get salaryDisplay;/// Not currently rendered by any Flutter widget — captured anyway so
/// the DTO stays a complete mirror of the API. `@Default(0)` keeps
/// this tolerant of an older API build that omitted the key.
 int get applicationCount;
/// Create a copy of JobDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobDtoCopyWith<JobDto> get copyWith => _$JobDtoCopyWithImpl<JobDto>(this as JobDto, _$identity);

  /// Serializes this JobDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.postedAt, postedAt) || other.postedAt == postedAt)&&(identical(other.salaryDisplay, salaryDisplay) || other.salaryDisplay == salaryDisplay)&&(identical(other.applicationCount, applicationCount) || other.applicationCount == applicationCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,companyName,location,description,type,postedAt,salaryDisplay,applicationCount);

@override
String toString() {
  return 'JobDto(id: $id, title: $title, companyName: $companyName, location: $location, description: $description, type: $type, postedAt: $postedAt, salaryDisplay: $salaryDisplay, applicationCount: $applicationCount)';
}


}

/// @nodoc
abstract mixin class $JobDtoCopyWith<$Res>  {
  factory $JobDtoCopyWith(JobDto value, $Res Function(JobDto) _then) = _$JobDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String companyName, String location, String description, String type, String postedAt, String salaryDisplay, int applicationCount
});




}
/// @nodoc
class _$JobDtoCopyWithImpl<$Res>
    implements $JobDtoCopyWith<$Res> {
  _$JobDtoCopyWithImpl(this._self, this._then);

  final JobDto _self;
  final $Res Function(JobDto) _then;

/// Create a copy of JobDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? companyName = null,Object? location = null,Object? description = null,Object? type = null,Object? postedAt = null,Object? salaryDisplay = null,Object? applicationCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,postedAt: null == postedAt ? _self.postedAt : postedAt // ignore: cast_nullable_to_non_nullable
as String,salaryDisplay: null == salaryDisplay ? _self.salaryDisplay : salaryDisplay // ignore: cast_nullable_to_non_nullable
as String,applicationCount: null == applicationCount ? _self.applicationCount : applicationCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JobDto].
extension JobDtoPatterns on JobDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobDto value)  $default,){
final _that = this;
switch (_that) {
case _JobDto():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobDto value)?  $default,){
final _that = this;
switch (_that) {
case _JobDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String companyName,  String location,  String description,  String type,  String postedAt,  String salaryDisplay,  int applicationCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobDto() when $default != null:
return $default(_that.id,_that.title,_that.companyName,_that.location,_that.description,_that.type,_that.postedAt,_that.salaryDisplay,_that.applicationCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String companyName,  String location,  String description,  String type,  String postedAt,  String salaryDisplay,  int applicationCount)  $default,) {final _that = this;
switch (_that) {
case _JobDto():
return $default(_that.id,_that.title,_that.companyName,_that.location,_that.description,_that.type,_that.postedAt,_that.salaryDisplay,_that.applicationCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String companyName,  String location,  String description,  String type,  String postedAt,  String salaryDisplay,  int applicationCount)?  $default,) {final _that = this;
switch (_that) {
case _JobDto() when $default != null:
return $default(_that.id,_that.title,_that.companyName,_that.location,_that.description,_that.type,_that.postedAt,_that.salaryDisplay,_that.applicationCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobDto implements JobDto {
  const _JobDto({required this.id, required this.title, required this.companyName, required this.location, this.description = '', required this.type, required this.postedAt, required this.salaryDisplay, this.applicationCount = 0});
  factory _JobDto.fromJson(Map<String, dynamic> json) => _$JobDtoFromJson(json);

/// The API's primary key is a `Guid`, serialised as a lowercase-hex
/// string like `"6e8d9f34-..."`. It travels through the app as a
/// `String` and is used verbatim as the URL path segment for
/// `/jobs/:id`. The JSON key is `id`, which matches the Dart field
/// name — no `@JsonKey(name: ...)` needed.
@override final  String id;
@override final  String title;
/// API JSON key: `companyName`. Flutter's `Job` model calls this
/// `company` — the rename lives in `Job.fromDto`, not here.
/// The Dart field name and JSON key already match, so no
/// `@JsonKey(name: ...)` override is required. See README 2.2, Q2.
@override final  String companyName;
@override final  String location;
/// The API returns a description string on the list endpoint too, so
/// we can capture it eagerly rather than making a second call per card.
/// `@Default('')` reproduces the previous hand-written tolerance
/// for a missing `description` key: Freezed forwards the default
/// through both `JobDto()` construction AND
/// `json_serializable`'s generated `fromJson`, so a missing key
/// yields `''` instead of a runtime type error.
@override@JsonKey() final  String description;
/// The API's `JobType` enum comes over as a Pascal-cased String
/// (`"FullTime"`, `"PartTime"`, `"Contract"`, `"Internship"`) thanks
/// to `JsonStringEnumConverter` in `Program.cs`. Kept as the raw
/// string here; the Flutter-friendly re-hyphenation ("Full-time")
/// is a concern of `Job.fromDto`.
@override final  String type;
/// ISO-8601 date-time. Kept as `String` on the DTO because the DTO's
/// only job is to mirror the wire shape faithfully — parsing to
/// `DateTime` is a modelling decision that belongs on the way OUT of
/// the DTO, not here.
@override final  String postedAt;
/// A pre-formatted display string. When the employer omitted salary
/// entirely the API sends the literal `"Salary not specified"` (see
/// `JobResponse.FromListing`). The Flutter model prefers `null` for
/// that case so `Job.displaySalary` can render "Market-related";
/// that translation happens in `Job.fromDto`.
@override final  String salaryDisplay;
/// Not currently rendered by any Flutter widget — captured anyway so
/// the DTO stays a complete mirror of the API. `@Default(0)` keeps
/// this tolerant of an older API build that omitted the key.
@override@JsonKey() final  int applicationCount;

/// Create a copy of JobDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobDtoCopyWith<_JobDto> get copyWith => __$JobDtoCopyWithImpl<_JobDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.postedAt, postedAt) || other.postedAt == postedAt)&&(identical(other.salaryDisplay, salaryDisplay) || other.salaryDisplay == salaryDisplay)&&(identical(other.applicationCount, applicationCount) || other.applicationCount == applicationCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,companyName,location,description,type,postedAt,salaryDisplay,applicationCount);

@override
String toString() {
  return 'JobDto(id: $id, title: $title, companyName: $companyName, location: $location, description: $description, type: $type, postedAt: $postedAt, salaryDisplay: $salaryDisplay, applicationCount: $applicationCount)';
}


}

/// @nodoc
abstract mixin class _$JobDtoCopyWith<$Res> implements $JobDtoCopyWith<$Res> {
  factory _$JobDtoCopyWith(_JobDto value, $Res Function(_JobDto) _then) = __$JobDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String companyName, String location, String description, String type, String postedAt, String salaryDisplay, int applicationCount
});




}
/// @nodoc
class __$JobDtoCopyWithImpl<$Res>
    implements _$JobDtoCopyWith<$Res> {
  __$JobDtoCopyWithImpl(this._self, this._then);

  final _JobDto _self;
  final $Res Function(_JobDto) _then;

/// Create a copy of JobDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? companyName = null,Object? location = null,Object? description = null,Object? type = null,Object? postedAt = null,Object? salaryDisplay = null,Object? applicationCount = null,}) {
  return _then(_JobDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,postedAt: null == postedAt ? _self.postedAt : postedAt // ignore: cast_nullable_to_non_nullable
as String,salaryDisplay: null == salaryDisplay ? _self.salaryDisplay : salaryDisplay // ignore: cast_nullable_to_non_nullable
as String,applicationCount: null == applicationCount ? _self.applicationCount : applicationCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
