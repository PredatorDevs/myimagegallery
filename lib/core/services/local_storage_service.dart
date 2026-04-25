import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _imagesKey = 'saved_images';
  static const String _pdfsKey = 'saved_pdfs';

  Future<List<File>> loadImages() => _loadFiles(_imagesKey);

  Future<void> saveImages(List<File> files) => _saveFiles(_imagesKey, files);

  Future<List<File>> loadPdfs() => _loadFiles(_pdfsKey);

  Future<void> savePdfs(List<File> files) => _saveFiles(_pdfsKey, files);

  Future<List<File>> _loadFiles(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> savedPaths = prefs.getStringList(key) ?? <String>[];

    final List<String> existingPaths = savedPaths
        .where((String path) => File(path).existsSync())
        .toList();

    if (existingPaths.length != savedPaths.length) {
      await prefs.setStringList(key, existingPaths);
    }

    return existingPaths.map((String path) => File(path)).toList();
  }

  Future<void> _saveFiles(String key, List<File> files) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> validPaths = files
        .map((File file) => file.path)
        .where((String path) => File(path).existsSync())
        .toList();

    await prefs.setStringList(key, validPaths);
  }
}
