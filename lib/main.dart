import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:second_mart/features/auth/login_view.dart';
import 'package:second_mart/features/primary/primary_view.dart';
import 'package:second_mart/features/splash/splash_view.dart';
import 'package:second_mart/firebase_options.dart';
import 'package:second_mart/utils/theme/custom_theme/app_bar_theme.dart';
import 'package:second_mart/utils/theme/custom_theme/elevated_button_theme.dart';
import 'package:second_mart/utils/theme/custom_theme/input_decoration_theme.dart'
    show appInputDecorationTheme;
import 'package:second_mart/utils/theme/custom_theme/text_theme.dart';
import 'package:second_mart/utils/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load saved theme preference before running the app
  await ThemeProvider().load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider(),
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Second Mart',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,

          // ── Light Theme ──────────────────────────────────────────
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF3498DB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3498DB),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F6FA),
            textTheme: appTextTheme,
            appBarTheme: appBarTheme,
            elevatedButtonTheme: appElevatedButtonTheme,
            inputDecorationTheme: appInputDecorationTheme,
            cardColor: Colors.white,
          ),

          // ── Dark Theme ───────────────────────────────────────────
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF3498DB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3498DB),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            elevatedButtonTheme: appElevatedButtonTheme,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF3498DB), width: 2),
              ),
            ),
          ),

          home: const SplashView(),
        );
      },
    );
  }
}

/// Listens to Firebase auth state and routes to the correct screen:
/// - Loading  → SplashView (while Firebase resolves the persisted session)
/// - Logged in → PrimaryView (skip login entirely)
/// - Logged out → LoginView
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashView();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const PrimaryView();
        }
        return const LoginView();
      },
    );
  }
}
