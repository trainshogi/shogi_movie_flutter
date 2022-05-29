import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/controller/audio_controller.dart';
import 'package:shogi_movie_flutter/controller/camera.dart';
import 'package:shogi_movie_flutter/result.dart';
import 'package:shogi_movie_flutter/service/record_service.dart';
import 'package:shogi_movie_flutter/util/util.dart';
import 'package:shogi_movie_flutter/util/util_sfen.dart';
import 'package:wakelock/wakelock.dart';

import 'controller/image_and_painter.dart';
import 'domain/board_state.dart';
import 'controller/file_controller.dart';
import 'controller/overlay_loading_molecules.dart';

class Record extends StatefulWidget {
  final String dirName;
  const Record({Key? key, required this.dirName}) : super(key: key);

  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<Record> {
  FileController fileController = FileController();
  AudioController audioController = AudioController();
  late RecordService recordService;
  BoardState boardState = BoardState();

  GlobalKey globalKeyForPainter = GlobalKey();
  final _points = <Offset>[];
  double aspectRatio = 0.01;

  CameraController? _controller;
  bool onProgress = false;
  Completer<String> cameraInitCompleter = Completer<String>();

  // prepare camera
  void initCamera() async {
    List<CameraDescription> _cameras = await availableCameras();

    if (_cameras.isNotEmpty) {
      //カメラ接続時にbuildするようsetStateを呼び出し
      setState(() {
        _controller = CameraController(_cameras.first,
            ResolutionPreset.high,
            imageFormatGroup: ImageFormatGroup.yuv420);
      });
    }
    cameraInitCompleter.future.then((value) {
      setState(() {
        aspectRatio = _controller!.value.aspectRatio;
      });
    });
  }


  Widget cameraImageOrIcon() {
    if (_controller == null) {
      return const Icon(Icons.no_sim);
    }
    return
      ImageAndPainter(
          maxPointLength: 4,
          points: _points,
          imageBytes: null,
          imageWidget: Camera(controller: _controller!, initializeCompleter: cameraInitCompleter,),
          aspectRatio: aspectRatio,
          key: globalKeyForPainter);
  }

  Size _getPainterSize() {
    return (globalKeyForPainter.currentContext?.findRenderObject() as RenderBox).size;
  }

  Future<void> _detectPiecePlace() async {
    // File savedFile = await fileController.getImgFile(_savedImage!);
    setState(() {
      onProgress = true;
    });
    File savedFile = File((await _controller!.takePicture()).path);
    boardState.relativePoints = sortPoints(absolutePoints2relativePoints(_points, _getPainterSize()));
    recordService.detectPiecePlace(context, savedFile, boardState.relativePoints).then((value) {
      if (value.isNotEmpty) {
        audioController.play(["initial"]);
      }
      setState(() {
        onProgress = false;
      });
    });
  }

  void _recognize() {
    setState(() {
      onProgress = true;
      boardState.relativePoints = sortPoints(absolutePoints2relativePoints(_points, _getPainterSize()));
    });
    recordService.recognize(context, _controller!, boardState).then((value) =>
        setState(() {
          onProgress = false;
        })
    );
  }

  @override
  void initState() {
    recordService = RecordService(widget.dirName);
    initCamera();
    Wakelock.enable();
    super.initState();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    Wakelock.disable();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('棋譜記録'),
        ),
        body: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.expand,
          children: <Widget>[
            Center(child: Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(boardState.currentMoveNumber.toString() + '手目：' + boardState.currentKif),
                  Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: cameraImageOrIcon()
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: const Text('初期'),
                        onPressed: _detectPiecePlace,
                      ),
                      ElevatedButton(
                        child: const Text('撮影'),
                        onPressed: _recognize,
                      ),
                      ElevatedButton(
                        child: const Text('投了'),
                        onPressed: () {
                          Wakelock.disable();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Result(
                              moveNumber: boardState.currentMoveNumber,
                              winner: (boardState.currentMoveNumber%2 == 0) ? "先手の勝ち" : "後手の勝ち",
                              sfen: sfenMoveList2Sfen(boardState.sfenMoveList),
                            )),
                          );
                        },
                      )
                    ],
                  ),
                ],
              ),
            )),
            OverlayLoadingMolecules(visible: onProgress)
          ]
        )
    );
  }
}
