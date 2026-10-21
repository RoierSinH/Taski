import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _initializedFields = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileController>().load();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncControllers(UserProfile? profile) {
    if (profile != null && !_initializedFields) {
      _nameController.text = profile.displayName ?? '';
      _bioController.text = profile.bio ?? '';
      _initializedFields = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<ProfileController>();
    final success = await controller.saveProfile(
      displayName: _nameController.text,
      bio: _bioController.text,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado correctamente'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;

    _syncControllers(profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: controller.loading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundImage: profile?.avatarUrl == null ||
                                  profile!.avatarUrl!.isEmpty
                              ? null
                              : NetworkImage(profile.avatarUrl!),
                          child: profile?.avatarUrl == null ||
                                  profile!.avatarUrl!.isEmpty
                              ? const Icon(Icons.person, size: 52)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const Key('profile_change_avatar'),
                          onPressed: controller.loading
                              ? null
                              : () => controller.pickAndChangeAvatar(),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Cambiar fotografía'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile?.email ?? '',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 24),
                        if (controller.error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              controller.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        TextFormField(
                          key: const Key('profile_display_name'),
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre para mostrar',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _bioController,
                          builder: (context, value, _) {
                            final currentLength = value.text.length;
                            final isOverLimit =
                                currentLength > UserProfile.maxBioLength;
                            return TextFormField(
                              key: const Key('profile_bio'),
                              controller: _bioController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Biografía (opcional)',
                                hintText:
                                    'Cuéntanos algo sobre ti (máx. 120 caracteres)',
                                prefixIcon: const Icon(Icons.info_outline),
                                border: const OutlineInputBorder(),
                                counterText:
                                    '$currentLength/${UserProfile.maxBioLength} caracteres',
                                counterStyle: TextStyle(
                                  color: isOverLimit ? Colors.red : null,
                                  fontWeight: isOverLimit
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              validator: UserProfile.validateBio,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            key: const Key('profile_save_button'),
                            onPressed: controller.loading ? null : _save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
