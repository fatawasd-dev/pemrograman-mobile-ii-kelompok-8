import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_crud/models/todo_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> downloadTodosToExcel() async {
    try {
      QuerySnapshot querySnapshot = await todosCollection.get();
      List<QueryDocumentSnapshot> docs = querySnapshot.docs;

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      sheetObject.appendRow([
        TextCellValue('ID'),
        TextCellValue('Title'),
        TextCellValue('Description')
      ]);

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        sheetObject.appendRow([
          TextCellValue(doc.id),
          TextCellValue(data['title'] ?? ''),
          TextCellValue(data['description'] ?? ''),
        ]);
      }

      Uint8List? excelBytes =
          excel.encode() != null ? Uint8List.fromList(excel.encode()!) : null;

      if (excelBytes != null) {
        await saveFileToDownloads(
            excelBytes, 'todos_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      }
    } catch (e) {
      print('Gagal mengunduh data ke Excel: $e');
      rethrow;
    }
  }

  Future<void> saveFileToDownloads(Uint8List fileBytes, String fileName) async {
    try {
      if (await requestStoragePermission()) {
        final downloadDir = Directory('/storage/emulated/0/Download');

        if (!downloadDir.existsSync()) {
          throw Exception('Folder Download tidak ditemukan.');
        }

        final filePath = '${downloadDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        print('File berhasil disimpan di $filePath');
      } else {
        throw Exception('Izin akses penyimpanan ditolak.');
      }
    } catch (e) {
      print('Gagal menyimpan file ke folder Download: $e');
    }
  }

  Future<bool> requestStoragePermission() async {
    var status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> importExcelFile() async {
    await requestStoragePermission();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      String filePath = result.files.single.path!;

      var bytes = File(filePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      bool isFirstRow = true;

      var sheet = excel.tables.keys.first;
      for (var row in excel.tables[sheet]!.rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue;
        }
        String title = row[1]!.value.toString();
        String desc = row[2]!.value.toString();

        TodoModel todo = TodoModel(title: title, description: desc);
        await addTodo(todo);
      }
    } else {
      print('Tidak ada file yang dipilih');
    }
  }
}
