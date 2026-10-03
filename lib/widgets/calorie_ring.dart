import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/balance.dart';
import '../theme/app_theme.dart';

/// Hero circular calorie balance progress ring widget.
/// Meets R2 (progress rings, calorie typography), R8 (consumed vs target),
/// and visually differentiates Eaten, Burned, and Target to clearly illustrate Calorie Deficit.
class CalorieRing extends StatefulWidget {
  final Balance balance;
  final double size;

  const CalorieRing({
    super.key,
    required this.balance,
    this.size = 230,
  });

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _consumedAnimation;
  late Animation<double> _burnAnimation;
  double _oldConsumedProgress = 0.0;
  double _oldBurnProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _consumedAnimation = Tween<double>(
      begin: 0.0,
      end: widget.balance.consumedProgress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _burnAnimation = Tween<double>(
      begin: 0.0,
      end: widget.balance.burnProgress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _oldConsumedProgress = widget.balance.consumedProgress;
    _oldBurnProgress = widget.balance.burnProgress;
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance.consumedProgress != widget.balance.consumedProgress ||
        oldWidget.balance.burnProgress != widget.balance.burnProgress) {
      _oldConsumedProgress = oldWidget.balance.consumedProgress;
      _oldBurnProgress = oldWidget.balance.burnProgress;

      _consumedAnimation = Tween<double>(
        begin: _oldConsumedProgress,
        end: widget.balance.consumedProgress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _burnAnimation = Tween<double>(
        begin: _oldBurnProgress,
        end: widget.balance.burnProgress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = widget.balance.isOver;
    final deficitColor = isOver ? theme.colorScheme.error : AppTheme.primarySeed;

    final displayCalories = isOver
        ? widget.balance.overAmount.abs()
        : widget.balance.remaining.abs();

    final statusText = isOver ? 'kcal surplus' : 'kcal deficit';
    final semanticLabel = isOver
        ? '${widget.balance.overAmount} calories over target of ${widget.balance.target}'
        : '${widget.balance.remaining} calories remaining in deficit toward ${widget.balance.target} target';

    return Semantics(
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _DualRingPainter(
                          consumedProgress: _consumedAnimation.value,
                          burnProgress: _burnAnimation.value,
                          isOver: isOver,
                          consumedColor: AppTheme.consumedBlue,
                          burnColor: AppTheme.burnedOrange,
                          overColor: theme.colorScheme.error,
                          trackColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: deficitColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOver ? Icons.warning_amber_rounded : Icons.eco_rounded,
                              size: 13,
                              color: deficitColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOver ? 'Surplus' : 'Deficit',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: deficitColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          '$displayCalories',
                          key: ValueKey<int>(displayCalories),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: isOver ? theme.colorScheme.error : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        statusText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isOver ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Intuitive Legend showing Eaten (Blue), Burned (Orange), and Deficit (Green)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildLegendItem(
                    color: AppTheme.consumedBlue,
                    label: 'Eaten',
                    value: '${widget.balance.consumed} kcal',
                    theme: theme,
                  ),
                ),
                Container(width: 1, height: 20, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                Expanded(
                  child: _buildLegendItem(
                    color: AppTheme.burnedOrange,
                    label: 'Burned',
                    value: '${widget.balance.burned} kcal',
                    theme: theme,
                  ),
                ),
                Container(width: 1, height: 20, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                Expanded(
                  child: _buildLegendItem(
                    color: deficitColor,
                    label: isOver ? 'Surplus' : 'Deficit',
                    value: '${widget.balance.remaining} kcal',
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DualRingPainter extends CustomPainter {
  final double consumedProgress;
  final double burnProgress;
  final bool isOver;
  final Color consumedColor;
  final Color burnColor;
  final Color overColor;
  final Color trackColor;

  _DualRingPainter({
    required this.consumedProgress,
    required this.burnProgress,
    required this.isOver,
    required this.consumedColor,
    required this.burnColor,
    required this.overColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const outerStrokeWidth = 14.0;
    const innerStrokeWidth = 9.0;
    const gap = 4.0;

    final outerRadius = (size.width - outerStrokeWidth) / 2;
    final innerRadius = outerRadius - outerStrokeWidth / 2 - innerStrokeWidth / 2 - gap;

    // 1. Outer Track (Target base for Food Eaten)
    final outerTrackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, outerRadius, outerTrackPaint);

    // 2. Outer Progress Arc: Food Eaten / Consumed (Blue or Red if Over)
    final outerColor = isOver ? overColor : consumedColor;
    final outerSweep = 2 * math.pi * consumedProgress.clamp(0.0, 1.0);
    if (outerSweep > 0) {
      final outerProgressPaint = Paint()
        ..color = outerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,
        outerSweep,
        false,
        outerProgressPaint,
      );
    }

    // 3. Inner Track (Base for Workouts / Burned)
    final innerTrackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, innerRadius, innerTrackPaint);

    // 4. Inner Progress Arc: Calories Burned (Active Orange)
    final innerSweep = 2 * math.pi * burnProgress.clamp(0.0, 1.0);
    if (innerSweep > 0) {
      final innerProgressPaint = Paint()
        ..color = burnColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -math.pi / 2,
        innerSweep,
        false,
        innerProgressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DualRingPainter oldDelegate) {
    return oldDelegate.consumedProgress != consumedProgress ||
        oldDelegate.burnProgress != burnProgress ||
        oldDelegate.isOver != isOver ||
        oldDelegate.consumedColor != consumedColor ||
        oldDelegate.burnColor != burnColor;
  }
}

