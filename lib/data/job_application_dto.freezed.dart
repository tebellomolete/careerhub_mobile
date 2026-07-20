// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_application_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobApplicationDto {

/// Guid → String, verbatim, as with `JobDto.id`.
 String get applicantId;/// Guid → String, the listing this application was submitted against.
 String get jobListingId;/// Denormalised at the API layer so the client renders a card without
/// a second HTTP call. Backend key: `jobTitle`.
 String get jobTitle;/// Denormalised at the API layer. Backend key: `companyName`.
 String get companyName;/// ISO-8601 date-time string. Kept as `String` on the DTO — parsing
/// to `DateTime` is a modelling decision that belongs on the way
/// OUT via `JobApplication.fromDto`.
 String get submittedAt;/// Serialised via `JsonStringEnumConverter` on the API side, so this
/// arrives as one of `Submitted`, `UnderReview`, `Interviewing`,
/// `Offered`, `Hired`, `Rejected`. The DTO holds the raw string;
/// the domain layer maps it to an `ApplicationStatus` enum value.
 String get status;
/// Create a copy of JobApplicationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobApplicationDtoCopyWith<JobApplicationDto> get copyWith => _$JobApplicationDtoCopyWithImpl<JobApplicationDto>(this as JobApplicationDto, _$identity);

  /// Serializes this JobApplicationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobApplicationDto&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.jobListingId, jobListingId) || other.jobListingId == jobListingId)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,applicantId,jobListingId,jobTitle,companyName,submittedAt,status);

@override
String toString() {
  return 'JobApplicationDto(applicantId: $applicantId, jobListingId: $jobListingId, jobTitle: $jobTitle, companyName: $companyName, submittedAt: $submittedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $JobApplicationDtoCopyWith<$Res>  {
  factory $JobApplicationDtoCopyWith(JobApplicationDto value, $Res Function(JobApplicationDto) _then) = _$JobApplicationDtoCopyWithImpl;
@useResult
$Res call({
 String applicantId, String jobListingId, String jobTitle, String companyName, String submittedAt, String status
});




}
/// @nodoc
class _$JobApplicationDtoCopyWithImpl<$Res>
    implements $JobApplicationDtoCopyWith<$Res> {
  _$JobApplicationDtoCopyWithImpl(this._self, this._then);

  final JobApplicationDto _self;
  final $Res Function(JobApplicationDto) _then;

/// Create a copy of JobApplicationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? applicantId = null,Object? jobListingId = null,Object? jobTitle = null,Object? companyName = null,Object? submittedAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,jobListingId: null == jobListingId ? _self.jobListingId : jobListingId // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JobApplicationDto].
extension JobApplicationDtoPatterns on JobApplicationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobApplicationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobApplicationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobApplicationDto value)  $default,){
final _that = this;
switch (_that) {
case _JobApplicationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobApplicationDto value)?  $default,){
final _that = this;
switch (_that) {
case _JobApplicationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String applicantId,  String jobListingId,  String jobTitle,  String companyName,  String submittedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobApplicationDto() when $default != null:
return $default(_that.applicantId,_that.jobListingId,_that.jobTitle,_that.companyName,_that.submittedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String applicantId,  String jobListingId,  String jobTitle,  String companyName,  String submittedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _JobApplicationDto():
return $default(_that.applicantId,_that.jobListingId,_that.jobTitle,_that.companyName,_that.submittedAt,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String applicantId,  String jobListingId,  String jobTitle,  String companyName,  String submittedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _JobApplicationDto() when $default != null:
return $default(_that.applicantId,_that.jobListingId,_that.jobTitle,_that.companyName,_that.submittedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobApplicationDto implements JobApplicationDto {
  const _JobApplicationDto({required this.applicantId, required this.jobListingId, required this.jobTitle, required this.companyName, required this.submittedAt, required this.status});
  factory _JobApplicationDto.fromJson(Map<String, dynamic> json) => _$JobApplicationDtoFromJson(json);

/// Guid → String, verbatim, as with `JobDto.id`.
@override final  String applicantId;
/// Guid → String, the listing this application was submitted against.
@override final  String jobListingId;
/// Denormalised at the API layer so the client renders a card without
/// a second HTTP call. Backend key: `jobTitle`.
@override final  String jobTitle;
/// Denormalised at the API layer. Backend key: `companyName`.
@override final  String companyName;
/// ISO-8601 date-time string. Kept as `String` on the DTO — parsing
/// to `DateTime` is a modelling decision that belongs on the way
/// OUT via `JobApplication.fromDto`.
@override final  String submittedAt;
/// Serialised via `JsonStringEnumConverter` on the API side, so this
/// arrives as one of `Submitted`, `UnderReview`, `Interviewing`,
/// `Offered`, `Hired`, `Rejected`. The DTO holds the raw string;
/// the domain layer maps it to an `ApplicationStatus` enum value.
@override final  String status;

/// Create a copy of JobApplicationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobApplicationDtoCopyWith<_JobApplicationDto> get copyWith => __$JobApplicationDtoCopyWithImpl<_JobApplicationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobApplicationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobApplicationDto&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.jobListingId, jobListingId) || other.jobListingId == jobListingId)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,applicantId,jobListingId,jobTitle,companyName,submittedAt,status);

@override
String toString() {
  return 'JobApplicationDto(applicantId: $applicantId, jobListingId: $jobListingId, jobTitle: $jobTitle, companyName: $companyName, submittedAt: $submittedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$JobApplicationDtoCopyWith<$Res> implements $JobApplicationDtoCopyWith<$Res> {
  factory _$JobApplicationDtoCopyWith(_JobApplicationDto value, $Res Function(_JobApplicationDto) _then) = __$JobApplicationDtoCopyWithImpl;
@override @useResult
$Res call({
 String applicantId, String jobListingId, String jobTitle, String companyName, String submittedAt, String status
});




}
/// @nodoc
class __$JobApplicationDtoCopyWithImpl<$Res>
    implements _$JobApplicationDtoCopyWith<$Res> {
  __$JobApplicationDtoCopyWithImpl(this._self, this._then);

  final _JobApplicationDto _self;
  final $Res Function(_JobApplicationDto) _then;

/// Create a copy of JobApplicationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? applicantId = null,Object? jobListingId = null,Object? jobTitle = null,Object? companyName = null,Object? submittedAt = null,Object? status = null,}) {
  return _then(_JobApplicationDto(
applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,jobListingId: null == jobListingId ? _self.jobListingId : jobListingId // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
