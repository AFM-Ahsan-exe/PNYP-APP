import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/dashboard_stats.dart';

/// A simple horizontal-bar breakdown of the real counts in [stats].
///
/// Deliberately not a fabricated time-series/trend chart: there is no
/// historical data source in the project yet, so this only visualizes
/// counts that are actually known right now.
class BreakdownChart extends StatelessWidget {
  final DashboardStats stats;

  const BreakdownChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = <_ChartEntry>[
      _ChartEntry('Members', stats.totalMembers, AppColors.chartSeries[0]),
      _ChartEntry('Volunteers', stats.totalVolunteers, AppColors.chartSeries[1]),
      _ChartEntry('Coordinators', stats.totalCoordinators, AppColors.chartSeries[2]),
      _ChartEntry('Pending Apps', stats.pendingApplications, AppColors.chartSeries[3]),
      _ChartEntry('Opportunities', stats.activeOpportunities, AppColors.chartSeries[4]),
    ];

    final maxValue = entries.fold<int>(
      1,
      (max, e) => e.value > max ? e.value : max,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview Breakdown', style: AppTextStyles.title),
          const SizedBox(height: 20),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BarRow(entry: e, maxValue: maxValue),
              )),
        ],
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
          width: 110,
          child: Text(entry.label, style: AppTextStyles.bodyMuted),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 10, color: AppColors.surfaceMuted),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Container(
                          height: 10,
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
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            '${entry.value}',
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
