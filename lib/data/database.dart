import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DataClassName('Book')
class Books extends Table {
  TextColumn get isbn => text()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get format => text().nullable()();
  IntColumn get addedDate => integer()();
  RealColumn get spineConfidence => real().nullable()();

  @override
  Set<Column> get primaryKey => {isbn};
}

@DataClassName('FailedScan')
class FailedScans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobId => text()();
  TextColumn get imagePath => text()();
  TextColumn get errorMessage => text()();
  IntColumn get createdAt => integer()();
  IntColumn get expiresAt => integer()();
}

@DriftDatabase(tables: [Books, FailedScans])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.test(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create index on addedDate descending for default sort
        await customStatement(
          'CREATE INDEX idx_books_added_date ON books(added_date DESC)',
        );
      },
    );
  }

  // Query all books ordered by added date descending
  Stream<List<Book>> watchAllBooks() {
    return (select(books)..orderBy([(t) => OrderingTerm.desc(t.addedDate)]))
        .watch();
  }

  Future<List<Book>> getAllBooks() {
    return (select(books)..orderBy([(t) => OrderingTerm.desc(t.addedDate)]))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wingtip.db'));
    return NativeDatabase(file);
  });
}
