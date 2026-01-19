import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG bookshelf illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.borderGray,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(16),
            child: SvgPicture.asset(
              'assets/images/empty_bookshelf.svg',
              colorFilter: const ColorFilter.mode(
                AppTheme.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Empty state text
          Text(
            '0 Books. Tap [O] to scan.',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
