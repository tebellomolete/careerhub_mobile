// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JobApplication {

 String get id; String get applicantId; String get jobListingId; String get jobTitle; String get companyName; DateTime get submittedAt; ApplicationStatus get status;
/// Create a copy of JobApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobApplicationCopyWith<JobApplication> get copyWith => _$JobApplicationCopyWithImpl<JobApplication>(this as JobApplication, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.jobListingId, jobListingId) || other.jobListingId == jobListingId)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,applicantId,jobListingId,jobTitle,companyName,submittedAt,status);

@override
String toString() {
  return 'JobApplication(id: $id, applicantId: $applicantId, jobListingId: $jobListingId, jobTitle: $jobTitle, companyName: $companyName, submittedAt: $submittedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $JobApplicationCopyWith<$Res>  {
  factory $JobApplicationCopyWith(JobApplication value, $Res Function(JobApplication) _then) = _$JobApplicationCopyWithImpl;
@useResult
$Res call({
 String id, String applicantId, String jobListingId, String jobTitle, String companyName, DateTime submittedAt, ApplicationStatus status
});




}
/// @nodoc
class _$JobApplicationCopyWithImpl<$Res>
    implements $JobApplicationCopyWith<$Res> {
  _$JobApplicationCopyWithImpl(this._self, this._then);

  final JobApplication _self;
  final $Res Function(JobApplication) _then;

/// Create a copy of JobApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? applicantId = null,Object? jobListingId = null,Object? jobTitle = null,Object? companyName = null,Object? submittedAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,jobListingId: null == jobListingId ? _self.jobListingId : jobListingId // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [JobApplication].
extension JobApplicationPatterns on JobApplication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobApplication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobApplication value)  $default,){
final _that = this;
switch (_that) {
case _JobApplication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobApplication value)?  $default,){
final _that = this;
switch (_that) {
case _JobApplication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String applicantId,  String jobListingId,  String jobTitle,  String companyName,  DateTime submittedAt,  ApplicationStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobApplication() when $default != null:
return $default(_that.id,_that.applicantId,_that.jobListingId,_that.jobTitle,_that.companyName,_that.submittedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String applicantId,  String jobListingId,  String jobTitle,  String companyName,  DateTime submittedAt,  ApplicationStatus status)  $default,) {final _that = this;
switch (_that) {
case _JobApplication():
return $default(_that.id,_that.applicantId,_that.jobListingId,_that.jobTitle,_that.companyName,_that.submittedAt,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String applicantId,  String jobListingId,  String jobTitle,  String companyName,  DateTime submittedAt,  ApplicationStatus status)?  $default,) {final _that = this;
switch (_that) {
case _JobApplication() when $default != null:
return $default(_that.id,_that.applicantId,_that.jobListingId,_that.jobTitle,_that.companyName,_that.submittedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _JobApplication extends JobApplication {
  const _JobApplication({required this.id, required this.applicantId, required this.jobListingId, required this.jobTitle, required this.companyName, required this.submittedAt, required this.status}): super._();
  

@override final  String id;
@override final  String applicantId;
@override final  String jobListingId;
@override final  String jobTitle;
@override final  String companyName;
@override final  DateTime submittedAt;
@override final  ApplicationStatus status;

/// Create a copy of JobApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobApplicationCopyWith<_JobApplication> get copyWith => __$JobApplicationCopyWithImpl<_JobApplication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.jobListingId, jobListingId) || other.jobListingId == jobListingId)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,applicantId,jobListingId,jobTitle,companyName,submittedAt,status);

@override
String toString() {
  return 'JobApplication(id: $id, applicantId: $applicantId, jobListingId: $jobListingId, jobTitle: $jobTitle, companyName: $companyName, submittedAt: $submittedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$JobApplicationCopyWith<$Res> implements $JobApplicationCopyWith<$Res> {
  factory _$JobApplicationCopyWith(_JobApplication value, $Res Function(_JobApplication) _then) = __$JobApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String applicantId, String jobListingId, String jobTitle, String companyName, DateTime submittedAt, ApplicationStatus status
});




}
/// @nodoc
class __$JobApplicationCopyWithImpl<$Res>
    implements _$JobApplicationCopyWith<$Res> {
  __$JobApplicationCopyWithImpl(this._self, this._then);

  final _JobApplication _self;
  final $Res Function(_JobApplication) _then;

/// Create a copy of JobApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? applicantId = null,Object? jobListingId = null,Object? jobTitle = null,Object? companyName = null,Object? submittedAt = null,Object? status = null,}) {
  return _then(_JobApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,jobListingId: null == jobListingId ? _self.jobListingId : jobListingId // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,
  ));
}


}

// dart format on
