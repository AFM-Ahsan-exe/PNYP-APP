import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../../domain/entities/volunteer.dart';
import '../providers/volunteers_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';

class VolunteerApplicationsScreen extends ConsumerWidget {
  const VolunteerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(volunteersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Volunteer Applications')),
      body: applications.when(
        loading: () =>
            const AppLoadingState(message: 'Loading applications...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(volunteersProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No volunteer applications yet',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(volunteersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _ApplicationTile(application: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationTile extends ConsumerWidget {
  final Volunteer application;

  const _ApplicationTile({required this.application});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityId = application.opportunityId;
    final status = application.status;
    final appliedAt = application.appliedAt?.toDate() ?? DateTime.now();

    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _statusColor(status).withValues(alpha: 0.1),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: _statusColor(status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Opportunity: ${opportunityId.isEmpty ? 'Unknown' : opportunityId.substring(0, opportunityId.length < 10 ? opportunityId.length : 10)}...',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Applied: ${appliedAt.day.toString().padLeft(2, '0')}/${appliedAt.month.toString().padLeft(2, '0')}/${appliedAt.year} • Status: ${_statusLabel(status)}',
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              StatusChip(label: _statusLabel(status), compact: true),
              if (status == 'pending') ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  onPressed: () async {
                    final confirm = await showAppConfirmDialog(
                      context,
                      title: 'Withdraw Application',
                      message:
                          'Are you sure you want to withdraw this application?',
                      isDestructive: true,
                    );
                    if (confirm == true && context.mounted) {
                      try {
                        await ref
                            .read(withdrawVolunteerApplicationProvider)
                            .call(application.id);
                        ref.invalidate(volunteersProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Application withdrawn'),
                            ),
                          );
                        }
                        unawaited(
                          ActivityLogger.logAdmin(
                            title: 'Volunteer application withdrawn',
                            type: 'volunteer',
                            subtitle: application.id,
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
                  tooltip: 'Withdraw',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.accentBlue;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}
