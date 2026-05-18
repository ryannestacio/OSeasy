import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import 'app_surface_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.highlight = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      backgroundColor: highlight ? AppPalette.surfaceMuted : AppPalette.white,
      gradient: highlight
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor.withValues(alpha: 0.18), AppPalette.white],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const Spacer(),
              Icon(
                Icons.north_east_rounded,
                color: accentColor.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(title, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(color: AppPalette.black),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }
}
