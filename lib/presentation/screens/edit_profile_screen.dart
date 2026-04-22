import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_states.dart';
import '../widgets/common_app_bar.dart';
import 'change_password_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'تعديل الملف الشخصي',
        showNotifications: false,
        showThemeToggle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return ListView(
                padding: AppSpacing.page,
                children: const [
                  AppErrorState(
                    title: 'يلزم تسجيل الدخول',
                    message: 'سجل الدخول أولًا لتعديل ملفك الشخصي.',
                  ),
                ],
              );
            }

            _seedControllers(profile);
            final avatar = _avatarUrl ?? profile.avatarUrl;

            return ListView(
              padding: AppSpacing.page,
              children: [
                AppCard(
                  usePanelColor: true,
                  borderRadius: AppRadius.panel,
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.subtleFill(isDark),
                            backgroundImage: (avatar != null && avatar.isNotEmpty)
                                ? NetworkImage(avatar)
                                : null,
                            child: (avatar == null || avatar.isEmpty)
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: AppColors.appBarForeground(isDark),
                                  )
                                : null,
                          ),
                          PositionedDirectional(
                            bottom: 0,
                            end: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.panelColor(isDark),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.borderColor(isDark),
                                ),
                              ),
                              child: IconButton(
                                iconSize: 18,
                                onPressed:
                                    _uploadingAvatar || _saving ? null : _pickAvatar,
                                icon: _uploadingAvatar
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.appBarForeground(isDark),
                                        ),
                                      )
                                    : const Icon(Icons.photo_camera_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName ?? 'مستخدم ترتيل',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary(isDark),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              profile.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary(isDark),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    hintText: 'اكتب اسمك',
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                TextField(
                  controller: _bioController,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'نبذة مختصرة',
                    hintText: 'اكتب نبذة بسيطة عنك (اختياري)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _saveProfile(profile),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ التغييرات'),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangePasswordScreen(
                                  email: profile.email,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.password_outlined),
                    label: const Text('تغيير كلمة المرور'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            padding: AppSpacing.page,
            children: [
              AppErrorState(
                title: 'تعذر تحميل ملفك',
                message: err.toString(),
                onRetry: () => ref.invalidate(profileProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _seedControllers(ProfileModel profile) {
    if (_nameController.text.isEmpty) {
      _nameController.text = profile.fullName ?? '';
    }
    if (_bioController.text.isEmpty) {
      _bioController.text = profile.bio ?? '';
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1200,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref.read(mediaRepositoryProvider).uploadBytes(
            bytes: bytes,
            filename: file.name,
          );
      setState(() => _avatarUrl = url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  Future<void> _saveProfile(ProfileModel profile) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الاسم لا يمكن أن يكون فارغًا.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = ProfileModel(
        id: profile.id,
        email: profile.email,
        fullName: name,
        avatarUrl: _avatarUrl ?? profile.avatarUrl,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        role: profile.role,
        country: profile.country,
        isVerified: profile.isVerified,
        status: profile.status,
        specialties: profile.specialties,
        socialLinks: profile.socialLinks,
        isPublicProfile: profile.isPublicProfile,
      );

      final ok = await ref.read(profileRepositoryProvider).updateProfile(updated);
      if (!mounted) return;

      if (ok) {
        ref.invalidate(profileProvider);
        ref.invalidate(userProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التغييرات بنجاح.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ التغييرات. حاول لاحقاً.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

