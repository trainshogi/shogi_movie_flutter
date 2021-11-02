import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shogi_movie_flutter/image_and_painter.dart';
import 'package:shogi_movie_flutter/record.dart';
import 'package:wakelock/wakelock.dart';

import 'camera.dart';
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
  FileController fileController = FileController();
  File? imageFile;
  GlobalKey globalKeyForPainter = GlobalKey();
  String currentSfen = "";
  bool onProgress = false;
  bool _cameraStreamOn = false;

  //カメラリスト
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  late CameraImage _savedImage;

  // タッチした点を覚えておく
  final _points = <Offset>[];
  List<Offset>? relativePoints;

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
      // final imageXFile = await _controller!.takePicture();
      var savedFile = await fileController.getImgFile(_savedImage);
      relativePoints = sortPoints(absolutePoints2relativePoints(_points, getPainterSize()));
      String directoryPath = await FileController.directoryPath(widget.dirName);
      var requestMap = {
        "platform": platformPieceDetect,
        "methodName": 'initial_piece_detect',
        "args": <String, String>{
          'srcPath': savedFile.path, //imageXFile.path,
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

  // prepare camera
  void initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.yuv420
      );
      _controller!.setFlashMode(FlashMode.always);
      _controller!.initialize().then((_) async {
        if (!mounted) {
          return;
        }

        _controller!.startImageStream((CameraImage image) => _processCameraImage(image));

        //カメラ接続時にbuildするようsetStateを呼び出し
        setState(() {});
      });
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_cameraStreamOn == false) {
      fileController.getImgFile(image)
          .then((value) => setState(() {imageFile = value;}));
    }
    setState(() {
      _savedImage = image;
      _cameraStreamOn = true;
    });
  }

  Widget cameraImageOrIcon() {
    return
      (imageFile != null && _controller != null) ?
        ImageAndPainter(maxPointLength: 4, points: _points, imageBytes: imageFile?.readAsBytesSync(),
        imageWidget: Camera(controller:_controller!), key: globalKeyForPainter)
        : const Icon(Icons.no_sim);
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose(){
    _controller?.dispose();
    super.dispose();
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
                        padding: const EdgeInsets.all(20),
                        child: cameraImageOrIcon()
                      ),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
