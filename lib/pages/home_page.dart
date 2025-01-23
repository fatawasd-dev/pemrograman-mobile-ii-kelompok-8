import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/todo_model.dart';
import '../services/firebase_service.dart';
import 'add_page.dart';
import 'edit_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.upload,
              color: Colors.white,
            ),
            onPressed: () async {
              await _firebaseService.importExcelFile();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File Excel berhasil diimport!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.download,
              color: Colors.white,
            ),
            onPressed: () async {
              await _firebaseService.downloadTodosToExcel();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'File Excel berhasil diunduh ke folder download!')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TodoModel>>(
        stream: _firebaseService.todosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final todos = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshTodos,
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(todo.title),
                    subtitle: Text(todo.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () => _editTodo(todo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool? confirm = await _confirmDelete(context);
                            if (confirm == true) {
                              await _firebaseService.deleteTodo(todo.id!);
                            }
                          },
                        ),
                        IconButton(
                            onPressed: () {
                              final shareText =
                                  'Todo: ${todo.title}\nDescription: ${todo.description}';
                              Share.share(shareText);
                            },
                            icon: const Icon(Icons.share, color: Colors.blue))
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshTodos() async {
    // Di sini Anda bisa menambahkan logika untuk memperbarui data, misalnya memanggil ulang stream.
    setState(() {});
  }

  void _editTodo(TodoModel todo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(todo: todo),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus todo ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
