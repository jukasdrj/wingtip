import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wingtip/core/network_status_provider.dart';
import 'package:wingtip/core/theme.dart';

class NetworkStatusIndicator extends ConsumerWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.oledBlack,
            border: Border.all(
              color: AppTheme.textPrimary,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'OFFLINE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
