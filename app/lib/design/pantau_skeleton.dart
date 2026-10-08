import 'package:flutter/material.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

class PantauSkeleton extends StatelessWidget {
  const PantauSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaceCardSkeleton(tokens: tokens),
        const SizedBox(height: WudgetTokens.space5),
        _ForecastCardSkeleton(tokens: tokens),
        const SizedBox(height: WudgetTokens.space5),
        const SectionLabel('Tujuh hari terakhir'),
        _WeekChartSkeleton(tokens: tokens),
        const SizedBox(height: WudgetTokens.space5),
        _CategoryListSkeleton(tokens: tokens),
      ],
    );
  }
}

class _PaceCardSkeleton extends StatelessWidget {
  const _PaceCardSkeleton({required this.tokens});
  final WudgetTokens tokens;

  @override
  Widget build(BuildContext context) {
    return WudgetCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ShimmerBox(width: 84, height: 84, tokens: tokens),
          const SizedBox(width: WudgetTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 100, height: 12, tokens: tokens),
                const SizedBox(height: WudgetTokens.space2),
                _ShimmerBox(width: double.infinity, height: 16, tokens: tokens),
                const SizedBox(height: WudgetTokens.space2),
                _ShimmerBox(width: 150, height: 12, tokens: tokens),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastCardSkeleton extends StatelessWidget {
  const _ForecastCardSkeleton({required this.tokens});
  final WudgetTokens tokens;

  @override
  Widget build(BuildContext context) {
    return WudgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 150, height: 14, tokens: tokens),
          const SizedBox(height: WudgetTokens.space3),
          _ShimmerBox(width: double.infinity, height: 120, tokens: tokens),
          const SizedBox(height: WudgetTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(width: 100, height: 12, tokens: tokens),
              _ShimmerBox(width: 80, height: 12, tokens: tokens),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekChartSkeleton extends StatelessWidget {
  const _WeekChartSkeleton({required this.tokens});
  final WudgetTokens tokens;

  @override
  Widget build(BuildContext context) {
    return WudgetCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          7,
          (i) =>
              _ShimmerBox(width: 20, height: 60 + (i % 3) * 20, tokens: tokens),
        ),
      ),
    );
  }
}

class _CategoryListSkeleton extends StatelessWidget {
  const _CategoryListSkeleton({required this.tokens});
  final WudgetTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: WudgetTokens.space2),
          child: Row(
            children: [
              _ShimmerBox(width: 32, height: 32, tokens: tokens),
              const SizedBox(width: WudgetTokens.space3),
              Expanded(
                child: _ShimmerBox(
                    width: double.infinity, height: 16, tokens: tokens),
              ),
              const SizedBox(width: WudgetTokens.space3),
              _ShimmerBox(width: 80, height: 16, tokens: tokens),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.tokens,
  });

  final double width;
  final double height;
  final WudgetTokens tokens;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.repeat();
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
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.tokens.surfaceMuted,
                widget.tokens.border,
                widget.tokens.surfaceMuted,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
