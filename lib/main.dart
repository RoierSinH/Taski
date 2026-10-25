import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'controllers/auth_controller.dart';
import 'services/supabase_task_service.dart';
import 'controllers/task_controller.dart';
import 'services/profile_service.dart';
import 'controllers/profile_controller.dart';
import 'controllers/theme_controller.dart';
import 'services/notification_service.dart';
import 'screens/auth_gate.dart';
import 'screens/reset_password_page.dart';
import 'theme/taski_colors.dart';

final themeController = ThemeController();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await themeController.load();

  SupabaseConfig.validate();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(Supabase.instance.client),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<AuthService>()),
        ),
        Provider<ProfileService>(
          create: (_) => ProfileService(Supabase.instance.client),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (context) => ProfileController(context.read<ProfileService>()),
        ),
        ChangeNotifierProxyProvider<AuthController, TaskController>(
          create: (context) => TaskController(
            SupabaseTaskService(Supabase.instance.client),
          ),
          update: (_, auth, controller) {
            final result = controller ??
                TaskController(
                  SupabaseTaskService(Supabase.instance.client),
                );
            if (auth.user != null) {
              result.init();
            }
            return result;
          },
        ),
      ],
      child: const TaskiApp(),
    ),
  );
}

class TaskiApp extends StatefulWidget {
  const TaskiApp({super.key});

  @override
  State<TaskiApp> createState() => _TaskiAppState();
}

class _TaskiAppState extends State<TaskiApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _openedInitialRecovery = false;

  void _openResetPasswordPage({String? notice}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(noticeMessage: notice),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    try {
      final fullUrl = Uri.base.toString();
      final fragment = Uri.base.fragment;
      if (!_openedInitialRecovery &&
          (fullUrl.contains('type=recovery') || fragment.contains('type=recovery'))) {
        _openedInitialRecovery = true;
        _openResetPasswordPage();
      } else if (!_openedInitialRecovery &&
          (fullUrl.contains('otp_expired') || fragment.contains('otp_expired'))) {
        _openedInitialRecovery = true;
        _openResetPasswordPage(
          notice:
              'Nota: El enlace del correo es de un solo uso y ya había abierto tu sesión. Puedes actualizar tu contraseña aquí.',
        );
      }

      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          if (data.event == AuthChangeEvent.passwordRecovery && !_openedInitialRecovery) {
            _openedInitialRecovery = true;
            _openResetPasswordPage();
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Taski',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: TaskiColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: TaskiColors.background,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            cardTheme: CardThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: TaskiColors.primary,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: TaskiColors.darkBackground,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            cardTheme: CardThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
            ),
          ),
          themeMode: themeController.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}
