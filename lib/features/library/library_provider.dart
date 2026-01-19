import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';

final allBooksProvider = StreamProvider<List<Book>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllBooks();
});
