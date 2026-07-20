// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_application_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJobApplicationIsarCollection on Isar {
  IsarCollection<JobApplicationIsar> get jobApplicationIsars =>
      this.collection();
}

const JobApplicationIsarSchema = CollectionSchema(
  name: r'JobApplicationIsar',
  id: -596041354592425319,
  properties: {
    r'applicantId': PropertySchema(
      id: 0,
      name: r'applicantId',
      type: IsarType.string,
    ),
    r'companyName': PropertySchema(
      id: 1,
      name: r'companyName',
      type: IsarType.string,
    ),
    r'jobListingId': PropertySchema(
      id: 2,
      name: r'jobListingId',
      type: IsarType.string,
    ),
    r'jobTitle': PropertySchema(
      id: 3,
      name: r'jobTitle',
      type: IsarType.string,
    ),
    r'status': PropertySchema(id: 4, name: r'status', type: IsarType.string),
    r'submittedAt': PropertySchema(
      id: 5,
      name: r'submittedAt',
      type: IsarType.dateTime,
    ),
    r'uniqueKey': PropertySchema(
      id: 6,
      name: r'uniqueKey',
      type: IsarType.string,
    ),
  },

  estimateSize: _jobApplicationIsarEstimateSize,
  serialize: _jobApplicationIsarSerialize,
  deserialize: _jobApplicationIsarDeserialize,
  deserializeProp: _jobApplicationIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'uniqueKey': IndexSchema(
      id: -866995956150369819,
      name: r'uniqueKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uniqueKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _jobApplicationIsarGetId,
  getLinks: _jobApplicationIsarGetLinks,
  attach: _jobApplicationIsarAttach,
  version: '3.3.2',
);

int _jobApplicationIsarEstimateSize(
  JobApplicationIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.applicantId.length * 3;
  bytesCount += 3 + object.companyName.length * 3;
  bytesCount += 3 + object.jobListingId.length * 3;
  bytesCount += 3 + object.jobTitle.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.uniqueKey.length * 3;
  return bytesCount;
}

void _jobApplicationIsarSerialize(
  JobApplicationIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.applicantId);
  writer.writeString(offsets[1], object.companyName);
  writer.writeString(offsets[2], object.jobListingId);
  writer.writeString(offsets[3], object.jobTitle);
  writer.writeString(offsets[4], object.status);
  writer.writeDateTime(offsets[5], object.submittedAt);
  writer.writeString(offsets[6], object.uniqueKey);
}

JobApplicationIsar _jobApplicationIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JobApplicationIsar();
  object.applicantId = reader.readString(offsets[0]);
  object.companyName = reader.readString(offsets[1]);
  object.id = id;
  object.jobListingId = reader.readString(offsets[2]);
  object.jobTitle = reader.readString(offsets[3]);
  object.status = reader.readString(offsets[4]);
  object.submittedAt = reader.readDateTime(offsets[5]);
  object.uniqueKey = reader.readString(offsets[6]);
  return object;
}

P _jobApplicationIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _jobApplicationIsarGetId(JobApplicationIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _jobApplicationIsarGetLinks(
  JobApplicationIsar object,
) {
  return [];
}

void _jobApplicationIsarAttach(
  IsarCollection<dynamic> col,
  Id id,
  JobApplicationIsar object,
) {
  object.id = id;
}

extension JobApplicationIsarByIndex on IsarCollection<JobApplicationIsar> {
  Future<JobApplicationIsar?> getByUniqueKey(String uniqueKey) {
    return getByIndex(r'uniqueKey', [uniqueKey]);
  }

  JobApplicationIsar? getByUniqueKeySync(String uniqueKey) {
    return getByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<bool> deleteByUniqueKey(String uniqueKey) {
    return deleteByIndex(r'uniqueKey', [uniqueKey]);
  }

  bool deleteByUniqueKeySync(String uniqueKey) {
    return deleteByIndexSync(r'uniqueKey', [uniqueKey]);
  }

  Future<List<JobApplicationIsar?>> getAllByUniqueKey(
    List<String> uniqueKeyValues,
  ) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'uniqueKey', values);
  }

  List<JobApplicationIsar?> getAllByUniqueKeySync(
    List<String> uniqueKeyValues,
  ) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uniqueKey', values);
  }

  Future<int> deleteAllByUniqueKey(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uniqueKey', values);
  }

  int deleteAllByUniqueKeySync(List<String> uniqueKeyValues) {
    final values = uniqueKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uniqueKey', values);
  }

  Future<Id> putByUniqueKey(JobApplicationIsar object) {
    return putByIndex(r'uniqueKey', object);
  }

  Id putByUniqueKeySync(JobApplicationIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'uniqueKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUniqueKey(List<JobApplicationIsar> objects) {
    return putAllByIndex(r'uniqueKey', objects);
  }

  List<Id> putAllByUniqueKeySync(
    List<JobApplicationIsar> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uniqueKey', objects, saveLinks: saveLinks);
  }
}

extension JobApplicationIsarQueryWhereSort
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QWhere> {
  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JobApplicationIsarQueryWhere
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QWhereClause> {
  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhereClause>
  uniqueKeyEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uniqueKey', value: [uniqueKey]),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterWhereClause>
  uniqueKeyNotEqualTo(String uniqueKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [uniqueKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uniqueKey',
                lower: [],
                upper: [uniqueKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension JobApplicationIsarQueryFilter
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QFilterCondition> {
  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'applicantId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'applicantId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'applicantId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'applicantId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'applicantId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'applicantId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'applicantId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'applicantId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'applicantId', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  applicantIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'applicantId', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'companyName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'companyName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'companyName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  companyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'companyName', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'jobListingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'jobListingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'jobListingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'jobListingId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'jobListingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'jobListingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'jobListingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'jobListingId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'jobListingId', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobListingIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'jobListingId', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'jobTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'jobTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'jobTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'jobTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'jobTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'jobTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'jobTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'jobTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'jobTitle', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  jobTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'jobTitle', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  submittedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'submittedAt', value: value),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  submittedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'submittedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  submittedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'submittedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  submittedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'submittedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uniqueKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uniqueKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uniqueKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uniqueKey', value: ''),
      );
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterFilterCondition>
  uniqueKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uniqueKey', value: ''),
      );
    });
  }
}

extension JobApplicationIsarQueryObject
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QFilterCondition> {}

extension JobApplicationIsarQueryLinks
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QFilterCondition> {}

extension JobApplicationIsarQuerySortBy
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QSortBy> {
  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByApplicantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'applicantId', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByApplicantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'applicantId', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByJobListingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobListingId', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByJobListingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobListingId', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByJobTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByJobTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortBySubmittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'submittedAt', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortBySubmittedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'submittedAt', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  sortByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension JobApplicationIsarQuerySortThenBy
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QSortThenBy> {
  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByApplicantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'applicantId', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByApplicantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'applicantId', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByJobListingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobListingId', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByJobListingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobListingId', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByJobTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByJobTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenBySubmittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'submittedAt', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenBySubmittedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'submittedAt', Sort.desc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByUniqueKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.asc);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QAfterSortBy>
  thenByUniqueKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uniqueKey', Sort.desc);
    });
  }
}

extension JobApplicationIsarQueryWhereDistinct
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct> {
  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct>
  distinctByApplicantId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'applicantId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct>
  distinctByCompanyName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct>
  distinctByJobListingId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobListingId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct>
  distinctByJobTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct>
  distinctBySubmittedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'submittedAt');
    });
  }

  QueryBuilder<JobApplicationIsar, JobApplicationIsar, QDistinct>
  distinctByUniqueKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uniqueKey', caseSensitive: caseSensitive);
    });
  }
}

extension JobApplicationIsarQueryProperty
    on QueryBuilder<JobApplicationIsar, JobApplicationIsar, QQueryProperty> {
  QueryBuilder<JobApplicationIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JobApplicationIsar, String, QQueryOperations>
  applicantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'applicantId');
    });
  }

  QueryBuilder<JobApplicationIsar, String, QQueryOperations>
  companyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companyName');
    });
  }

  QueryBuilder<JobApplicationIsar, String, QQueryOperations>
  jobListingIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobListingId');
    });
  }

  QueryBuilder<JobApplicationIsar, String, QQueryOperations>
  jobTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobTitle');
    });
  }

  QueryBuilder<JobApplicationIsar, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<JobApplicationIsar, DateTime, QQueryOperations>
  submittedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'submittedAt');
    });
  }

  QueryBuilder<JobApplicationIsar, String, QQueryOperations>
  uniqueKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uniqueKey');
    });
  }
}
