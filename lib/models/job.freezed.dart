// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Job {

/// A stable, unique identifier for this listing. Assignment 2.1
/// changed this from `int` to `String` because the CareerHub API's
/// primary key is a `Guid`. Every URL like `/jobs/<guid>` keys on
/// this string verbatim — never a list index.
 String get id; String get title; String get company;/// Every role is performed somewhere (including "Remote"), so a
/// seeker always needs a location to judge fit. Required.
 String get location;/// The physical work arrangement — on-site, remote, or hybrid.
/// The CareerHub API has no dedicated `locationType` column, so
/// `Job.fromDto` derives this via [inferLocationType].
 LocationType get locationType;/// An employer may choose not to disclose salary. When the API
/// returns the sentinel `"Salary not specified"`, `Job.fromDto`
/// maps that to `null` here so `displaySalary` can render
/// "Market-related".
 String? get salary;/// The employer-friendly string, e.g. "Full-time" or "Part-time".
/// `Job.fromDto` re-hyphenates the API's Pascal-cased enum string
/// via `_typeStringFromApi`.
 String get employmentType;/// Not in the list-endpoint response — the API's `JobResponse`
/// doesn't currently expose `ClosingDate`. Left `null` for
/// API-sourced jobs.
 DateTime? get closingDate;/// A short summary of the role. The API's list endpoint returns
/// a non-null (possibly empty) description; empty strings pass
/// straight through, and the detail widget already handles them.
 String? get description;/// The API's list endpoint only ever returns ACTIVE listings, so
/// every job coming from `Job.fromDto` is `isOpen = true`. The
/// field is retained so hand-constructed fixtures in tests can
/// still model a closed job.
 bool get isOpen;/// Stretch B — a UI-only field.
///
/// Never populated by `Job.fromDto` because the API doesn't send
/// it: `@Default('')` supplies the value at CONSTRUCTION time when
/// the caller omits the argument, which `fromDto` always does. The
/// job detail screen produces an EDITED `Job` via
/// `original.copyWith(userNote: text)` and stores it in a
/// `StateProvider<Job?>` (see `editedJobProvider` in
/// `lib/providers/job_providers.dart`) — the original `Job` in the
/// list is never mutated.
///
/// Contrast with hand-writing `String userNote = ''` on a plain
/// class constructor: `@Default` places the fallback INSIDE the
/// Freezed factory's generated implementation, so the value is
/// applied uniformly whether you build a `Job` directly, through
/// `copyWith`, or via any future variant. See README 2.2, Stretch B.
 String get userNote;
/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobCopyWith<Job> get copyWith => _$JobCopyWithImpl<Job>(this as Job, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Job&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.company, company) || other.company == company)&&(identical(other.location, location) || other.location == location)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.closingDate, closingDate) || other.closingDate == closingDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.userNote, userNote) || other.userNote == userNote));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,company,location,locationType,salary,employmentType,closingDate,description,isOpen,userNote);

@override
String toString() {
  return 'Job(id: $id, title: $title, company: $company, location: $location, locationType: $locationType, salary: $salary, employmentType: $employmentType, closingDate: $closingDate, description: $description, isOpen: $isOpen, userNote: $userNote)';
}


}

/// @nodoc
abstract mixin class $JobCopyWith<$Res>  {
  factory $JobCopyWith(Job value, $Res Function(Job) _then) = _$JobCopyWithImpl;
@useResult
$Res call({
 String id, String title, String company, String location, LocationType locationType, String? salary, String employmentType, DateTime? closingDate, String? description, bool isOpen, String userNote
});




}
/// @nodoc
class _$JobCopyWithImpl<$Res>
    implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._self, this._then);

  final Job _self;
  final $Res Function(Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? company = null,Object? location = null,Object? locationType = null,Object? salary = freezed,Object? employmentType = null,Object? closingDate = freezed,Object? description = freezed,Object? isOpen = null,Object? userNote = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,company: null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as LocationType,salary: freezed == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String?,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String,closingDate: freezed == closingDate ? _self.closingDate : closingDate // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,userNote: null == userNote ? _self.userNote : userNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Job].
extension JobPatterns on Job {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Job value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Job value)  $default,){
final _that = this;
switch (_that) {
case _Job():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Job value)?  $default,){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String company,  String location,  LocationType locationType,  String? salary,  String employmentType,  DateTime? closingDate,  String? description,  bool isOpen,  String userNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.title,_that.company,_that.location,_that.locationType,_that.salary,_that.employmentType,_that.closingDate,_that.description,_that.isOpen,_that.userNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String company,  String location,  LocationType locationType,  String? salary,  String employmentType,  DateTime? closingDate,  String? description,  bool isOpen,  String userNote)  $default,) {final _that = this;
switch (_that) {
case _Job():
return $default(_that.id,_that.title,_that.company,_that.location,_that.locationType,_that.salary,_that.employmentType,_that.closingDate,_that.description,_that.isOpen,_that.userNote);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String company,  String location,  LocationType locationType,  String? salary,  String employmentType,  DateTime? closingDate,  String? description,  bool isOpen,  String userNote)?  $default,) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.id,_that.title,_that.company,_that.location,_that.locationType,_that.salary,_that.employmentType,_that.closingDate,_that.description,_that.isOpen,_that.userNote);case _:
  return null;

}
}

}

/// @nodoc


class _Job extends Job {
  const _Job({required this.id, required this.title, required this.company, required this.location, required this.locationType, this.salary, required this.employmentType, this.closingDate, this.description, this.isOpen = true, this.userNote = ''}): super._();
  

/// A stable, unique identifier for this listing. Assignment 2.1
/// changed this from `int` to `String` because the CareerHub API's
/// primary key is a `Guid`. Every URL like `/jobs/<guid>` keys on
/// this string verbatim — never a list index.
@override final  String id;
@override final  String title;
@override final  String company;
/// Every role is performed somewhere (including "Remote"), so a
/// seeker always needs a location to judge fit. Required.
@override final  String location;
/// The physical work arrangement — on-site, remote, or hybrid.
/// The CareerHub API has no dedicated `locationType` column, so
/// `Job.fromDto` derives this via [inferLocationType].
@override final  LocationType locationType;
/// An employer may choose not to disclose salary. When the API
/// returns the sentinel `"Salary not specified"`, `Job.fromDto`
/// maps that to `null` here so `displaySalary` can render
/// "Market-related".
@override final  String? salary;
/// The employer-friendly string, e.g. "Full-time" or "Part-time".
/// `Job.fromDto` re-hyphenates the API's Pascal-cased enum string
/// via `_typeStringFromApi`.
@override final  String employmentType;
/// Not in the list-endpoint response — the API's `JobResponse`
/// doesn't currently expose `ClosingDate`. Left `null` for
/// API-sourced jobs.
@override final  DateTime? closingDate;
/// A short summary of the role. The API's list endpoint returns
/// a non-null (possibly empty) description; empty strings pass
/// straight through, and the detail widget already handles them.
@override final  String? description;
/// The API's list endpoint only ever returns ACTIVE listings, so
/// every job coming from `Job.fromDto` is `isOpen = true`. The
/// field is retained so hand-constructed fixtures in tests can
/// still model a closed job.
@override@JsonKey() final  bool isOpen;
/// Stretch B — a UI-only field.
///
/// Never populated by `Job.fromDto` because the API doesn't send
/// it: `@Default('')` supplies the value at CONSTRUCTION time when
/// the caller omits the argument, which `fromDto` always does. The
/// job detail screen produces an EDITED `Job` via
/// `original.copyWith(userNote: text)` and stores it in a
/// `StateProvider<Job?>` (see `editedJobProvider` in
/// `lib/providers/job_providers.dart`) — the original `Job` in the
/// list is never mutated.
///
/// Contrast with hand-writing `String userNote = ''` on a plain
/// class constructor: `@Default` places the fallback INSIDE the
/// Freezed factory's generated implementation, so the value is
/// applied uniformly whether you build a `Job` directly, through
/// `copyWith`, or via any future variant. See README 2.2, Stretch B.
@override@JsonKey() final  String userNote;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobCopyWith<_Job> get copyWith => __$JobCopyWithImpl<_Job>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Job&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.company, company) || other.company == company)&&(identical(other.location, location) || other.location == location)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.closingDate, closingDate) || other.closingDate == closingDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.userNote, userNote) || other.userNote == userNote));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,company,location,locationType,salary,employmentType,closingDate,description,isOpen,userNote);

@override
String toString() {
  return 'Job(id: $id, title: $title, company: $company, location: $location, locationType: $locationType, salary: $salary, employmentType: $employmentType, closingDate: $closingDate, description: $description, isOpen: $isOpen, userNote: $userNote)';
}


}

/// @nodoc
abstract mixin class _$JobCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$JobCopyWith(_Job value, $Res Function(_Job) _then) = __$JobCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String company, String location, LocationType locationType, String? salary, String employmentType, DateTime? closingDate, String? description, bool isOpen, String userNote
});




}
/// @nodoc
class __$JobCopyWithImpl<$Res>
    implements _$JobCopyWith<$Res> {
  __$JobCopyWithImpl(this._self, this._then);

  final _Job _self;
  final $Res Function(_Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? company = null,Object? location = null,Object? locationType = null,Object? salary = freezed,Object? employmentType = null,Object? closingDate = freezed,Object? description = freezed,Object? isOpen = null,Object? userNote = null,}) {
  return _then(_Job(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,company: null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as LocationType,salary: freezed == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String?,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as String,closingDate: freezed == closingDate ? _self.closingDate : closingDate // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,userNote: null == userNote ? _self.userNote : userNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
