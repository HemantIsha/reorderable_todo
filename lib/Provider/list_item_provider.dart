import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reorderable_todo/Model/list_item.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final todoListProvider = AsyncNotifierProvider<TodoList, List<TodoItem>>(() {
  return TodoList();
});

class TodoList extends AsyncNotifier<List<TodoItem>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  FutureOr<List<TodoItem>> build() async {
    ref.listen(authStateChangesProvider, (_, __) {
      ref.invalidateSelf();
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return []; // Return an empty list if there's no user
    }
    return _loadTodos();
  }

  Future<List<TodoItem>> _loadTodos() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _db
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('todos')
          .orderBy('position')
          .get();

      final todos = snapshot.docs
          .map((doc) => TodoItem.fromFirestore(doc.data()))
          .toList();

      return todos;
    } catch (e) {
      throw AsyncError('Error loading todos: $e', StackTrace.current);
    }
  }

  Future<void> add(String desc) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final id = UniqueKey().toString();
    state = AsyncValue.data([
      ...?state.value,
      TodoItem(
          id: id,
          text: desc,
          isChecked: false,
          isSelected: false,
          position: state.value?.length != null ? state.value!.length - 1 : 0),
    ]);

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(id)
          .set({
        'text': desc,
        'isChecked': false,
        'id': id,
        'isSelected': false,
        'position': state.value?.length ?? 0
      });
    } catch (e) {
      // Rollback on failure
      state =
          AsyncValue.data(state.value!.where((todo) => todo.id != id).toList());
      throw AsyncError('Failed to add todo', StackTrace.current);
    }
  }

  void reorder(int oldIndex, int newIndex) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    state.whenData((todos) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = todos.removeAt(oldIndex);
      todos.insert(newIndex, item);
      state = AsyncValue.data(todos);
    });

    try {
      var snapshot =
          await _db.collection("users").doc(userId).collection('todos').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      log("Error deleting document $e");
    }

    for (int i = 0; i < state.value!.length; i++) {
      await _db
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(state.value![i].id)
          .set({
        'text': state.value![i].text,
        'isChecked': state.value![i].isChecked,
        'id': state.value![i].id,
        'isSelected': state.value![i].isSelected,
        'position': i,
      });
    }
  }

  Future<void> toggle(String id, bool isChecked) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final updatedTodos = state.value ?? [];

    state = AsyncValue.data(updatedTodos.map((todo) {
      if (todo.id == id) {
        return TodoItem(
          id: todo.id,
          isChecked: !todo.isChecked,
          text: todo.text,
          isSelected: todo.isSelected,
        );
      }
      return todo;
    }).toList());

    try {
      await _db
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('todos')
          .doc(id)
          .update({'isChecked': isChecked});
    } catch (e) {
      throw AsyncError('Failed to update todo', StackTrace.current);
    }
  }

  Future<void> select(String id, bool isSelected) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final updatedTodos = state.value ?? [];

    state = AsyncValue.data(updatedTodos.map((todo) {
      if (todo.id == id) {
        return TodoItem(
          id: todo.id,
          isSelected: isSelected,
          text: todo.text,
          isChecked: todo.isChecked,
        );
      }
      return todo;
    }).toList());

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(id)
          .update({'isSelected': isSelected});
    } catch (e) {
      throw AsyncError('Failed to update todo', StackTrace.current);
    }
  }

  Future<void> edit({
    required String id,
    required String description,
  }) async {
    final updatedTodos = state.value ?? [];

    state = AsyncValue.data(updatedTodos.map((todo) {
      if (todo.id == id) {
        return TodoItem(
          id: todo.id,
          text: description,
          isChecked: todo.isChecked,
        );
      }
      return todo;
    }).toList());

    try {
      await _db
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('todos')
          .doc(id)
          .update({
        'text': description,
      });
    } catch (e) {
      throw AsyncError('Failed to update todo', StackTrace.current);
    }
  }

  Future<void> remove(TodoItem target) async {
    final updatedTodos = state.value ?? [];
    state = AsyncValue.data(
        updatedTodos.where((todo) => todo.id != target.id).toList());
    try {
      await _db
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('todos')
          .doc(target.id)
          .delete();
    } catch (e) {
      throw AsyncError('Failed to delete todo', StackTrace.current);
    }
  }
}
