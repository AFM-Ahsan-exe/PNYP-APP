import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/public_profile.dart';
import '../providers/profile_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_list_tile.dart';

class MemberDirectoryScreen extends ConsumerStatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  ConsumerState<MemberDirectoryScreen> createState() =>
      _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends ConsumerState<MemberDirectoryScreen> {
  String _query = '';
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final directoryAsync = ref.watch(memberDirectoryProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: Text('Member Directory', style: AppTextStyles.headline),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search members by name, city, district...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  items: const [
                    DropdownMenuItem(value: 'approved', child: Text('Active')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(value: 'all', child: Text('All')),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: directoryAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading members...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(memberDirectoryProvider(_query)),
              ),
              data: (profiles) {
                var filtered = profiles;
                if (_query.isNotEmpty) {
                  filtered = filtered.where((p) {
                    final q = _query.toLowerCase();
                    return (p.fullName ?? '').toLowerCase().contains(q) ||
                        (p.city ?? '').toLowerCase().contains(q) ||
                        (p.district ?? '').toLowerCase().contains(q);
                  }).toList();
                }
                if (_statusFilter != null && _statusFilter != 'all') {
                  filtered = filtered
                      .where((p) => p.status.name == _statusFilter)
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No members found');
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(memberDirectoryProvider(_query)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final profile = filtered[index];
                      return _MemberTile(profile: profile);
                    },
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

class _MemberTile extends StatelessWidget {
  final PublicProfile profile;

  const _MemberTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.navyDeep.withValues(alpha: 0.1),
          child:
              profile.profilePictureUrl != null &&
                  profile.profilePictureUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    profile.profilePictureUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    cacheWidth: 96,
                    cacheHeight: 96,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navyDeep,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        _getInitials(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDeep,
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  _getInitials(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                  ),
                ),
        ),
        title: profile.fullName ?? 'Unknown Member',
        subtitle: _buildSubtitle(),
        trailing: StatusChip(label: _statusLabel(), compact: true),
      ),
    );
  }

  String _getInitials() {
    final name = profile.fullName ?? '';
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    final email = profile.fullName ?? '';
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (profile.membershipType != null) parts.add(_membershipTypeLabel());
    if (profile.city != null && profile.city!.isNotEmpty) {
      parts.add(profile.city!);
    }
    if (profile.district != null && profile.district!.isNotEmpty) {
      parts.add(profile.district!);
    }
    if (profile.province != null && profile.province!.isNotEmpty) {
      parts.add(profile.province!);
    }
    return parts.join(', ');
  }

  String _statusLabel() {
    switch (profile.status) {
      case AccountStatus.approved:
        return 'Active';
      case AccountStatus.pending:
        return 'Pending';
      case AccountStatus.rejected:
        return 'Rejected';
      case AccountStatus.suspended:
        return 'Suspended';
      case AccountStatus.expired:
        return 'Expired';
    }
  }

  String _membershipTypeLabel() {
    switch (profile.membershipType) {
      case 'youth_mpa':
        return 'Youth MPA';
      case 'youth_mna':
        return 'Youth MNA';
      case 'youth_senator':
        return 'Youth Senator';
      case 'youth_judge':
        return 'Youth Judge';
      default:
        return profile.membershipType ?? 'Member';
    }
  }
}
