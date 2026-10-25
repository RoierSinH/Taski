import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'reset_password_page.dart';

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
  bool _deletingAccount = false;

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

  /// Paso 5 (Parte 10): Integrar una confirmación consciente antes de eliminar la cuenta
  Future<void> _confirmAndDeleteAccount() async {
    if (_deletingAccount) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        title: const Text('Eliminar mi cuenta permanentemente'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta acción es irreversible. Al confirmar, se ejecutará la secuencia de limpieza en el servidor:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('• Se eliminarán todos tus archivos en el bucket privado task-attachments.'),
              Text('• Se eliminará tu fotografía de perfil en el bucket avatars.'),
              Text('• Se borrarán tus tareas, subtareas, categorías y metadatos en PostgreSQL.'),
              Text('• Se eliminará tu identidad en Supabase Auth y se cerrará tu sesión local.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            key: const Key('confirm_delete_account_dialog_button'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sí, eliminar mi cuenta'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      final authService = AuthService(Supabase.instance.client);
      await authService.solicitarEliminacion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta y archivos eliminados correctamente.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.classifyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingAccount = false);
      }
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
                          onPressed: controller.loading || _deletingAccount
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
                            onPressed: controller.loading || _deletingAccount
                                ? null
                                : _save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Guardar'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('profile_change_password_button'),
                            onPressed: controller.loading || _deletingAccount
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ResetPasswordPage(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.lock_reset),
                            label: const Text('Cambiar mi contraseña'),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.security_outlined, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Zona de seguridad de la cuenta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Puedes solicitar la eliminación definitiva de tu cuenta, '
                                'tareas, galería de evidencias en Storage y avatar.',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: const Key('profile_delete_account_button'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  onPressed: controller.loading || _deletingAccount
                                      ? null
                                      : _confirmAndDeleteAccount,
                                  icon: _deletingAccount
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.red,
                                          ),
                                        )
                                      : const Icon(Icons.delete_forever_outlined),
                                  label: Text(
                                    _deletingAccount
                                        ? 'Eliminando cuenta y archivos...'
                                        : 'Eliminar mi cuenta',
                                  ),
                                ),
                              ),
                            ],
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
