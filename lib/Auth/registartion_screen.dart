import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reorderable_todo/Auth/auth_screen.dart';

class RegistrationScreen extends HookWidget {
  RegistrationScreen({super.key});
  final _firebaseAuth = FirebaseAuth.instance;
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final controller1 = useTextEditingController();
    final controller2 = useTextEditingController();
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
              const Text('Sign up'),
              const SizedBox(height: 50),
              Container(
                  constraints:
                      const BoxConstraints.expand(width: 300, height: 400),
                  child: Column(children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                      ),
                    ),
                    const SizedBox(height: 50),
                    TextField(
                      controller: controller1,
                      obscureText: true,
                      onChanged: (value) => warningText.value = '',
                      decoration: const InputDecoration(
                        hintText: 'Enter your password',
                      ),
                    ),
                    const SizedBox(height: 50),
                    TextField(
                      controller: controller2,
                      obscureText: true,
                      onChanged: (value) => warningText.value = '',
                      decoration: const InputDecoration(
                        hintText: 'Confirm your password',
                      ),
                    ),
                    const SizedBox(height: 50),
                    Text(warningText.value,
                        style: const TextStyle(color: Colors.red)),
                  ])),
              TextButton(
                  onPressed: () async {
                    if (controller1.value != controller2.value) {
                      warningText.value = 'Passwords do not match';
                      controller1.clear();
                      controller2.clear();
                      return;
                    } else if (!emailRegex.hasMatch(emailController.text)) {
                      warningText.value = 'Invalid email';
                      return;
                    } else {
                      try {
                        await _firebaseAuth.createUserWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: controller1.text.trim());
                        Future.delayed(const Duration(seconds: 3), () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                        });
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'weak-password') {
                          warningText.value =
                              'The password provided is too weak.';
                        } else if (e.code == 'email-already-in-use') {
                          warningText.value =
                              'An account already exists with that email.';
                        }
                      } catch (e) {
                        Fluttertoast.showToast(
                          msg: "Failed: $e",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.SNACKBAR,
                          backgroundColor: Colors.black54,
                          textColor: Colors.white,
                          fontSize: 14.0,
                        );
                      }
                    }
                  },
                  child: const Text('Register')),
            ],
          ),
        ));
  }
}
