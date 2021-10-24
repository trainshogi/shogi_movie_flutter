import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shogi_movie_flutter/image_and_painter.dart';
import 'package:shogi_movie_flutter/record.dart';
import 'package:wakelock/wakelock.dart';

import 'file_controller.dart';
import 'util.dart';
import 'util_sfen.dart';
import "overlay_loading_molecules.dart";

class BaseImgSetting extends StatefulWidget {
  final String dirName;
  const BaseImgSetting({Key? key, required this.dirName}) : super(key: key);

  @override
  _BaseImgSettingState createState() => _BaseImgSettingState();
}

class _BaseImgSettingState extends State<BaseImgSetting> {
  File? imageFile;
  GlobalKey globalKeyForPainter = GlobalKey();
  String currentSfen = "";
  bool onProgress = false;
  bool _cameraOn = true;

  // タッチした点を覚えておく
  final _points = <Offset>[];
  List<Offset>? relativePoints;

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
      this.imageFile = savedFile; //変更
    });
  }

  static const platformPieceDetect = MethodChannel('com.nkkuma.dev/piece_detect');

  Size getPainterSize() {
    return (globalKeyForPainter.currentContext?.findRenderObject() as RenderBox).size;
  }

  Future<void> _detectPiecePlace() async {
    // Get battery level.
    if (_points.length != 4) {
      alertDialog(context, "枠の角を4点設定してください");
    }
    else {
      relativePoints = absolutePoints2relativePoints(
          _points, getPainterSize());
      String directoryPath = await FileController.directoryPath(
          widget.dirName);
      var requestMap = {
        "platform": platformPieceDetect,
        "methodName": 'initial_piece_detect',
        "args": <String, String>{
          'srcPath': imageFile!.path,
          'points': relativePoints.toString(),
          'dirName': directoryPath
        }
      };
      return callInvokeMethod(requestMap).then((result) =>
          setState(() {
            // _pieceDetect = pieceDetect;
            String imgPath = jsonDecode(result)['imgPath'];
            currentSfen = jsonDecode(result)['sfen'];
            imageFile = File(imgPath);
            // if currentSfen is not correct, retake piece photo or give up
            if (!isInitialPosition(currentSfen)) {
              alertDialog(context, "初期盤面が正しく読み込まれませんでした。初期盤面を撮り直すか駒を撮り直してください。");
            }
            else {
              successDialog(context, "初期盤面が正しく読み込まれました");
            }
          })
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('初期盤面取得'),
        ),
        body: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.expand,
          children: <Widget>[
            Center(
                child: Container(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: ImageAndPainter(
                            maxPointLength: 4, points: _points,
                            imageBytes: imageFile?.readAsBytesSync(),
                            imageWidget: (imageFile == null) ? null : Image.memory(imageFile!.readAsBytesSync()),
                            key: globalKeyForPainter),
                      ),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(3.0),
                                child: ElevatedButton(
                                  child: const Text('カメラで撮影'),
                                  onPressed: () {
                                    // _getAndSaveImageFromDevice(ImageSource.camera);
                                    _getAndSaveImageFromDevice(ImageSource.gallery);
                                  },
                                )),
                            Container(
                                padding: const EdgeInsets.all(3.0),
                                child: ElevatedButton(
                                  child: const Text('初期駒チェック'),
                                  onPressed: () {
                                    // 全画面プログレスダイアログを表示
                                    Wakelock.enable();
                                    setState(() {
                                      onProgress = true;
                                    });
                                    _detectPiecePlace().then((value) =>
                                        setState(() {
                                          onProgress = false;
                                          Wakelock.disable();
                                        })
                                    );
                                  },
                                )),
                            Container(
                                padding: const EdgeInsets.all(3.0),
                                child: ElevatedButton(
                                  child: const Text('スタート'),
                                  onPressed: () {
                                    relativePoints ??= absolutePoints2relativePoints(
                                          _points, getPainterSize());
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => Record(dirName: widget.dirName, relativePoints: relativePoints!)),
                                    );
                                  },
                                )),
                          ]
                      ),
                    ],
                  ),
                )
            ),
            OverlayLoadingMolecules(visible: onProgress)
          ]
        )
    );
  }
}
