import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../route_names.dart';
import '../auth/google_sign_in_service.dart';
import '../home/home_view_model.dart';
import '../memory_match/presentation/parent_unlock_screen.dart';
import 'edit_player_profile_screen.dart';

class PlayerProfileTabScreen extends StatelessWidget {
  const PlayerProfileTabScreen({super.key});

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
          return const Center(child: CircularProgressIndicator());
        }

        final profile = vm.profile;
        if (profile == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                vm.errorMessage ?? 'Profile not available.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final initials = _buildInitials(profile.displayName);
        final otpDestination = profile.preferredOtpDestination;

        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFFECE1FA),
                      backgroundImage: profile.photoUrl.trim().isNotEmpty
                          ? NetworkImage(profile.photoUrl)
                          : null,
                      child: profile.photoUrl.trim().isEmpty
                          ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C1FB1),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.displayName.trim().isEmpty
                          ? 'Player'
                          : profile.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      otpDestination.isEmpty
                          ? 'No approval email configured'
                          : 'OTP goes to: $otpDestination',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: otpDestination.isEmpty
                            ? Colors.redAccent
                            : const Color(0xFF6B7280),
                        fontWeight: otpDestination.isEmpty
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (profile.temporaryEmail.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Temporary email is currently overriding primary approval email.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      profile.mobileNumber.isEmpty
                          ? 'No mobile added'
                          : profile.mobileNumber,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.email.isEmpty
                          ? 'No auth email available'
                          : 'Auth Email: ${profile.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (profile.loginEmail.trim().isNotEmpty &&
                        profile.loginEmail.trim() != profile.email.trim()) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Login / Recovery Email: ${profile.loginEmail}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _ActionCard(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle:
                'Update profile photo, name, mobile, parent approval email, and temporary email.',
                onTap: () => _openEditProfile(context, vm),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.lock_outline_rounded,
                title: 'Parent Controls',
                subtitle: 'Manage unlock approvals and child play access.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ParentUnlockScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.refresh_rounded,
                title: 'Refresh Profile',
                subtitle: 'Reload the latest player profile and rewards.',
                onTap: vm.refresh,
              ),
              const SizedBox(height: 12),
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

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
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
            const SizedBox(width: 8),
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