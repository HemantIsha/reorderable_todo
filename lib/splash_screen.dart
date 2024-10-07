import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeUser();
    navigateUser();
  }

  Future initializeUser() async {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    await firebaseUser?.reload();
    // get User authentication status here
  }

  navigateUser() async {
    // checking whether user already loggedIn or not
    if (_auth.currentUser != null) {
      // &&  FirebaseAuth.instance.currentUser.reload() != null
      Timer(
        const Duration(seconds: 3),
        () => Navigator.of(context).pushReplacementNamed("/home"),
      );
    } else {
      Timer(const Duration(seconds: 4),
          () => Navigator.pushReplacementNamed(context, "/auth"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: const Center(
          child: SizedBox(
              height: 100, width: 100, child: CircularProgressIndicator()),
        ));
  }
}
