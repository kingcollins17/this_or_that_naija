import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChoicePanel extends StatelessWidget {
  final String text;
  final String banter;
  final double percentage;
  final bool isSelected;
  final bool hasVoted;
  final Color baseColor;
  final VoidCallback? onTap;

  const ChoicePanel({
    super.key,
    required this.text,
    required this.banter,
    required this.percentage,
    required this.isSelected,
    required this.hasVoted,
    required this.baseColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        child: Stack(
          children: [
            Container(color: baseColor),
            if (hasVoted)
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: (percentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (hasVoted) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
                      const SizedBox(height: 8),
                      Text(
                        banter,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ],
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                top: 16,
                right: 16,
                child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 30),
              ),
          ],
        ),
      ),
    );
  }
}
