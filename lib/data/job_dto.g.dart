// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobDto _$JobDtoFromJson(Map<String, dynamic> json) => _JobDto(
  id: json['id'] as String,
  title: json['title'] as String,
  companyName: json['companyName'] as String,
  location: json['location'] as String,
  description: json['description'] as String? ?? '',
  type: json['type'] as String,
  postedAt: json['postedAt'] as String,
  salaryDisplay: json['salaryDisplay'] as String,
  applicationCount: (json['applicationCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$JobDtoToJson(_JobDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'companyName': instance.companyName,
  'location': instance.location,
  'description': instance.description,
  'type': instance.type,
  'postedAt': instance.postedAt,
  'salaryDisplay': instance.salaryDisplay,
  'applicationCount': instance.applicationCount,
};
