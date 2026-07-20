// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_application_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobApplicationDto _$JobApplicationDtoFromJson(Map<String, dynamic> json) =>
    _JobApplicationDto(
      applicantId: json['applicantId'] as String,
      jobListingId: json['jobListingId'] as String,
      jobTitle: json['jobTitle'] as String,
      companyName: json['companyName'] as String,
      submittedAt: json['submittedAt'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$JobApplicationDtoToJson(_JobApplicationDto instance) =>
    <String, dynamic>{
      'applicantId': instance.applicantId,
      'jobListingId': instance.jobListingId,
      'jobTitle': instance.jobTitle,
      'companyName': instance.companyName,
      'submittedAt': instance.submittedAt,
      'status': instance.status,
    };
