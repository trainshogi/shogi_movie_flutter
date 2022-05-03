import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as imglib;

typedef convert_func = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32, Int32, Int32, Int32);
typedef Convert = Pointer<Uint32> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, int, int, int, int);

class FileController {

  // Load the convertImage() function from the library
  // Convert conv = (Platform.isAndroid
  //     ? DynamicLibrary.open("libconvertImage.so")
  //     : DynamicLibrary.process())
  //     .lookup<NativeFunction<convert_func>>('convertImage').asFunction<Convert>();

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

  static Future<List<FileSystemEntity>> directoryFileList(String dirName) async {
    final path = await localPath;
    return Directory(path+"/"+dirName).list(recursive: false).toList();
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

  // 画像をドキュメントへ保存する。
  // 引数にはカメラ撮影時にreturnされるFileオブジェクトを持たせる。
  // 画像は必要十分なサイズに変更
  static Future<File> saveLocalImageWithResize(XFile xFile, String dirName, String filename, int minWidth) async {
    final path = await directoryPath(dirName);
    final imagePath = '$path/$filename';
    File imageFile = File(imagePath);

    //Read a jpeg image from file.
    Image image= decodeImage(await xFile.readAsBytes())!;
    //Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
    Image resizedImage = copyResize(image, width: minWidth);
    //Save the thumbnail as a PNG.
    var savedFile = await imageFile.writeAsBytes(encodeJpg(resizedImage));

    return savedFile;
  }

  // 画像をドキュメントへ保存する。
  // 引数にはカメラ撮影時にreturnされるFileオブジェクトを持たせる。
  static Future saveLocalImageBytes(List<int> bytes, String dirName, String filename) async {
    final path = await directoryPath(dirName);
    final imagePath = '$path/$filename';
    File imageFile = File(imagePath);
    // カメラで撮影した画像は撮影時用の一時的フォルダパスに保存されるため、
    // その画像をドキュメントへ保存し直す。
    var savedFile = await imageFile.writeAsBytes(bytes);
    // もしくは
    // var savedFile = await image.copy(imagePath);
    // でもOK

    return savedFile;
  }

  imglib.Image cameraImageYUV420toImage(CameraImage _savedImage) {
    // Load the convertImage() function from the library
    Convert conv = (Platform.isAndroid
        ? DynamicLibrary.open("libconvertImage.so")
        : DynamicLibrary.process())
        .lookup<NativeFunction<convert_func>>('convertImage').asFunction<Convert>();

    // Allocate memory for the 3 planes of the image
    Pointer<Uint8> p = calloc(_savedImage.planes[0].bytes.length);
    Pointer<Uint8> p1 = calloc(_savedImage.planes[1].bytes.length);
    Pointer<Uint8> p2 = calloc(_savedImage.planes[2].bytes.length);

    // Assign the planes data to the pointers of the image
    Uint8List pointerList = p.asTypedList(_savedImage.planes[0].bytes.length);
    Uint8List pointerList1 = p1.asTypedList(_savedImage.planes[1].bytes.length);
    Uint8List pointerList2 = p2.asTypedList(_savedImage.planes[2].bytes.length);
    pointerList.setRange(0, _savedImage.planes[0].bytes.length, _savedImage.planes[0].bytes);
    pointerList1.setRange(0, _savedImage.planes[1].bytes.length, _savedImage.planes[1].bytes);
    pointerList2.setRange(0, _savedImage.planes[2].bytes.length, _savedImage.planes[2].bytes);

    // Call the convertImage function and convert the YUV to RGB
    Pointer<Uint32> imgP = conv(p, p1, p2, _savedImage.planes[1].bytesPerRow,
        _savedImage.planes[1].bytesPerPixel!, _savedImage.width, _savedImage.height);
    // Get the pointer of the data returned from the function to a List
    List<int> imgData = imgP.asTypedList((_savedImage.width * _savedImage.height));

    // Generate image from the converted data
    imglib.Image img = imglib.Image.fromBytes(_savedImage.height, _savedImage.width, imgData);

    // Free the memory space allocated
    // from the planes and the converted data
    calloc.free(p);
    calloc.free(p1);
    calloc.free(p2);
    calloc.free(imgP);

    return img;
  }

  imglib.Image cameraImageBGRA8888toImage(CameraImage image) {
    return imglib.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: imglib.Format.bgra,
    );
  }

  Future<File> getImgFile(CameraImage _savedImage) async {
    imglib.Image img = (Platform.isAndroid ? cameraImageYUV420toImage(_savedImage) : cameraImageBGRA8888toImage(_savedImage));

    File file = await saveLocalImageBytes(imglib.encodeJpg(img), 'tmp', 'base.jpg');

    return file;
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

  static Future deleteFolder(String dirName) async {
    List<FileSystemEntity> folderList = await directoryFileList("");
    for (var folder in folderList) {
      if (folder is Directory && folder.path.split("/").removeLast() == dirName) {
        folder.deleteSync(recursive: true);
        break;
      }
    }
  }
}