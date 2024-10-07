import 'dart:async';
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
      TodoItem(id: id, text: desc),
    ]);

    try {
      await _db.collection('users').doc(userId).collection('todos').doc(id).set(
          {'text': desc, 'isChecked': false, 'id': id, 'isSelected': false});
    } catch (e) {
      // Rollback on failure
      state =
          AsyncValue.data(state.value!.where((todo) => todo.id != id).toList());
      throw AsyncError('Failed to add todo', StackTrace.current);
    }
  }

  void reorder(int oldIndex, int newIndex) {
    state.whenData((todos) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = todos.removeAt(oldIndex);
      todos.insert(newIndex, item);
      state = AsyncValue.data(todos);
    });
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
