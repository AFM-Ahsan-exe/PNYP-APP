import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Shows the signed-in admin (from the existing auth feature - not
/// fabricated data) with a sign-out action.
class AdminProfileMenu extends ConsumerWidget {
  const AdminProfileMenu({super.key});

  String _initials(AppUser? user) {
    if (user == null) return '?';
    final displayName = user.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return PopupMenuButton<String>(
      tooltip: 'Admin menu',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'my_profile') {
          context.push('/profile');
        } else if (value == 'sign_out') {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) context.go('/login');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user?.displayName ?? 'Admin',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(user?.email ?? '', style: AppTextStyles.caption),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'my_profile',
          child: Row(
            children: [
              Icon(Icons.person_rounded, size: 18),
              SizedBox(width: 10),
              Text('My Profile'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'sign_out',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text('Sign Out'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.navyDarkest,
        backgroundImage:
            (user?.profilePictureUrl != null &&
                user!.profilePictureUrl!.isNotEmpty)
            ? NetworkImage(user.profilePictureUrl!)
            : null,
        child:
            (user?.profilePictureUrl == null ||
                user!.profilePictureUrl!.isEmpty)
            ? Text(
                _initials(user),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
}