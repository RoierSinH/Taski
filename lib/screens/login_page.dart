import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_isSignUp) {
      success = await authController.signUp(email, password);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cuenta creada exitosamente. Si tu proyecto requiere confirmación, revisa tu correo.',
            ),
          ),
        );
      }
    } else {
      success = await authController.signIn(email, password);
    }

    if (!success && mounted && authController.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_done_outlined,
                        size: 64,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isSignUp ? 'Crear cuenta en Taski' : 'Bienvenido a Taski',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp
                            ? 'Sincroniza tus tareas en la nube con Supabase'
                            : 'Inicia sesión para sincronizar tus tareas',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('login_email'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('login_password'),
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (authController.loading)
                        const CircularProgressIndicator()
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            key: const Key('login_submit'),
                            onPressed: _submit,
                            child: Text(
                              _isSignUp ? 'Registrarse' : 'Iniciar sesión',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                        child: Text(
                          _isSignUp
                              ? '¿Ya tienes cuenta? Inicia sesión aquí'
                              : '¿No tienes cuenta? Regístrate aquí',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
