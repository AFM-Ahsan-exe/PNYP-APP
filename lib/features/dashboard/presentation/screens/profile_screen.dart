import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/member_providers.dart';

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
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Could not load your profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(memberUserProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No profile data found'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(memberUserProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.navyDeep.withValues(alpha: 0.1),
                    child: Text(
                      _getInitials(user),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDeep,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Personal Information',
                  children: [
                    _ProfileRow(label: 'Full Name', value: user.fullName ?? 'Not provided'),
                    _ProfileRow(label: 'Father Name', value: user.fatherName ?? 'Not provided'),
                    _ProfileRow(label: 'CNIC', value: _maskCnic(user)),
                    _ProfileRow(label: 'Date of Birth', value: _formatDate(user.dateOfBirth?.toDate())),
                    _ProfileRow(label: 'Gender', value: _genderLabel(user.gender)),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileSection(
                  title: 'Contact Information',
                  children: [
                    _ProfileRow(label: 'Email', value: user.email ?? 'Not provided'),
                    _ProfileRow(label: 'Phone', value: user.phone ?? 'Not provided'),
                    _ProfileRow(label: 'Province', value: user.province ?? 'Not provided'),
                    _ProfileRow(label: 'District', value: user.district ?? 'Not provided'),
                    _ProfileRow(label: 'City', value: user.city ?? 'Not provided'),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileSection(
                  title: 'Professional Details',
                  children: [
                    _ProfileRow(label: 'Education', value: user.education ?? 'Not provided'),
                    _ProfileRow(label: 'Employment', value: user.employment ?? 'Not provided'),
                    _ProfileRow(label: 'Skills', value: user.skills.isEmpty ? 'Not provided' : user.skills.join(', ')),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileSection(
                  title: 'Emergency Contact',
                  children: [
                    _ProfileRow(label: 'Name', value: user.emergencyContactName ?? 'Not provided'),
                    _ProfileRow(label: 'Phone', value: user.emergencyContactPhone ?? 'Not provided'),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileSection(
                  title: 'Account Information',
                  children: [
                    _ProfileRow(label: 'Status', value: _statusLabel(user.status)),
                    _ProfileRow(label: 'Membership Type', value: _membershipTypeLabel(user.membershipType)),
                    _ProfileRow(label: 'Member ID', value: user.membershipId ?? 'Not assigned'),
                    _ProfileRow(label: 'Referral Source', value: user.referralSource?.isNotEmpty == true ? user.referralSource! : 'Not provided'),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
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

  String _maskCnic(AppUser user) {
    return '*****';
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

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
