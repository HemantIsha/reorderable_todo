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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
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

  Future<void> _addButtonPressed(BuildContext context, WidgetRef ref) async {
    TextEditingController inputController = TextEditingController();

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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                ref.read(todoListProvider.notifier).add(inputController.text);
                inputController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _textItemPressed(
      BuildContext context, WidgetRef ref, TodoItem todo) async {
    TextEditingController inputController =
        TextEditingController(text: todo.text);

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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                ref
                    .read(todoListProvider.notifier)
                    .edit(description: inputController.text, id: todo.id);

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
          height: 500,
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
                                _textItemPressed(
                                    context, ref, todoList.value![index]);
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
          _addButtonPressed(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
