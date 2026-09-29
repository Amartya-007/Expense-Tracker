import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

enum LlmStatus { notInstalled, loading, ready }

class LlmService {
  static const _modelPathKey = 'local_gguf_model_path';
  
  LlmStatus status = LlmStatus.notInstalled;
  String? modelFilePath;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_modelPathKey);
    if (path != null && File(path).existsSync()) {
      modelFilePath = path;
      status = LlmStatus.ready;
    } else {
      status = LlmStatus.notInstalled;
    }
  }

  Future<void> setModelFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPathKey, path);
    modelFilePath = path;
    status = LlmStatus.ready;
  }

  Future<void> removeModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modelPathKey);
    modelFilePath = null;
    status = LlmStatus.notInstalled;
  }

  Future<String> copyToAppStorage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sourcePath);
    final targetPath = p.join(appDir.path, fileName);
    await File(sourcePath).copy(targetPath);
    await setModelFile(targetPath);
    return targetPath;
  }
}
