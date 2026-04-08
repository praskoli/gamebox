import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/home/home_view_model.dart';
import '../../app/routing/route_names.dart';
import '../../platform/auth/google_sign_in_service.dart';
import '../../games/memory_match/presentation/parent_unlock_screen.dart';
import 'edit_player_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await GoogleSignInService.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.login,
          (route) => false,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openEditProfile(BuildContext context, HomeViewModel vm) async {
    final profile = vm.profile;
    if (profile == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditPlayerProfileScreen(
          initialProfile: profile,
        ),
      ),
    );

    if (result != null) {
      await vm.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = vm.profile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              /// 🔹 EDIT PROFILE
              _ActionCard(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle:
                'Update profile photo, name, mobile, and approval email.',
                onTap: () => _openEditProfile(context, vm),
              ),

              const SizedBox(height: 12),

              /// 🔹 PARENT CONTROLS
              _ActionCard(
                icon: Icons.lock_outline_rounded,
                title: 'Parent Controls',
                subtitle:
                'Manage unlock approvals and child play access.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ParentUnlockScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              /// 🔹 LOGOUT
              _ActionCard(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out from GameBox safely.',
                onTap: () => _logout(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF5B67F1).withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF5B67F1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}