import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/admin_member.dart';

class RecentRegistrationsTable extends StatelessWidget {
  final List<AdminMember> members;

  const RecentRegistrationsTable({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Registrations', style: AppTextStyles.title),
            const SizedBox(height: 16),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No registrations yet')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  headingTextStyle: AppTextStyles.bodyMuted.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  dataTextStyle: AppTextStyles.body.copyWith(fontSize: 13),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: members
                      .map(
                        (member) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                member.name.isNotEmpty
                                    ? member.name
                                    : 'Unnamed',
                              ),
                            ),
                            DataCell(Text(member.email)),
                            DataCell(Text(member.role)),
                            DataCell(Text(_formatDate(member.createdAt))),
                            DataCell(_StatusChip(status: member.status)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _StatusChip extends StatelessWidget {
  final AccountStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AccountStatus.approved => (AppColors.success, 'Active'),
      AccountStatus.pending => (AppColors.warning, 'Pending'),
      AccountStatus.rejected => (AppColors.error, 'Rejected'),
      AccountStatus.suspended => (AppColors.error, 'Suspended'),
      AccountStatus.expired => (AppColors.textSecondary, 'Expired'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}