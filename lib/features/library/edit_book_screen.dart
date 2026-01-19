import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/database_provider.dart';

/// Screen for editing book metadata
class EditBookScreen extends ConsumerStatefulWidget {
  final Book book;

  const EditBookScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends ConsumerState<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _isbnController;
  late final TextEditingController _formatController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _isbnController = TextEditingController(text: widget.book.isbn);
    _formatController = TextEditingController(text: widget.book.format ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _formatController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Trigger haptic feedback
    HapticFeedback.lightImpact();

    try {
      final database = ref.read(databaseProvider);
      final success = await database.updateBook(
        isbn: _isbnController.text.trim(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        format: _formatController.text.trim().isEmpty
            ? null
            : _formatController.text.trim(),
        clearReviewNeeded: true,
      );

      if (!mounted) return;

      if (success) {
        // Trigger haptic feedback for success
        HapticFeedback.mediumImpact();

        // Show confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Book metadata updated',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.internationalOrange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(
                color: AppTheme.internationalOrange,
                width: 1,
              ),
            ),
          ),
        );

        // Navigate back
        Navigator.of(context).pop(true);
      } else {
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update book',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: AppTheme.internationalOrange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.internationalOrange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: Text(
          'Edit Book',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.internationalOrange,
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.internationalOrange,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            _buildTextField(
              controller: _titleController,
              label: 'TITLE',
              hint: 'Enter book title',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Author field
            _buildTextField(
              controller: _authorController,
              label: 'AUTHOR',
              hint: 'Enter author name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Author is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ISBN field (monospace)
            _buildTextField(
              controller: _isbnController,
              label: 'ISBN',
              hint: 'Enter ISBN',
              mono: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ISBN is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Format field (optional)
            _buildTextField(
              controller: _formatController,
              label: 'FORMAT',
              hint: 'Enter format (optional)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool mono = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: mono
              ? GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                )
              : GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
            filled: true,
            fillColor: AppTheme.oledBlack,
            border: const OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.borderGray,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.borderGray,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.internationalOrange,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.internationalOrange,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: AppTheme.internationalOrange,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.internationalOrange,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
