// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_draft.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetApplicationDraftCollection on Isar {
  IsarCollection<ApplicationDraft> get applicationDrafts => this.collection();
}

const ApplicationDraftSchema = CollectionSchema(
  name: r'ApplicationDraft',
  id: 1481163886637176271,
  properties: {
    r'coverLetter': PropertySchema(
      id: 0,
      name: r'coverLetter',
      type: IsarType.string,
    ),
    r'email': PropertySchema(id: 1, name: r'email', type: IsarType.string),
    r'fullName': PropertySchema(
      id: 2,
      name: r'fullName',
      type: IsarType.string,
    ),
    r'jobId': PropertySchema(id: 3, name: r'jobId', type: IsarType.string),
    r'portfolioUrl': PropertySchema(
      id: 4,
      name: r'portfolioUrl',
      type: IsarType.string,
    ),
    r'savedAt': PropertySchema(
      id: 5,
      name: r'savedAt',
      type: IsarType.dateTime,
    ),
    r'startDate': PropertySchema(
      id: 6,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'terms': PropertySchema(id: 7, name: r'terms', type: IsarType.bool),
    r'yearsExperience': PropertySchema(
      id: 8,
      name: r'yearsExperience',
      type: IsarType.long,
    ),
  },

  estimateSize: _applicationDraftEstimateSize,
  serialize: _applicationDraftSerialize,
  deserialize: _applicationDraftDeserialize,
  deserializeProp: _applicationDraftDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _applicationDraftGetId,
  getLinks: _applicationDraftGetLinks,
  attach: _applicationDraftAttach,
  version: '3.3.2',
);

int _applicationDraftEstimateSize(
  ApplicationDraft object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.coverLetter.length * 3;
  bytesCount += 3 + object.email.length * 3;
  bytesCount += 3 + object.fullName.length * 3;
  bytesCount += 3 + object.jobId.length * 3;
  bytesCount += 3 + object.portfolioUrl.length * 3;
  return bytesCount;
}

void _applicationDraftSerialize(
  ApplicationDraft object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.coverLetter);
  writer.writeString(offsets[1], object.email);
  writer.writeString(offsets[2], object.fullName);
  writer.writeString(offsets[3], object.jobId);
  writer.writeString(offsets[4], object.portfolioUrl);
  writer.writeDateTime(offsets[5], object.savedAt);
  writer.writeDateTime(offsets[6], object.startDate);
  writer.writeBool(offsets[7], object.terms);
  writer.writeLong(offsets[8], object.yearsExperience);
}

ApplicationDraft _applicationDraftDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ApplicationDraft();
  object.coverLetter = reader.readString(offsets[0]);
  object.email = reader.readString(offsets[1]);
  object.fullName = reader.readString(offsets[2]);
  object.id = id;
  object.jobId = reader.readString(offsets[3]);
  object.portfolioUrl = reader.readString(offsets[4]);
  object.savedAt = reader.readDateTime(offsets[5]);
  object.startDate = reader.readDateTime(offsets[6]);
  object.terms = reader.readBool(offsets[7]);
  object.yearsExperience = reader.readLong(offsets[8]);
  return object;
}

P _applicationDraftDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _applicationDraftGetId(ApplicationDraft object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _applicationDraftGetLinks(ApplicationDraft object) {
  return [];
}

void _applicationDraftAttach(
  IsarCollection<dynamic> col,
  Id id,
  ApplicationDraft object,
) {
  object.id = id;
}

extension ApplicationDraftQueryWhereSort
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QWhere> {
  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ApplicationDraftQueryWhere
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QWhereClause> {
  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterWhereClause>
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

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterWhereClause> idBetween(
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
}

extension ApplicationDraftQueryFilter
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QFilterCondition> {
  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'coverLetter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'coverLetter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'coverLetter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'coverLetter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'coverLetter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'coverLetter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'coverLetter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'coverLetter',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'coverLetter', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  coverLetterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'coverLetter', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'email',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'email',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'email',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'email', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'email', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fullName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fullName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fullName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fullName', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  fullNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fullName', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
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

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
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

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
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

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'jobId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'jobId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'jobId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'jobId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'jobId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'jobId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'jobId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'jobId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'jobId', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  jobIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'jobId', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'portfolioUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'portfolioUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'portfolioUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'portfolioUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'portfolioUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'portfolioUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'portfolioUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'portfolioUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'portfolioUrl', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  portfolioUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'portfolioUrl', value: ''),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  savedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'savedAt', value: value),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  savedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'savedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  savedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'savedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  savedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'savedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  startDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startDate', value: value),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  startDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  startDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  startDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  termsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'terms', value: value),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  yearsExperienceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'yearsExperience', value: value),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  yearsExperienceGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'yearsExperience',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  yearsExperienceLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'yearsExperience',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterFilterCondition>
  yearsExperienceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'yearsExperience',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ApplicationDraftQueryObject
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QFilterCondition> {}

extension ApplicationDraftQueryLinks
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QFilterCondition> {}

extension ApplicationDraftQuerySortBy
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QSortBy> {
  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByCoverLetter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverLetter', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByCoverLetterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverLetter', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy> sortByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByPortfolioUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portfolioUrl', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByPortfolioUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portfolioUrl', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy> sortByTerms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByTermsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByYearsExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  sortByYearsExperienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.desc);
    });
  }
}

extension ApplicationDraftQuerySortThenBy
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QSortThenBy> {
  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByCoverLetter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverLetter', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByCoverLetterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverLetter', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullName', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy> thenByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByPortfolioUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portfolioUrl', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByPortfolioUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portfolioUrl', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenBySavedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAt', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy> thenByTerms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByTermsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.desc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByYearsExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.asc);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QAfterSortBy>
  thenByYearsExperienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'yearsExperience', Sort.desc);
    });
  }
}

extension ApplicationDraftQueryWhereDistinct
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct> {
  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct>
  distinctByCoverLetter({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coverLetter', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct> distinctByEmail({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct>
  distinctByFullName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fullName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct> distinctByJobId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct>
  distinctByPortfolioUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'portfolioUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct>
  distinctBySavedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savedAt');
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct>
  distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct>
  distinctByTerms() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'terms');
    });
  }

  QueryBuilder<ApplicationDraft, ApplicationDraft, QDistinct>
  distinctByYearsExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'yearsExperience');
    });
  }
}

extension ApplicationDraftQueryProperty
    on QueryBuilder<ApplicationDraft, ApplicationDraft, QQueryProperty> {
  QueryBuilder<ApplicationDraft, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ApplicationDraft, String, QQueryOperations>
  coverLetterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coverLetter');
    });
  }

  QueryBuilder<ApplicationDraft, String, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<ApplicationDraft, String, QQueryOperations> fullNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fullName');
    });
  }

  QueryBuilder<ApplicationDraft, String, QQueryOperations> jobIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobId');
    });
  }

  QueryBuilder<ApplicationDraft, String, QQueryOperations>
  portfolioUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'portfolioUrl');
    });
  }

  QueryBuilder<ApplicationDraft, DateTime, QQueryOperations> savedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savedAt');
    });
  }

  QueryBuilder<ApplicationDraft, DateTime, QQueryOperations>
  startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<ApplicationDraft, bool, QQueryOperations> termsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'terms');
    });
  }

  QueryBuilder<ApplicationDraft, int, QQueryOperations>
  yearsExperienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'yearsExperience');
    });
  }
}
