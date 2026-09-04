import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/dashboard_stats.dart';

class BreakdownChart extends StatelessWidget {
  final DashboardStats stats;

  const BreakdownChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = <_ChartEntry>[
      _ChartEntry('Members', stats.totalMembers, AppColors.chartSeries[0]),
      _ChartEntry(
        'Volunteers',
        stats.totalVolunteers,
        AppColors.chartSeries[1],
      ),
      _ChartEntry(
        'Coordinators',
        stats.totalCoordinators,
        AppColors.chartSeries[2],
      ),
      _ChartEntry(
        'Pending Apps',
        stats.pendingApplications,
        AppColors.chartSeries[3],
      ),
      _ChartEntry(
        'Opportunities',
        stats.activeOpportunities,
        AppColors.chartSeries[4],
      ),
    ];

    final maxValue = entries.fold<int>(
      1,
      (max, e) => e.value > max ? e.value : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: AppTextStyles.title),
            const SizedBox(height: 16),
            ...entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BarRow(entry: e, maxValue: maxValue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartEntry {
  final String label;
  final int value;
  final Color color;

  const _ChartEntry(this.label, this.value, this.color);
}

class _BarRow extends StatelessWidget {
  final _ChartEntry entry;
  final int maxValue;

  const _BarRow({required this.entry, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue == 0 ? 0.0 : entry.value / maxValue;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            entry.label,
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 8, color: AppColors.surfaceMuted),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Container(
                          height: 8,
                          width: constraints.maxWidth * value,
                          color: entry.color,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '${entry.value}',
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
