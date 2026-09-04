import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunities_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';

class AdminOpportunitiesScreen extends ConsumerStatefulWidget {
  const AdminOpportunitiesScreen({super.key});

  @override
  ConsumerState<AdminOpportunitiesScreen> createState() =>
      _AdminOpportunitiesScreenState();
}

class _AdminOpportunitiesScreenState
    extends ConsumerState<AdminOpportunitiesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final opportunitiesAsync = ref.watch(adminOpportunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Opportunities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/opportunities/new'),
            tooltip: 'Create Opportunity',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search opportunities...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: opportunitiesAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading opportunities...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(adminOpportunitiesProvider),
              ),
              data: (items) {
                var filtered = items;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (o) =>
                            o.title.toLowerCase().contains(_query) ||
                            (o.organization ?? '').toLowerCase().contains(
                              _query,
                            ),
                      )
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No opportunities yet');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminOpportunitiesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _OpportunityTile(opportunity: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityTile extends ConsumerWidget {
  final Opportunity opportunity;

  const _OpportunityTile({required this.opportunity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = opportunity.title;
    final status = opportunity.status ?? 'active';

    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${opportunity.organization ?? 'Unknown'} • ${_statusLabel(status)}',
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              StatusChip(label: _statusLabel(status), compact: true),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    context.push('/opportunities/${opportunity.id}/edit'),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final confirm = await showAppConfirmDialog(
                    context,
                    title: 'Delete Opportunity',
                    message: 'Delete "$title"?',
                    isDestructive: true,
                  );
                  if (confirm == true && context.mounted) {
                    try {
                      await ref
                          .read(deleteOpportunityProvider)
                          .call(opportunity.id);
                      ref.invalidate(adminOpportunitiesProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opportunity deleted')),
                        );
                      }
                      unawaited(
                        ActivityLogger.logAdmin(
                          title: 'Opportunity deleted',
                          type: 'content',
                          subtitle: opportunity.id,
                        ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  }
                },
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'paused':
        return 'Paused';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}
