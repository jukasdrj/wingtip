import 'package:shared_preferences/shared_preferences.dart';
import 'sort_service.dart';

/// Provider for initializing sort service
/// This should be overridden where SharedPreferences is available
Future<SortService> createSortService() async {
  final prefs = await SharedPreferences.getInstance();
  return SortService(prefs);
}
