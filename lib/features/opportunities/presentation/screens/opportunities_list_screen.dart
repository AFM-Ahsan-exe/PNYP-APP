import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunities_providers.dart';

class OpportunitiesListScreen extends ConsumerWidget {
  const OpportunitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(opportunitiesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities')),
      body: opportunities.when(
        loading: () => const AppLoadingState(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  'Could not load opportunities',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(opportunitiesStreamProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: const AppEmptyState(
                message: 'No opportunities available',
                icon: Icons.work_outline_rounded,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(opportunitiesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _OpportunityTile(opportunity: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _OpportunityTile extends StatelessWidget {
  final Opportunity opportunity;

  const _OpportunityTile({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final title = opportunity.title;
    final description = opportunity.description ?? '';
    final location = opportunity.location ?? '';
    final deadline = opportunity.deadline?.toDate();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.navyDeep.withValues(alpha: 0.1),
          child: const Icon(
            Icons.work_outline_rounded,
            color: AppColors.navyDeep,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description.length > 80
                  ? '${description.substring(0, 80)}...'
                  : description,
            ),
            const SizedBox(height: 4),
            Text(
              '$location${deadline != null ? " • Deadline: ${deadline.day}/${deadline.month}/${deadline.year}" : ""}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () => context.push('/opportunities/${opportunity.id}'),
      ),
    );
  }
}
