import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../providers/opportunities_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  final String opportunityId;

  const OpportunityDetailScreen({super.key, required this.opportunityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(
      opportunityDetailProvider(opportunityId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity Details')),
      body: opportunityAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading opportunity details...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(opportunityDetailProvider(opportunityId)),
        ),
        data: (opportunity) {
          if (opportunity == null) {
            return const AppEmptyState(message: 'Opportunity not found');
          }
          final title = opportunity.title;
          final description = opportunity.description ?? 'No description';
          final organization = opportunity.organization ?? 'Unknown';
          final location = opportunity.location ?? '';
          final isRemote = opportunity.isRemote;
          final applyUrl = opportunity.applyUrl ?? '';
          final deadline = opportunity.deadline?.toDate();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(opportunityDetailProvider(opportunityId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  title,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  organization,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  value: isRemote ? 'Remote' : location,
                ),
                const SizedBox(height: 10),
                if (deadline != null)
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Deadline',
                    value: '${deadline.day}/${deadline.month}/${deadline.year}',
                  ),
                const SizedBox(height: 20),
                const Text('Description', style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(height: 1.6),
                ),
                const SizedBox(height: 24),
                if (applyUrl.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () =>
                        _trackClickAndOpen(context, opportunityId, applyUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Apply Now'),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _showApplyDialog(context, opportunityId),
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: const Text('Apply in App'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showApplyDialog(
    BuildContext context,
    String opportunityId,
  ) async {
    final motivationController = TextEditingController();
    final availabilityController = TextEditingController();
    final skillsController = TextEditingController();
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Apply for this Opportunity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: motivationController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivation',
                  hintText: 'Why do you want to volunteer? (min. 10 characters)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: availabilityController,
                decoration: const InputDecoration(
                  labelText: 'Availability',
                  hintText: 'e.g., Weekends, Evenings (min. 3 characters)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  hintText: 'e.g., Communication, First Aid',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final motivation = motivationController.text.trim();
                      final availability = availabilityController.text.trim();
                      if (motivation.length < 10) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Motivation must be at least 10 characters',
                            ),
                          ),
                        );
                        return;
                      }
                      if (availability.length < 3) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Availability must be at least 3 characters',
                            ),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final client = CloudFunctionsClient(
                          projectId: Firebase.app().options.projectId,
                          region: 'us-central1',
                        );
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          throw StateError('No authenticated user');
                        }
                        final idToken = await user.getIdToken();
                        await client.call('applyAsVolunteer', {
                          'opportunityId': opportunityId,
                          'motivation': motivation,
                          'availability': availability,
                          'skills': skillsController.text
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList(),
                        }, idToken);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(
                            dialogContext,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );
    }
  }

  Future<void> _trackClickAndOpen(
    BuildContext context,
    String opportunityId,
    String applyUrl,
  ) async {
    try {
      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        await client.call('trackOpportunityClick', {
          'opportunityId': opportunityId,
        }, idToken);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening application link...')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentBlue),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}