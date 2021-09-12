import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shogi_movie_flutter/record.dart';

import 'file_controller.dart';
import 'frame_painter.dart';

class BaseImgSetting extends StatefulWidget {
  final String dirName;
  const BaseImgSetting({Key? key, required this.dirName}) : super(key: key);

  @override
  _BaseImgSettingState createState() => _BaseImgSettingState();
}

class _BaseImgSettingState extends State<BaseImgSetting> {
  File? imageFile;
  Image? image;
  Image? transImage;
  int movePointIndex = 0;

  // タッチした点を覚えておく
  final _points = <Offset>[];

  void _getAndSaveImageFromDevice(ImageSource source) async {
    // 撮影/選択したFileが返ってくる
    final ImagePicker _picker = ImagePicker();
    var imageFile = await _picker.pickImage(source: source);
    // 撮影せずに閉じた場合はnullになる
    if (imageFile == null) {
      return;
    }

    var savedFile = await FileController.saveLocalImage(imageFile, 'tmp', 'base.jpg'); //追加

    setState(() {
      // this.imageFile = imageFile;
      this.imageFile = savedFile; //変更
      image = Image.memory(savedFile!.readAsBytesSync());
      transImage = Image.memory(
          savedFile.readAsBytesSync(),
          color: const Color.fromRGBO(255, 255, 255, 0)
      );
    });
  }

  // 点を追加
  void _addPoint(TapUpDetails details) {
    // setState()にリストを更新する関数を渡して状態を更新
    if (_points.length < 4) {
      setState(() {
        _points.add(details.localPosition);
      });
    }
    else {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("エラー"),
            content: const Text("枠の角は4点より多く設定できません"),
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
  }

  // singleTapに制御がいかないようにここは必要。
  void _catchDoubleTap() {
  }

  void _deletePoint(TapDownDetails details) {
    if (_points.isNotEmpty) {
      int removePointIndex = getNearestPointIndex(_points, details.localPosition);
      setState(() {
        _points.removeAt(removePointIndex);
      });
    }
  }

  void _setMovePointIndex(DragStartDetails details) {
    if (_points.isNotEmpty) {
      movePointIndex = getNearestPointIndex(_points, details.localPosition);
      setState(() {
        _points[movePointIndex] = details.localPosition;
      });
    }
  }

  void _movePoint(DragUpdateDetails details) {
    if (_points.isNotEmpty) {
      setState(() {
        _points[movePointIndex] = details.localPosition;
      });
    }
  }

  Widget imageAndPainter() {
    if (imageFile == null) {
      return const Icon(Icons.no_sim);
    }
    else {
      return Stack(
        children: [
          image!,
          GestureDetector(
            // 追加イベント
            onTapUp: _addPoint,
            // 削除イベント
            onDoubleTap: _catchDoubleTap,
            onDoubleTapDown: _deletePoint,
            // 移動イベント
            onPanStart: _setMovePointIndex,
            onPanUpdate: _movePoint,
            // カスタムペイント
            child: CustomPaint(
              painter: FramePainter(_points),
              // タッチを有効にするため、childが必要
              child: transImage,
            ),
          ),
        ],
      );
    }
  }


  static const platform = MethodChannel('samples.flutter.dev/battery');

  String _batteryLevel = 'Unknown battery level.';

  Future<void> _getBatteryLevel() async {
    // Get battery level.
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  static const platformPieceDetect = MethodChannel('com.nkkuma.dev/piece_detect');

  String _pieceDetect = 'Unknown battery level.';

  Future<void> _detectPiecePlace() async {
    // Get battery level.
    String pieceDetect;
    try {
      final int result = await platformPieceDetect.invokeMethod(
          'piece_detect',
          <String, String>{'srcPath': imageFile!.path, 'points': _points.toString(), 'dirName': widget.dirName}
      );
      pieceDetect = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      pieceDetect = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _pieceDetect = pieceDetect;
    });
  }

  @override
  void initState() {
    _getBatteryLevel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('初期盤面取得'),
        ),
        body: Center(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: imageAndPainter(),
                  ),
                  Text(_batteryLevel),
                  Container(
                      padding: const EdgeInsets.all(3.0),
                      child: ElevatedButton(
                        child: const Text('カメラで撮影'),
                        onPressed: () {
                          _getAndSaveImageFromDevice(ImageSource.camera); // New Line
                        },
                      )),
                  Container(
                      padding: const EdgeInsets.all(3.0),
                      child: ElevatedButton(
                        child: const Text('初期駒チェック'),
                        onPressed: () {
                          _detectPiecePlace();
                        },
                      )),
                  Container(
                      padding: const EdgeInsets.all(3.0),
                      child: ElevatedButton(
                        child: const Text('スタート'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Record()),
                          );
                        },
                      )),
                ],
              ),
            )
        )
    );
  }
}
