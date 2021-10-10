
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'file_controller.dart';

List<Offset> absolutePoints2relativePoints(List<Offset> points, Size size) {
  // get PainterSize
  print("ウィジェットのサイズ: $size");
  // convert to relative
  var relativePoints = <Offset>[];
  points.forEach((Offset point) {
    relativePoints.add(Offset(100 * point.dx / size.width, 100 * point.dy / size.height));
  });
  return relativePoints;
}

List<Offset> relativePoints2absolutePoints(List<Offset> points, Size size) {
  // get PainterSize
  print("ウィジェットのサイズ: $size");
  // convert to relative
  var absolutePoints = <Offset>[];
  points.forEach((Offset point) {
    absolutePoints.add(Offset(size.width * (point.dx / 100), size.height * (point.dy / 100)));
  });
  return absolutePoints;
}

List<Offset> string2Offsets(String row) {
  var offsets = <Offset>[];
  List<String> rowOffsets = row.split(':');
  for (var rowOffset in rowOffsets) {
    var formatted = rowOffset
        .replaceAll(" ", "")
        .replaceFirst("Offset(", "")
        .replaceFirst(")", "")
        .split(",");
    offsets.add(Offset(double.parse(formatted[0]), double.parse(formatted[1])));
  }
  return offsets;
}

void alertDialog(BuildContext context, String alert_sentence) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("エラー"),
        content: Text(alert_sentence),
        actions: <Widget>[
          // ボタン領域
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

void successDialog(BuildContext context, String alert_sentence) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("成功"),
        content: Text(alert_sentence),
        actions: <Widget>[
          // ボタン領域
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

void textDialog(BuildContext context, String alert_sentence) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("成功"),
        content: Text(alert_sentence),
        actions: <Widget>[
          // ボタン領域
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

// call invokeMethod
Future<dynamic> callInvokeMethod(Map<String, dynamic> map) {
  var platform = map['platform'] as MethodChannel;
  var methodName = map['methodName'];
  var args = map['args'];
  return platform.invokeMethod(methodName, args);
}


// 全画面プログレスダイアログを表示する関数
void showProgressDialog(BuildContext context) {
  showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
  );
}

Widget progressIndicatorOrEmpty(bool onProgress) {
  if (onProgress) {
    return const CircularProgressIndicator();
  }
  else {
    return Container();
  }
}

Future<Map<String, bool>> getSavedPieceNameMap() async {
  int pieceFileNum = 30;
  List<String> exceptFolder = ["flutter_assets", "tmp"];
  Map<String, bool> pieceNameMap = {};
  List<FileSystemEntity> folderList = await FileController.directoryFileList("");
  for (var folder in folderList) {
    if (folder is Directory) {
      String folderName = folder.path.split("/").removeLast();
      if (!exceptFolder.contains(folderName)) {
        List fileList = await FileController.directoryFileList(folderName);
        pieceNameMap[folderName] = (fileList.length == pieceFileNum);
      }
    }
  }
  return pieceNameMap;
}