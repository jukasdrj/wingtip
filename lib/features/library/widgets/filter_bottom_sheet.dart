import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../filter_model.dart';
import '../library_provider.dart';

/// Bottom sheet for advanced library filters
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late BookFormat? _selectedFormat;
  late ReviewStatus? _selectedReviewStatus;
  late DateRange _selectedDateRange;
  late DateTime? _customStartDate;
  late DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(filterStateProvider);
    _selectedFormat = currentFilters.format;
    _selectedReviewStatus = currentFilters.reviewStatus;
    _selectedDateRange = currentFilters.dateRange;
    _customStartDate = currentFilters.customStartDate;
    _customEndDate = currentFilters.customEndDate;
  }

  void _applyFilters() {
    HapticFeedback.lightImpact();

    ref.read(filterStateProvider.notifier).setFormat(_selectedFormat);
    ref.read(filterStateProvider.notifier).setReviewStatus(_selectedReviewStatus);
    ref.read(filterStateProvider.notifier).setDateRange(
      _selectedDateRange,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );

    Navigator.of(context).pop();
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedFormat = null;
      _selectedReviewStatus = null;
      _selectedDateRange = DateRange.allTime;
      _customStartDate = null;
      _customEndDate = null;
    });

    ref.read(filterStateProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.oledBlack,
        border: Border(
          top: BorderSide(color: AppTheme.borderGray, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.internationalOrange),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: AppTheme.borderGray,
            ),

            // Filter options
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Format filter
                      _buildFilterSection(
                        title: 'Format',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              isSelected: _selectedFormat == null,
                              onTap: () {
                                setState(() {
                                  _selectedFormat = null;
                                });
                              },
                            ),
                            ...BookFormat.values.map((format) {
                              return _buildFilterChip(
                                label: format.label,
                                isSelected: _selectedFormat == format,
                                onTap: () {
                                  setState(() {
                                    _selectedFormat = format;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Review status filter
                      _buildFilterSection(
                        title: 'Review Status',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              isSelected: _selectedReviewStatus == null,
                              onTap: () {
                                setState(() {
                                  _selectedReviewStatus = null;
                                });
                              },
                            ),
                            ...ReviewStatus.values.map((status) {
                              return _buildFilterChip(
                                label: status.label,
                                isSelected: _selectedReviewStatus == status,
                                onTap: () {
                                  setState(() {
                                    _selectedReviewStatus = status;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Date range filter
                      _buildFilterSection(
                        title: 'Date Range',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DateRange.values.map((range) {
                            return _buildFilterChip(
                              label: range.label,
                              isSelected: _selectedDateRange == range,
                              onTap: () {
                                setState(() {
                                  _selectedDateRange = range;
                                  if (range != DateRange.custom) {
                                    _customStartDate = null;
                                    _customEndDate = null;
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),

                      // Custom date range picker (shown when Custom is selected)
                      if (_selectedDateRange == DateRange.custom) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePickerButton(
                                label: 'Start Date',
                                date: _customStartDate,
                                onTap: () => _selectStartDate(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDatePickerButton(
                                label: 'End Date',
                                date: _customEndDate,
                                onTap: () => _selectEndDate(context),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.internationalOrange,
                  foregroundColor: AppTheme.textPrimary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: AppTheme.internationalOrange,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.internationalOrange.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.internationalOrange : AppTheme.borderGray,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.internationalOrange : AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.borderGray.withValues(alpha: 0.3),
          border: Border.all(
            color: date != null ? AppTheme.internationalOrange : AppTheme.borderGray,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.month}/${date.day}/${date.year}'
                  : 'Select',
              style: TextStyle(
                color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: _customEndDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.internationalOrange,
              onPrimary: AppTheme.textPrimary,
              surface: AppTheme.borderGray,
              onSurface: AppTheme.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.oledBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? DateTime.now(),
      firstDate: _customStartDate ?? DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.internationalOrange,
              onPrimary: AppTheme.textPrimary,
              surface: AppTheme.borderGray,
              onSurface: AppTheme.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.oledBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customEndDate = picked;
      });
    }
  }
}
