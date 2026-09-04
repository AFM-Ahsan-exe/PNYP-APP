import 'package:fl_chart/fl_chart.dart';
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
    ].where((e) => e.value > 0).toList();

    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Users by Role', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              'Distribution across all categories',
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (total == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No data yet')),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 340;
                  final donut = SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 52,
                            sections: entries
                                .map(
                                  (e) => PieChartSectionData(
                                    value: e.value.toDouble(),
                                    color: e.color,
                                    radius: 26,
                                    showTitle: false,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: AppTextStyles.statValue.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Total',
                              style: AppTextStyles.bodyMuted.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  final legend = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: e.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.label,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${e.value} (${(e.value / total * 100).toStringAsFixed(1)}%)',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        donut,
                        const SizedBox(height: 16),
                        legend,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      donut,
                      const SizedBox(width: 20),
                      Expanded(child: legend),
                    ],
                  );
                },
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