import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../models/kanban.dart';

class StorageService {
  Future<File> _getSaveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = Directory('${directory.path}\\SebanBoard');
    if (!await path.exists()) {
      await path.create();
    }
    return File('${path.path}\\kanban_data.json');
  }

  Future<List<KanbanCategory>?> loadData() async {
    try {
      final file = await _getSaveFile();
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        return jsonList.map((c) => KanbanCategory.fromJson(c)).toList();
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
    return null; // Returns null if no file exists (so UI can load the tutorial)
  }

  Future<void> saveData(List<KanbanCategory> categories) async {
    try {
      final file = await _getSaveFile();
      final String jsonString = jsonEncode(
        categories.map((c) => c.toJson()).toList(),
      );
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint("Error saving data: $e");
    }
  }

  Future<bool> exportBackup(List<KanbanCategory> categories) async {
    final String jsonString = jsonEncode(
      categories.map((c) => c.toJson()).toList(),
    );
    final List<int> byteList = utf8.encode(jsonString);

    final Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Export Board Backup',
      fileName: 'seban_board_backup.json',
      bytes: Uint8List.fromList(byteList),
    );

    return outputFile != null;
  }

  Future<List<KanbanCategory>?> importBackup() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      dialogTitle: 'Import Board Backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final file = File(files.first.path!);
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((c) => KanbanCategory.fromJson(c)).toList();
    }
    return null;
  }
}
