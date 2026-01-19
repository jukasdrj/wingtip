import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:wingtip/data/database.dart';

/// Service for exporting book library data to CSV format.
class CsvExportService {
  final AppDatabase _database;

  CsvExportService(this._database);

  /// Exports all books to a CSV file and opens the system share sheet.
  ///
  /// The CSV file includes headers: ISBN, Title, Author, Format, Added Date, Cover URL
  /// Filename format: wingtip_library_YYYY-MM-DD.csv
  ///
  /// Returns the file path if successful, null if there are no books to export.
  Future<String?> exportLibraryToCsv() async {
    // Fetch all books from the database
    final books = await _database.getAllBooks();

    if (books.isEmpty) {
      return null;
    }

    // Create CSV data with headers
    final List<List<dynamic>> csvData = [
      ['ISBN', 'Title', 'Author', 'Format', 'Added Date', 'Cover URL'],
    ];

    // Add book data rows
    for (final book in books) {
      csvData.add([
        book.isbn,
        book.title,
        book.author,
        book.format ?? '',
        _formatDate(book.addedDate),
        book.coverUrl ?? '',
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Generate filename with current date
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final filename = 'wingtip_library_$dateStr.csv';

    // Get temporary directory and create file
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, filename));
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Shares the exported CSV file using the system share sheet.
  Future<void> shareExportedCsv(String filePath) async {
    final xFile = XFile(filePath);
    await Share.shareXFiles(
      [xFile],
      subject: 'Wingtip Library Export',
    );
  }

  /// Formats a Unix timestamp to ISO 8601 date format (YYYY-MM-DD).
  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
