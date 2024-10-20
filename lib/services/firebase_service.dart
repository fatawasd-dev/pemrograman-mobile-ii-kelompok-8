import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_crud/models/todo_model.dart';

class FirebaseService {
  final CollectionReference todosCollection =
      FirebaseFirestore.instance.collection('todos');

  Future<void> addTodo(TodoModel todo) async {
    try {
      await todosCollection.add(todo.toMap());
    } catch (e) {
      print('Gagal menambah todo: $e');
      rethrow;
    }
  }

  // Gunakan satu metode untuk mendapatkan stream
  Stream<List<TodoModel>> getTodosStream() {
    return todosCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TodoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateTodo(TodoModel todo) async {
    try {
      await todosCollection.doc(todo.id).update(todo.toMap());
    } catch (e) {
      print('Gagal update todo: $e');
      rethrow;
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await todosCollection.doc(id).delete();
    } catch (e) {
      print('Gagal menghapus todo: $e');
      rethrow;
    }
  }
}
