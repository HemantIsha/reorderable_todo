import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reorderable_todo/Auth/auth_screen.dart';
import 'package:reorderable_todo/Auth/registartion_screen.dart';
import 'package:reorderable_todo/Model/list_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reorderable_todo/Provider/list_item_provider.dart';
import 'package:reorderable_todo/splash_screen.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';
import 'package:talker/talker.dart';

final talker = Talker();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(observers: [
    TalkerRiverpodObserver(
      talker: talker,
      settings: const TalkerRiverpodLoggerSettings(
        enabled: true,
        printStateFullData: false,
        printProviderAdded: true,
        printProviderUpdated: true,
        printProviderDisposed: true,
        printProviderFailed: true,
        // If you want log only AuthProvider events
        // eventFilter: (provider) => provider.runtimeType == 'AuthProvider<User>',
      ),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Master',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/register': (context) => RegistrationScreen(),
        '/home': (context) => const MyHomePage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

final todoListProvider =
    AsyncNotifierProvider<TodoList, List<TodoItem>>(() => TodoList());

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  Future<void> _addButtonPressed(BuildContext context, WidgetRef ref,
      TextEditingController inputController) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: TextField(
            controller: inputController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '+'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                inputController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                inputController.clear();
                ref.read(todoListProvider.notifier).add(inputController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _textItemPressed(BuildContext context, WidgetRef ref,
      TodoItem todo, TextEditingController inputController) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: TextField(
            controller: inputController,
            autofocus: true,
            decoration: InputDecoration(hintText: todo.text),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                inputController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                ref
                    .read(todoListProvider.notifier)
                    .edit(description: inputController.text, id: todo.id);
                inputController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoList = ref.watch(todoListProvider);
    var showCheckbox = useState<bool>(false);
    final inputController = useTextEditingController();

    Widget proxyDecorator(
        Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(0, 6, animValue)!;
          return Material(
            elevation: elevation,
            color: Colors.blueAccent,
            shadowColor: Colors.blueGrey,
            child: child,
          );
        },
        child: child,
      );
    }

    final user = ref.watch(authStateChangesProvider);
    RegExp regex = RegExp(r'^[^@]+');
    String? userName = regex.stringMatch(user.value?.email ?? '');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Taskmaster'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Future.delayed(const Duration(seconds: 3), () {
                  Navigator.of(context, rootNavigator: true).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(),
                    ),
                  );
                });
              } on Exception catch (e) {
                Fluttertoast.showToast(
                  msg: e.toString(),
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.SNACKBAR,
                  backgroundColor: Colors.black54,
                  textColor: Colors.white,
                  fontSize: 14.0,
                );
              }
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Column(children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              userName != null ? 'Hello $userName' : '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        Center(
          child: showCheckbox.value
              ? ElevatedButton(
                  onPressed: () {
                    for (TodoItem item in todoList.value ?? []) {
                      if (item.isSelected == true) {
                        ref.read(todoListProvider.notifier).remove(item);
                      }
                    }
                    showCheckbox.value = false;
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.delete),
                      Text('delete selected items')
                    ],
                  ),
                )
              : const SizedBox(height: 20),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ReorderableListView(
              proxyDecorator: proxyDecorator,
              onReorder: (int oldIndex, int newIndex) {
                ref.read(todoListProvider.notifier).reorder(oldIndex, newIndex);
              },
              children: [
                for (int index = 0;
                    index < (todoList.value?.length ?? 0);
                    index++)
                  Container(
                    key: ValueKey(todoList.value![index].id),
                    child: GestureDetector(
                        onDoubleTap: () {
                          showCheckbox.value = !showCheckbox.value;
                        },
                        child: ListTile(
                            leading: showCheckbox.value
                                ? Checkbox(
                                    value: todoList.value?[index].isSelected,
                                    onChanged: (updatedValue) {
                                      ref
                                          .read(todoListProvider.notifier)
                                          .select(todoList.value![index].id,
                                              updatedValue!);
                                    })
                                : null,
                            title: TextButton(
                              onPressed: () {
                                inputController.text =
                                    todoList.value![index].text;
                                _textItemPressed(context, ref,
                                    todoList.value![index], inputController);
                              },
                              child: Text(todoList.value![index].text,
                                  style: TextStyle(
                                      fontSize: 18,
                                      decoration:
                                          todoList.value![index].isChecked
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none)),
                            ),
                            trailing: Checkbox(
                                value: todoList.value?[index].isChecked,
                                onChanged: (updatedValue) {
                                  ref.read(todoListProvider.notifier).toggle(
                                      todoList.value![index].id, updatedValue!);
                                }))),
                  )
              ]),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addButtonPressed(context, ref, inputController);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
