import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:second_mart/features/auth/login_view.dart';
import 'package:second_mart/firebase_options.dart';
import 'package:second_mart/utils/theme/custom_theme/app_bar_theme.dart';
import 'package:second_mart/utils/theme/custom_theme/elevated_button_theme.dart';
import 'package:second_mart/utils/theme/custom_theme/input_decoration_theme.dart'
    show appInputDecorationTheme;
import 'package:second_mart/utils/theme/custom_theme/text_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF3498DB),
        textTheme: appTextTheme,
        appBarTheme: appBarTheme,
        elevatedButtonTheme: appElevatedButtonTheme,
        inputDecorationTheme: appInputDecorationTheme,
      ),
      home: LoginView(),
    );
  }
}
