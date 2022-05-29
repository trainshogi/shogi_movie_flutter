import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/file_controller.dart';

List<Offset> absolutePoints2relativePoints(List<Offset> points, Size size) {
  // get PainterSize
  print("ウィジェットのサイズ: $size");
  // convert to relative
  var relativePoints = <Offset>[];
  for (var point in points) {
    relativePoints.add(Offset(100 * point.dx / size.width, 100 * point.dy / size.height));
  }
  return relativePoints;
}

List<Offset> relativePoints2absolutePoints(List<Offset> points, Size size) {
  // get PainterSize
  print("ウィジェットのサイズ: $size");
  // convert to relative
  var absolutePoints = <Offset>[];
  for (var point in points) {
    absolutePoints.add(Offset(size.width * (point.dx / 100), size.height * (point.dy / 100)));
  }
  return absolutePoints;
}

List<Offset> sortPoints(List<Offset> points) {
  var sortedPoints = <Offset>[Offset.zero, Offset.zero, Offset.zero, Offset.zero];
  Offset midPoint = Offset(
      points.map((e) => e.dx).reduce((value, element) => value + element) / points.length,
      points.map((e) => e.dy).reduce((value, element) => value + element) / points.length);
  for (var element in points) {
    if (element.dx < midPoint.dx) {
      if (element.dy < midPoint.dy) {
        sortedPoints[0] = element;
      } else {
        sortedPoints[1] = element;
      }
    } else {
      if (element.dy < midPoint.dy) {
        sortedPoints[3] = element;
      } else {
        sortedPoints[2] = element;
      }
    }
  }
  return sortedPoints;
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

// call invokeMethod
Future<dynamic> callInvokeMethod(Map<String, dynamic> map) {
  var platform = map['platform'] as MethodChannel;
  var methodName = map['methodName'];
  var args = map['args'];
  return platform.invokeMethod(methodName, args);
}
