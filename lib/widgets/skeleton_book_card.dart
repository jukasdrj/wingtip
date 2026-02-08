import 'package:flutter/material.dart';
import 'package:wingtip/core/theme.dart';

class SkeletonBookCard extends StatefulWidget {
  const SkeletonBookCard({super.key});

  @override
  State<SkeletonBookCard> createState() => _SkeletonBookCardState();
}

class _SkeletonBookCardState extends State<SkeletonBookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderGray, width: 1),
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFF1C1C1E), // base - borderGray
                Color(0xFF2C2C2E), // highlight - slightly lighter
                Color(0xFF1C1C1E), // base
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              // Cover area placeholder (takes most of the card)
              const Expanded(flex: 4, child: SizedBox()),
              // Title placeholder bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Author placeholder bar (shorter)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 24, bottom: 8),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1 / 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 9,
      itemBuilder: (context, index) => const SkeletonBookCard(),
    );
  }
}
