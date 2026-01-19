// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedDateMeta = const VerificationMeta(
    'addedDate',
  );
  @override
  late final GeneratedColumn<int> addedDate = GeneratedColumn<int>(
    'added_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spineConfidenceMeta = const VerificationMeta(
    'spineConfidence',
  );
  @override
  late final GeneratedColumn<double> spineConfidence = GeneratedColumn<double>(
    'spine_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewNeededMeta = const VerificationMeta(
    'reviewNeeded',
  );
  @override
  late final GeneratedColumn<bool> reviewNeeded = GeneratedColumn<bool>(
    'review_needed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("review_needed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _spineImagePathMeta = const VerificationMeta(
    'spineImagePath',
  );
  @override
  late final GeneratedColumn<String> spineImagePath = GeneratedColumn<String>(
    'spine_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    isbn,
    title,
    author,
    coverUrl,
    format,
    addedDate,
    spineConfidence,
    reviewNeeded,
    spineImagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    } else if (isInserting) {
      context.missing(_isbnMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('added_date')) {
      context.handle(
        _addedDateMeta,
        addedDate.isAcceptableOrUnknown(data['added_date']!, _addedDateMeta),
      );
    } else if (isInserting) {
      context.missing(_addedDateMeta);
    }
    if (data.containsKey('spine_confidence')) {
      context.handle(
        _spineConfidenceMeta,
        spineConfidence.isAcceptableOrUnknown(
          data['spine_confidence']!,
          _spineConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('review_needed')) {
      context.handle(
        _reviewNeededMeta,
        reviewNeeded.isAcceptableOrUnknown(
          data['review_needed']!,
          _reviewNeededMeta,
        ),
      );
    }
    if (data.containsKey('spine_image_path')) {
      context.handle(
        _spineImagePathMeta,
        spineImagePath.isAcceptableOrUnknown(
          data['spine_image_path']!,
          _spineImagePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {isbn};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      addedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_date'],
      )!,
      spineConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}spine_confidence'],
      ),
      reviewNeeded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}review_needed'],
      )!,
      spineImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spine_image_path'],
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  final String isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final String? format;
  final int addedDate;
  final double? spineConfidence;
  final bool reviewNeeded;
  final String? spineImagePath;
  const Book({
    required this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    this.format,
    required this.addedDate,
    this.spineConfidence,
    required this.reviewNeeded,
    this.spineImagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['isbn'] = Variable<String>(isbn);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    map['added_date'] = Variable<int>(addedDate);
    if (!nullToAbsent || spineConfidence != null) {
      map['spine_confidence'] = Variable<double>(spineConfidence);
    }
    map['review_needed'] = Variable<bool>(reviewNeeded);
    if (!nullToAbsent || spineImagePath != null) {
      map['spine_image_path'] = Variable<String>(spineImagePath);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      isbn: Value(isbn),
      title: Value(title),
      author: Value(author),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      addedDate: Value(addedDate),
      spineConfidence: spineConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(spineConfidence),
      reviewNeeded: Value(reviewNeeded),
      spineImagePath: spineImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(spineImagePath),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      isbn: serializer.fromJson<String>(json['isbn']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      format: serializer.fromJson<String?>(json['format']),
      addedDate: serializer.fromJson<int>(json['addedDate']),
      spineConfidence: serializer.fromJson<double?>(json['spineConfidence']),
      reviewNeeded: serializer.fromJson<bool>(json['reviewNeeded']),
      spineImagePath: serializer.fromJson<String?>(json['spineImagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'isbn': serializer.toJson<String>(isbn),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'format': serializer.toJson<String?>(format),
      'addedDate': serializer.toJson<int>(addedDate),
      'spineConfidence': serializer.toJson<double?>(spineConfidence),
      'reviewNeeded': serializer.toJson<bool>(reviewNeeded),
      'spineImagePath': serializer.toJson<String?>(spineImagePath),
    };
  }

  Book copyWith({
    String? isbn,
    String? title,
    String? author,
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> format = const Value.absent(),
    int? addedDate,
    Value<double?> spineConfidence = const Value.absent(),
    bool? reviewNeeded,
    Value<String?> spineImagePath = const Value.absent(),
  }) => Book(
    isbn: isbn ?? this.isbn,
    title: title ?? this.title,
    author: author ?? this.author,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    format: format.present ? format.value : this.format,
    addedDate: addedDate ?? this.addedDate,
    spineConfidence: spineConfidence.present
        ? spineConfidence.value
        : this.spineConfidence,
    reviewNeeded: reviewNeeded ?? this.reviewNeeded,
    spineImagePath: spineImagePath.present
        ? spineImagePath.value
        : this.spineImagePath,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      format: data.format.present ? data.format.value : this.format,
      addedDate: data.addedDate.present ? data.addedDate.value : this.addedDate,
      spineConfidence: data.spineConfidence.present
          ? data.spineConfidence.value
          : this.spineConfidence,
      reviewNeeded: data.reviewNeeded.present
          ? data.reviewNeeded.value
          : this.reviewNeeded,
      spineImagePath: data.spineImagePath.present
          ? data.spineImagePath.value
          : this.spineImagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('isbn: $isbn, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('format: $format, ')
          ..write('addedDate: $addedDate, ')
          ..write('spineConfidence: $spineConfidence, ')
          ..write('reviewNeeded: $reviewNeeded, ')
          ..write('spineImagePath: $spineImagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    isbn,
    title,
    author,
    coverUrl,
    format,
    addedDate,
    spineConfidence,
    reviewNeeded,
    spineImagePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.isbn == this.isbn &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverUrl == this.coverUrl &&
          other.format == this.format &&
          other.addedDate == this.addedDate &&
          other.spineConfidence == this.spineConfidence &&
          other.reviewNeeded == this.reviewNeeded &&
          other.spineImagePath == this.spineImagePath);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> isbn;
  final Value<String> title;
  final Value<String> author;
  final Value<String?> coverUrl;
  final Value<String?> format;
  final Value<int> addedDate;
  final Value<double?> spineConfidence;
  final Value<bool> reviewNeeded;
  final Value<String?> spineImagePath;
  final Value<int> rowid;
  const BooksCompanion({
    this.isbn = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.format = const Value.absent(),
    this.addedDate = const Value.absent(),
    this.spineConfidence = const Value.absent(),
    this.reviewNeeded = const Value.absent(),
    this.spineImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String isbn,
    required String title,
    required String author,
    this.coverUrl = const Value.absent(),
    this.format = const Value.absent(),
    required int addedDate,
    this.spineConfidence = const Value.absent(),
    this.reviewNeeded = const Value.absent(),
    this.spineImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : isbn = Value(isbn),
       title = Value(title),
       author = Value(author),
       addedDate = Value(addedDate);
  static Insertable<Book> custom({
    Expression<String>? isbn,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverUrl,
    Expression<String>? format,
    Expression<int>? addedDate,
    Expression<double>? spineConfidence,
    Expression<bool>? reviewNeeded,
    Expression<String>? spineImagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (isbn != null) 'isbn': isbn,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (format != null) 'format': format,
      if (addedDate != null) 'added_date': addedDate,
      if (spineConfidence != null) 'spine_confidence': spineConfidence,
      if (reviewNeeded != null) 'review_needed': reviewNeeded,
      if (spineImagePath != null) 'spine_image_path': spineImagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? isbn,
    Value<String>? title,
    Value<String>? author,
    Value<String?>? coverUrl,
    Value<String?>? format,
    Value<int>? addedDate,
    Value<double?>? spineConfidence,
    Value<bool>? reviewNeeded,
    Value<String?>? spineImagePath,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      format: format ?? this.format,
      addedDate: addedDate ?? this.addedDate,
      spineConfidence: spineConfidence ?? this.spineConfidence,
      reviewNeeded: reviewNeeded ?? this.reviewNeeded,
      spineImagePath: spineImagePath ?? this.spineImagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (addedDate.present) {
      map['added_date'] = Variable<int>(addedDate.value);
    }
    if (spineConfidence.present) {
      map['spine_confidence'] = Variable<double>(spineConfidence.value);
    }
    if (reviewNeeded.present) {
      map['review_needed'] = Variable<bool>(reviewNeeded.value);
    }
    if (spineImagePath.present) {
      map['spine_image_path'] = Variable<String>(spineImagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('isbn: $isbn, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('format: $format, ')
          ..write('addedDate: $addedDate, ')
          ..write('spineConfidence: $spineConfidence, ')
          ..write('reviewNeeded: $reviewNeeded, ')
          ..write('spineImagePath: $spineImagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FailedScansTable extends FailedScans
    with TableInfo<$FailedScansTable, FailedScan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FailedScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FailureReason, String>
  failureReason = GeneratedColumn<String>(
    'failure_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(FailureReason.unknown.name),
  ).withConverter<FailureReason>($FailedScansTable.$converterfailureReason);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    imagePath,
    errorMessage,
    failureReason,
    createdAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'failed_scans';
  @override
  VerificationContext validateIntegrity(
    Insertable<FailedScan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_errorMessageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FailedScan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FailedScan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      )!,
      failureReason: $FailedScansTable.$converterfailureReason.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}failure_reason'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $FailedScansTable createAlias(String alias) {
    return $FailedScansTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FailureReason, String, String>
  $converterfailureReason = const EnumNameConverter<FailureReason>(
    FailureReason.values,
  );
}

class FailedScan extends DataClass implements Insertable<FailedScan> {
  final int id;
  final String jobId;
  final String imagePath;
  final String errorMessage;
  final FailureReason failureReason;
  final int createdAt;
  final int expiresAt;
  const FailedScan({
    required this.id,
    required this.jobId,
    required this.imagePath,
    required this.errorMessage,
    required this.failureReason,
    required this.createdAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<String>(jobId);
    map['image_path'] = Variable<String>(imagePath);
    map['error_message'] = Variable<String>(errorMessage);
    {
      map['failure_reason'] = Variable<String>(
        $FailedScansTable.$converterfailureReason.toSql(failureReason),
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  FailedScansCompanion toCompanion(bool nullToAbsent) {
    return FailedScansCompanion(
      id: Value(id),
      jobId: Value(jobId),
      imagePath: Value(imagePath),
      errorMessage: Value(errorMessage),
      failureReason: Value(failureReason),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory FailedScan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FailedScan(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      errorMessage: serializer.fromJson<String>(json['errorMessage']),
      failureReason: $FailedScansTable.$converterfailureReason.fromJson(
        serializer.fromJson<String>(json['failureReason']),
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<String>(jobId),
      'imagePath': serializer.toJson<String>(imagePath),
      'errorMessage': serializer.toJson<String>(errorMessage),
      'failureReason': serializer.toJson<String>(
        $FailedScansTable.$converterfailureReason.toJson(failureReason),
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  FailedScan copyWith({
    int? id,
    String? jobId,
    String? imagePath,
    String? errorMessage,
    FailureReason? failureReason,
    int? createdAt,
    int? expiresAt,
  }) => FailedScan(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    imagePath: imagePath ?? this.imagePath,
    errorMessage: errorMessage ?? this.errorMessage,
    failureReason: failureReason ?? this.failureReason,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  FailedScan copyWithCompanion(FailedScansCompanion data) {
    return FailedScan(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FailedScan(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('imagePath: $imagePath, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('failureReason: $failureReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobId,
    imagePath,
    errorMessage,
    failureReason,
    createdAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FailedScan &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.imagePath == this.imagePath &&
          other.errorMessage == this.errorMessage &&
          other.failureReason == this.failureReason &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class FailedScansCompanion extends UpdateCompanion<FailedScan> {
  final Value<int> id;
  final Value<String> jobId;
  final Value<String> imagePath;
  final Value<String> errorMessage;
  final Value<FailureReason> failureReason;
  final Value<int> createdAt;
  final Value<int> expiresAt;
  const FailedScansCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  FailedScansCompanion.insert({
    this.id = const Value.absent(),
    required String jobId,
    required String imagePath,
    required String errorMessage,
    this.failureReason = const Value.absent(),
    required int createdAt,
    required int expiresAt,
  }) : jobId = Value(jobId),
       imagePath = Value(imagePath),
       errorMessage = Value(errorMessage),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<FailedScan> custom({
    Expression<int>? id,
    Expression<String>? jobId,
    Expression<String>? imagePath,
    Expression<String>? errorMessage,
    Expression<String>? failureReason,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (imagePath != null) 'image_path': imagePath,
      if (errorMessage != null) 'error_message': errorMessage,
      if (failureReason != null) 'failure_reason': failureReason,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  FailedScansCompanion copyWith({
    Value<int>? id,
    Value<String>? jobId,
    Value<String>? imagePath,
    Value<String>? errorMessage,
    Value<FailureReason>? failureReason,
    Value<int>? createdAt,
    Value<int>? expiresAt,
  }) {
    return FailedScansCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      imagePath: imagePath ?? this.imagePath,
      errorMessage: errorMessage ?? this.errorMessage,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(
        $FailedScansTable.$converterfailureReason.toSql(failureReason.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FailedScansCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('imagePath: $imagePath, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('failureReason: $failureReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final int id;
  final String name;
  final int createdAt;
  const Collection({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Collection copyWith({int? id, String? name, int? createdAt}) => Collection(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> createdAt;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CollectionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Collection> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CollectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? createdAt,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BookCollectionsTable extends BookCollections
    with TableInfo<$BookCollectionsTable, BookCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<int> collectionId = GeneratedColumn<int>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [isbn, collectionId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookCollection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    } else if (isInserting) {
      context.missing(_isbnMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {isbn, collectionId};
  @override
  BookCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookCollection(
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}collection_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $BookCollectionsTable createAlias(String alias) {
    return $BookCollectionsTable(attachedDatabase, alias);
  }
}

class BookCollection extends DataClass implements Insertable<BookCollection> {
  final String isbn;
  final int collectionId;
  final int addedAt;
  const BookCollection({
    required this.isbn,
    required this.collectionId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['isbn'] = Variable<String>(isbn);
    map['collection_id'] = Variable<int>(collectionId);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  BookCollectionsCompanion toCompanion(bool nullToAbsent) {
    return BookCollectionsCompanion(
      isbn: Value(isbn),
      collectionId: Value(collectionId),
      addedAt: Value(addedAt),
    );
  }

  factory BookCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookCollection(
      isbn: serializer.fromJson<String>(json['isbn']),
      collectionId: serializer.fromJson<int>(json['collectionId']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'isbn': serializer.toJson<String>(isbn),
      'collectionId': serializer.toJson<int>(collectionId),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  BookCollection copyWith({String? isbn, int? collectionId, int? addedAt}) =>
      BookCollection(
        isbn: isbn ?? this.isbn,
        collectionId: collectionId ?? this.collectionId,
        addedAt: addedAt ?? this.addedAt,
      );
  BookCollection copyWithCompanion(BookCollectionsCompanion data) {
    return BookCollection(
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookCollection(')
          ..write('isbn: $isbn, ')
          ..write('collectionId: $collectionId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(isbn, collectionId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookCollection &&
          other.isbn == this.isbn &&
          other.collectionId == this.collectionId &&
          other.addedAt == this.addedAt);
}

class BookCollectionsCompanion extends UpdateCompanion<BookCollection> {
  final Value<String> isbn;
  final Value<int> collectionId;
  final Value<int> addedAt;
  final Value<int> rowid;
  const BookCollectionsCompanion({
    this.isbn = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookCollectionsCompanion.insert({
    required String isbn,
    required int collectionId,
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : isbn = Value(isbn),
       collectionId = Value(collectionId),
       addedAt = Value(addedAt);
  static Insertable<BookCollection> custom({
    Expression<String>? isbn,
    Expression<int>? collectionId,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (isbn != null) 'isbn': isbn,
      if (collectionId != null) 'collection_id': collectionId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookCollectionsCompanion copyWith({
    Value<String>? isbn,
    Value<int>? collectionId,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return BookCollectionsCompanion(
      isbn: isbn ?? this.isbn,
      collectionId: collectionId ?? this.collectionId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<int>(collectionId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookCollectionsCompanion(')
          ..write('isbn: $isbn, ')
          ..write('collectionId: $collectionId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $FailedScansTable failedScans = $FailedScansTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $BookCollectionsTable bookCollections = $BookCollectionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    failedScans,
    collections,
    bookCollections,
  ];
}

typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      required String isbn,
      required String title,
      required String author,
      Value<String?> coverUrl,
      Value<String?> format,
      required int addedDate,
      Value<double?> spineConfidence,
      Value<bool> reviewNeeded,
      Value<String?> spineImagePath,
      Value<int> rowid,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<String> isbn,
      Value<String> title,
      Value<String> author,
      Value<String?> coverUrl,
      Value<String?> format,
      Value<int> addedDate,
      Value<double?> spineConfidence,
      Value<bool> reviewNeeded,
      Value<String?> spineImagePath,
      Value<int> rowid,
    });

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedDate => $composableBuilder(
    column: $table.addedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get spineConfidence => $composableBuilder(
    column: $table.spineConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reviewNeeded => $composableBuilder(
    column: $table.reviewNeeded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spineImagePath => $composableBuilder(
    column: $table.spineImagePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedDate => $composableBuilder(
    column: $table.addedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get spineConfidence => $composableBuilder(
    column: $table.spineConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reviewNeeded => $composableBuilder(
    column: $table.reviewNeeded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spineImagePath => $composableBuilder(
    column: $table.spineImagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get addedDate =>
      $composableBuilder(column: $table.addedDate, builder: (column) => column);

  GeneratedColumn<double> get spineConfidence => $composableBuilder(
    column: $table.spineConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reviewNeeded => $composableBuilder(
    column: $table.reviewNeeded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spineImagePath => $composableBuilder(
    column: $table.spineImagePath,
    builder: (column) => column,
  );
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
          Book,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> isbn = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<int> addedDate = const Value.absent(),
                Value<double?> spineConfidence = const Value.absent(),
                Value<bool> reviewNeeded = const Value.absent(),
                Value<String?> spineImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                isbn: isbn,
                title: title,
                author: author,
                coverUrl: coverUrl,
                format: format,
                addedDate: addedDate,
                spineConfidence: spineConfidence,
                reviewNeeded: reviewNeeded,
                spineImagePath: spineImagePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String isbn,
                required String title,
                required String author,
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> format = const Value.absent(),
                required int addedDate,
                Value<double?> spineConfidence = const Value.absent(),
                Value<bool> reviewNeeded = const Value.absent(),
                Value<String?> spineImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                isbn: isbn,
                title: title,
                author: author,
                coverUrl: coverUrl,
                format: format,
                addedDate: addedDate,
                spineConfidence: spineConfidence,
                reviewNeeded: reviewNeeded,
                spineImagePath: spineImagePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
      Book,
      PrefetchHooks Function()
    >;
typedef $$FailedScansTableCreateCompanionBuilder =
    FailedScansCompanion Function({
      Value<int> id,
      required String jobId,
      required String imagePath,
      required String errorMessage,
      Value<FailureReason> failureReason,
      required int createdAt,
      required int expiresAt,
    });
typedef $$FailedScansTableUpdateCompanionBuilder =
    FailedScansCompanion Function({
      Value<int> id,
      Value<String> jobId,
      Value<String> imagePath,
      Value<String> errorMessage,
      Value<FailureReason> failureReason,
      Value<int> createdAt,
      Value<int> expiresAt,
    });

class $$FailedScansTableFilterComposer
    extends Composer<_$AppDatabase, $FailedScansTable> {
  $$FailedScansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FailureReason, FailureReason, String>
  get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FailedScansTableOrderingComposer
    extends Composer<_$AppDatabase, $FailedScansTable> {
  $$FailedScansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FailedScansTableAnnotationComposer
    extends Composer<_$AppDatabase, $FailedScansTable> {
  $$FailedScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FailureReason, String> get failureReason =>
      $composableBuilder(
        column: $table.failureReason,
        builder: (column) => column,
      );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$FailedScansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FailedScansTable,
          FailedScan,
          $$FailedScansTableFilterComposer,
          $$FailedScansTableOrderingComposer,
          $$FailedScansTableAnnotationComposer,
          $$FailedScansTableCreateCompanionBuilder,
          $$FailedScansTableUpdateCompanionBuilder,
          (
            FailedScan,
            BaseReferences<_$AppDatabase, $FailedScansTable, FailedScan>,
          ),
          FailedScan,
          PrefetchHooks Function()
        > {
  $$FailedScansTableTableManager(_$AppDatabase db, $FailedScansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FailedScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FailedScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FailedScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> errorMessage = const Value.absent(),
                Value<FailureReason> failureReason = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
              }) => FailedScansCompanion(
                id: id,
                jobId: jobId,
                imagePath: imagePath,
                errorMessage: errorMessage,
                failureReason: failureReason,
                createdAt: createdAt,
                expiresAt: expiresAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jobId,
                required String imagePath,
                required String errorMessage,
                Value<FailureReason> failureReason = const Value.absent(),
                required int createdAt,
                required int expiresAt,
              }) => FailedScansCompanion.insert(
                id: id,
                jobId: jobId,
                imagePath: imagePath,
                errorMessage: errorMessage,
                failureReason: failureReason,
                createdAt: createdAt,
                expiresAt: expiresAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FailedScansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FailedScansTable,
      FailedScan,
      $$FailedScansTableFilterComposer,
      $$FailedScansTableOrderingComposer,
      $$FailedScansTableAnnotationComposer,
      $$FailedScansTableCreateCompanionBuilder,
      $$FailedScansTableUpdateCompanionBuilder,
      (
        FailedScan,
        BaseReferences<_$AppDatabase, $FailedScansTable, FailedScan>,
      ),
      FailedScan,
      PrefetchHooks Function()
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      Value<int> id,
      required String name,
      required int createdAt,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> createdAt,
    });

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (
            Collection,
            BaseReferences<_$AppDatabase, $CollectionsTable, Collection>,
          ),
          Collection,
          PrefetchHooks Function()
        > {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int createdAt,
              }) => CollectionsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (
        Collection,
        BaseReferences<_$AppDatabase, $CollectionsTable, Collection>,
      ),
      Collection,
      PrefetchHooks Function()
    >;
typedef $$BookCollectionsTableCreateCompanionBuilder =
    BookCollectionsCompanion Function({
      required String isbn,
      required int collectionId,
      required int addedAt,
      Value<int> rowid,
    });
typedef $$BookCollectionsTableUpdateCompanionBuilder =
    BookCollectionsCompanion Function({
      Value<String> isbn,
      Value<int> collectionId,
      Value<int> addedAt,
      Value<int> rowid,
    });

class $$BookCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $BookCollectionsTable> {
  $$BookCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookCollectionsTable> {
  $$BookCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookCollectionsTable> {
  $$BookCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<int> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$BookCollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookCollectionsTable,
          BookCollection,
          $$BookCollectionsTableFilterComposer,
          $$BookCollectionsTableOrderingComposer,
          $$BookCollectionsTableAnnotationComposer,
          $$BookCollectionsTableCreateCompanionBuilder,
          $$BookCollectionsTableUpdateCompanionBuilder,
          (
            BookCollection,
            BaseReferences<
              _$AppDatabase,
              $BookCollectionsTable,
              BookCollection
            >,
          ),
          BookCollection,
          PrefetchHooks Function()
        > {
  $$BookCollectionsTableTableManager(
    _$AppDatabase db,
    $BookCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> isbn = const Value.absent(),
                Value<int> collectionId = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookCollectionsCompanion(
                isbn: isbn,
                collectionId: collectionId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String isbn,
                required int collectionId,
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => BookCollectionsCompanion.insert(
                isbn: isbn,
                collectionId: collectionId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookCollectionsTable,
      BookCollection,
      $$BookCollectionsTableFilterComposer,
      $$BookCollectionsTableOrderingComposer,
      $$BookCollectionsTableAnnotationComposer,
      $$BookCollectionsTableCreateCompanionBuilder,
      $$BookCollectionsTableUpdateCompanionBuilder,
      (
        BookCollection,
        BaseReferences<_$AppDatabase, $BookCollectionsTable, BookCollection>,
      ),
      BookCollection,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$FailedScansTableTableManager get failedScans =>
      $$FailedScansTableTableManager(_db, _db.failedScans);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$BookCollectionsTableTableManager get bookCollections =>
      $$BookCollectionsTableTableManager(_db, _db.bookCollections);
}
