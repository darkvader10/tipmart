
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/login_pages/login_page.dart';
import 'package:login/pages/dashboard.dart';


class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user login
          if (snapshot.hasData) {
            return DashboardPage();
          } else {
            return LoginPage();
          }

          //user not logged
        },
      ),
    );
  }
}
