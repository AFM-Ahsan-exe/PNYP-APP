import '../../../notifications/presentation/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../providers/member_providers.dart';
import '../widgets/admin_profile_menu.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';

class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(memberUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'PYNP Member Portal',
          child: const Text('PYNP Member Portal'),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Notifications',
            child: Consumer(
              builder: (context, ref, _) {
                                final unreadAsync =
                    ref.watch(unreadNotificationCountStreamProvider);
                final count = unreadAsync.asData?.value ?? 0;

                return Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          const AdminProfileMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: userAsync.when(
        loading: () => const AppLoadingState(message: 'Loading profile...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(memberUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return const AppEmptyState(message: 'No user data found');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(memberUserProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WelcomeBanner(user: user),
                const SizedBox(height: 16),
                _MembershipCard(user: user),
                const SizedBox(height: 16),
                _QuickActions(user: user),
                const SizedBox(height: 16),
                _RecentActivity(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final AppUser user;

  const _WelcomeBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expiry = user.membershipExpiryDate?.toDate();
    final isExpired = expiry?.isBefore(now) ?? false;
    final daysUntilExpiry = expiry?.difference(now).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage:
                (user.profilePictureUrl != null &&
                    user.profilePictureUrl!.isNotEmpty)
                ? NetworkImage(user.profilePictureUrl!)
                : null,
            child:
                (user.profilePictureUrl == null ||
                    user.profilePictureUrl!.isEmpty)
                ? Text(
                    _getInitials(user),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.fullName ?? user.displayName ?? 'Member'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.membershipId ?? 'Membership pending',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                if (isExpired)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Membership expired',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (daysUntilExpiry != null && daysUntilExpiry <= 30)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Expires in $daysUntilExpiry days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(AppUser user) {
    final name = user.fullName ?? user.displayName;
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}

class _MembershipCard extends StatelessWidget {
  final AppUser user;

  const _MembershipCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final expiry = user.membershipExpiryDate?.toDate();
    final now = DateTime.now();
    final isExpired = expiry != null && expiry.isBefore(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_membership_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Membership Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Status', value: _statusLabel(user.status)),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Type',
              value: _membershipTypeLabel(user.membershipType),
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Member ID',
              value: user.membershipId ?? 'Not assigned',
            ),
            const SizedBox(height: 6),
            if (user.membershipStartDate != null)
              _DetailRow(
                label: 'Started',
                value: _formatDate(user.membershipStartDate!.toDate()),
              ),
            if (expiry != null) ...[
              const SizedBox(height: 6),
              _DetailRow(
                label: 'Expires',
                value: _formatDate(expiry),
                valueColor: isExpired ? AppColors.error : null,
              ),
            ],
            if (isExpired) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/renew-membership'),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Renew Membership'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(AccountStatus status) {
    switch (status) {
      case AccountStatus.approved:
        return 'Active';
      case AccountStatus.pending:
        return 'Pending Approval';
      case AccountStatus.rejected:
        return 'Rejected';
      case AccountStatus.suspended:
        return 'Suspended';
      case AccountStatus.expired:
        return 'Expired';
    }
  }

  String _membershipTypeLabel(String? type) {
    switch (type) {
      case 'youth_mpa':
        return 'Youth MPA';
      case 'youth_mna':
        return 'Youth MNA';
      case 'youth_senator':
        return 'Youth Senator';
      case 'youth_judge':
        return 'Youth Judge';
      default:
        return type ?? 'Not assigned';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final AppUser user;

  const _QuickActions({required this.user});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.person_outline_rounded,
        label: 'My Profile',
        onTap: () => context.push('/profile'),
      ),
      _ActionItem(
        icon: Icons.people_outline_rounded,
        label: 'Members',
        onTap: () => context.push('/members'),
      ),
      _ActionItem(
        icon: Icons.refresh_rounded,
        label: 'Renew Membership',
        onTap: () => context.push('/renew-membership'),
      ),
      _ActionItem(
        icon: Icons.description_outlined,
        label: 'Documents',
        onTap: () => context.push('/documents'),
      ),
      _ActionItem(
        icon: Icons.event_outlined,
        label: 'Events',
        onTap: () => context.push('/events'),
      ),
      _ActionItem(
        icon: Icons.article_outlined,
        label: 'News',
        onTap: () => context.push('/news'),
      ),
      _ActionItem(
        icon: Icons.work_outline_rounded,
        label: 'Opportunities',
        onTap: () => context.push('/opportunities'),
      ),
      _ActionItem(
        icon: Icons.photo_library_outlined,
        label: 'Gallery',
        onTap: () => context.push('/gallery'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.title),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: actions,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTextStyles.listTitle.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: AppTextStyles.title),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Activity feed coming soon',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}