import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reorderable_todo/Auth/registartion_screen.dart';

class AuthScreen extends HookWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final warningText = useState('');

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Taskmaster'),
        ),
        body: Center(
            child: Column(
          children: [
            const SizedBox(height: 100),
            const Text('Login'),
            const SizedBox(height: 50),
            Container(
                constraints:
                    const BoxConstraints.expand(width: 300, height: 300),
                child: Column(children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                    ),
                  ),
                  const SizedBox(height: 50),
                  TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your password',
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(warningText.value),
                ])),
            TextButton(
                onPressed: () async {
                  String message = '';
                  warningText.value = '';
                  if (!emailRegex.hasMatch(emailController.text)) {
                    warningText.value = 'Invalid email';
                    return;
                  }
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );

                    Future.delayed(const Duration(seconds: 3), () {
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacementNamed("/home");
                    });
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
                      message = 'Invalid login credentials.';
                    } else {
                      message = e.code;
                    }
                    Fluttertoast.showToast(
                      msg: message,
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.SNACKBAR,
                      backgroundColor: Colors.black54,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    );
                  }
                },
                child: const Text('Continue ')),
            TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => RegistrationScreen(),
                    ),
                  );
                },
                child: const Text('Signup')),
            //   TextButton(onPressed: () {}, child: const Text('Forgot Password')),
          ],
        )));
  }
}
