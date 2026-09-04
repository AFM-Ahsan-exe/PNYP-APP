import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/member_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(memberUserProvider);

        return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
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
            return const AppEmptyState(message: 'No profile data found');
          }
          final completion = _calculateCompletion(user);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(memberUserProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.navyDeep.withValues(
                          alpha: 0.1,
                        ),
                        child: _buildProfilePicture(user),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () => context.push('/profile/edit'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ProfileCompletionIndicator(completion: completion),
                const SizedBox(height: 20),
                _ProfileSection(
                  title: 'Personal Information',
                  children: [
                    _ProfileRow(
                      label: 'Full Name',
                      value: user.fullName ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'Father Name',
                      value: user.fatherName ?? 'Not provided',
                    ),
                    _ProfileRow(label: 'CNIC', value: _maskCnic(user)),
                    _ProfileRow(
                      label: 'Date of Birth',
                      value: _formatDate(user.dateOfBirth?.toDate()),
                    ),
                    _ProfileRow(
                      label: 'Gender',
                      value: _genderLabel(user.gender),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Contact Information',
                  children: [
                    _ProfileRow(
                      label: 'Email',
                      value: user.email ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'Phone',
                      value: user.phone ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'Province',
                      value: user.province ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'District',
                      value: user.district ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'City',
                      value: user.city ?? 'Not provided',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Professional Details',
                  children: [
                    _ProfileRow(
                      label: 'Education',
                      value: user.education ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'Employment',
                      value: user.employment ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'Skills',
                      value: user.skills.isEmpty
                          ? 'Not provided'
                          : user.skills.join(', '),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Emergency Contact',
                  children: [
                    _ProfileRow(
                      label: 'Name',
                      value: user.emergencyContactName ?? 'Not provided',
                    ),
                    _ProfileRow(
                      label: 'Phone',
                      value: _maskPhone(user.emergencyContactPhone),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Account Information',
                  children: [
                    _ProfileRow(
                      label: 'Status',
                      value: _statusLabel(user.status),
                    ),
                    _ProfileRow(
                      label: 'Membership Type',
                      value: _membershipTypeLabel(user.membershipType),
                    ),
                    _ProfileRow(
                      label: 'Member ID',
                      value: user.membershipId ?? 'Not assigned',
                    ),
                    _ProfileRow(
                      label: 'Referral Source',
                      value: user.referralSource?.isNotEmpty == true
                          ? user.referralSource!
                          : 'Not provided',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyDarkest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePicture(AppUser user) {
    if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          user.profilePictureUrl!,
          width: 112,
          height: 112,
          fit: BoxFit.cover,
          cacheWidth: 224,
          cacheHeight: 224,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.navyDeep,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Text(
              _getInitials(user),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDeep,
              ),
            );
          },
        ),
      );
    }
    return Text(
      _getInitials(user),
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.navyDeep,
      ),
    );
  }

  double _calculateCompletion(AppUser user) {
    int filled = 0;
    int total = 8;
    if (user.fullName != null && user.fullName!.isNotEmpty) filled++;
    if (user.phone != null && user.phone!.isNotEmpty) filled++;
    if (user.email != null && user.email!.isNotEmpty) filled++;
    if (user.province != null && user.province!.isNotEmpty) filled++;
    if (user.education != null && user.education!.isNotEmpty) filled++;
    if (user.employment != null && user.employment!.isNotEmpty) filled++;
    if (user.emergencyContactName != null &&
        user.emergencyContactName!.isNotEmpty) {
      filled++;
    }
    if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
      filled++;
    }
    return filled / total;
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

  String _maskCnic(AppUser user) {
    return '*****';
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'Not provided';
    if (phone.length <= 4) return '****';
    final visible = phone.substring(phone.length - 4);
    return '****$visible';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not provided';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _genderLabel(String? gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return gender ?? 'Not provided';
    }
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
}

class _ProfileCompletionIndicator extends StatelessWidget {
  final double completion;

  const _ProfileCompletionIndicator({required this.completion});

  @override
  Widget build(BuildContext context) {
    final percentage = (completion * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Profile Completion',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completion,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              completion == 1.0 ? AppColors.success : AppColors.accentBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.listTitle.copyWith(
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
