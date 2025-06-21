import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:bredproject/login_screen.dart';
import 'package:bredproject/register_user.dart';
import 'package:bredproject/chatbit.dart';
import 'package:bredproject/loginpro.dart';
import 'package:bredproject/registerpro.dart';
import 'package:bredproject/acceuilpro.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login':
            (context) =>
                LoginScreen(), // À remplacer avec ton vrai écran de connexion
        '/register': (context) => RegisterScreen(),
        '/chatbot': (context) => WebViewScreen(),
        '/loginPro': (context) => LoginproScreen(),
        '/registerPro': (context) => SignupPage(),
        '/acceuilPro': (context) => HomeProScreen(),
      },
    );
  }
}

// Écran de login temporaire pour tester la redirection
