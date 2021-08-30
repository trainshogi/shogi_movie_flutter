import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileController {
  // ドキュメントのパスを取得
  static Future get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    print(directory.path);
    return directory.path;
  }

  static Future directoryPath(String dirName) async {
    final path = await localPath;
    var directory = await Directory(path+"/"+dirName).create(recursive: true);
    print(directory.path);
    return directory.path;
  }

  // ドキュメントの画像を取得する。
  static Future loadLocalImage(String dirName, String filename) async {
    final path = await directoryPath(dirName);
    final imagePath = '$path/$filename';
    return File(imagePath);
  }

  // 画像をドキュメントへ保存する。
  // 引数にはカメラ撮影時にreturnされるFileオブジェクトを持たせる。
  static Future saveLocalImage(XFile image, String dirName, String filename) async {
    final path = await directoryPath(dirName);
    final imagePath = '$path/$filename';
    File imageFile = File(imagePath);
    // カメラで撮影した画像は撮影時用の一時的フォルダパスに保存されるため、
    // その画像をドキュメントへ保存し直す。
    var savedFile = await imageFile.writeAsBytes(await image.readAsBytes());
    // もしくは
    // var savedFile = await image.copy(imagePath);
    // でもOK

    return savedFile;
  }

  // ドキュメントのファイルを取得する。
  static Future loadLocalFile(String dirName, String filename) async {
    final path = await directoryPath(dirName);
    final filePath = '$path/$filename';
    return File(filePath);
  }

  // テキストをドキュメントへ保存する。
  static Future saveLocalFile(String text, String dirName, String filename) async {
    final path = await directoryPath(dirName);
    final filePath = '$path/$filename';
    File file = File(filePath);
    var savedFile = await file.writeAsString(text);
    return savedFile;
  }
}