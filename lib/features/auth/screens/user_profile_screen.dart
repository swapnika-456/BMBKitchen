import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../models/user.dart';
import '../../../services/api/organization_api_service.dart';
import '../controllers/auth_controller.dart';

/// Provider to fetch organization name if not directly present on the User model
final organizationDetailsProvider =
    FutureProvider.family<String?, String>((ref, orgId) async {
  if (orgId.isEmpty) return null;
  final orgService = ref.watch(organizationApiServiceProvider);
  final res = await orgService.getOrganizationById(orgId);
  if (res.success && res.data != null) {
    return res.data!['name'] as String?;
  }
  return null;
});

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;
  bool _isSendingReset = false;

  bool _canReadRoles(String role) {
    final r = role.toLowerCase().trim();
    return r == 'owner' || r == 'admin' || r == 'cto';
  }

  Future<void> _changePhoto(User user) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await picked.readAsBytes();
      final mFile = MultipartFile.fromBytes(bytes, filename: picked.name);

      await ref.read(authControllerProvider.notifier).uploadProfileImage(
            organizationId: user.organizationId,
            userId: user.id,
            file: mFile,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: AppColors.leaf,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // As per PDF/server audit: 500 fails because server image upload is unavailable
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Photo upload isn't available right now"),
            backgroundColor: AppColors.chilli,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _confirmResetPassword(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('We\'ll email a password reset link to ${user.email}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.tandoor),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSendingReset = true);
    try {
      final msg = await ref
          .read(authControllerProvider.notifier)
          .sendPasswordReset(user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Password reset link sent to your email.'),
            backgroundColor: AppColors.leaf,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request password reset: $e'),
            backgroundColor: AppColors.chilli,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.chilli),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: authState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.tandoor),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.chilli),
                const SizedBox(height: 12),
                Text('Failed to load profile: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).refreshUser(),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.tandoor),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No logged-in user found.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            );
          }

          final orgNameAsync = ref.watch(organizationDetailsProvider(user.organizationId));
          final orgName = user.organizationName ?? orgNameAsync.value ?? 'Organization';

          return RefreshIndicator(
            color: AppColors.tandoor,
            onRefresh: () => ref.read(authControllerProvider.notifier).refreshUser(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(context, user, orgName),
                      const SizedBox(height: 20),
                      _buildActionsCard(context, user),
                      const SizedBox(height: 20),
                      _buildPermissionsCard(context, user),
                      const SizedBox(height: 20),
                      _buildApiGapsNote(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, User user, String orgName) {
    final initials = user.userName.isNotEmpty
        ? user.userName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'U';

    final hasPhoto = user.profileImage?.url != null && user.profileImage!.url!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.tandoorSoft,
                    backgroundImage: hasPhoto ? NetworkImage(user.profileImage!.url!) : null,
                    child: !hasPhoto
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.tandoor,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                  if (_isUploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          user.userName.isNotEmpty ? user.userName : 'Unnamed User',
                          style: AppText.h2.copyWith(fontSize: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tandoorSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.tandoor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (user.specificRole != null &&
                            user.specificRole!.isNotEmpty &&
                            _canReadRoles(user.role))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.leafSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.specificRole!,
                              style: const TextStyle(
                                color: AppColors.leaf,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 15, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.email,
                            style: AppText.body.copyWith(color: AppColors.muted, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (user.phoneNo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 15, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.phoneNo,
                              style: AppText.body.copyWith(color: AppColors.muted, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 15, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            orgName,
                            style: AppText.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isUploadingPhoto ? null : () => _changePhoto(user),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Change photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isSendingReset ? null : () => _confirmResetPassword(user),
                  icon: const Icon(Icons.lock_reset_outlined, size: 16),
                  label: _isSendingReset
                      ? const Text('Sending link...')
                      : const Text('Change password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Session', style: AppText.bodyBold),
          const SizedBox(height: 8),
          Text(
            'Active session on BMB Kitchen Cloud. Log out to end this session on this device.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Log out'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chilli,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(BuildContext context, User user) {
    final permissions = user.permissions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_outlined, size: 20, color: AppColors.tandoor),
              const SizedBox(width: 8),
              Text('Your Access', style: AppText.h3.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Permissions granted to your account across platform modules.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (permissions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.role.toLowerCase() == 'owner'
                          ? 'Full administrative access granted by Owner role.'
                          : 'No granular module permissions explicitly assigned.',
                      style: AppText.caption.copyWith(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.paper),
                columns: const [
                  DataColumn(label: Text('Module', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Create', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Get', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Update', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: permissions.entries.map((entry) {
                  final module = entry.key;
                  final p = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(module, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(_buildTick(p.create)),
                      DataCell(_buildTick(p.get)),
                      DataCell(_buildTick(p.update)),
                      DataCell(_buildTick(p.delete)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTick(bool enabled) {
    if (enabled) {
      return const Icon(Icons.check_circle, size: 18, color: AppColors.leaf);
    }
    return const Icon(Icons.remove, size: 18, color: AppColors.line);
  }

  Widget _buildApiGapsNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Text('API Specification Notes', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• Updating user name, email, or phone is not supported by the backend auth API.\n'
            '• Photo deletion is not supported in the backend API (#7A supports upload only).\n'
            '• Password change triggers a reset link via #3 POST /api/auth/v1/forgot-password.',
            style: AppText.caption.copyWith(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
