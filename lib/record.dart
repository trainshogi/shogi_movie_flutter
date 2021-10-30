import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shogi_movie_flutter/camera.dart';
import 'package:shogi_movie_flutter/result.dart';
import 'package:shogi_movie_flutter/util.dart';
import 'package:shogi_movie_flutter/util_sfen.dart';
import 'package:wakelock/wakelock.dart';

import 'file_controller.dart';
import 'overlay_loading_molecules.dart';

class Record extends StatefulWidget {
  final String dirName;
  final List<Offset> relativePoints;
  const Record({Key? key, required this.dirName, required this.relativePoints}) : super(key: key);

  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<Record> {
  FileController fileController = FileController();
  String? imageFilePath;
  File? imageFile;
  Image? image;
  final AudioCache _player = AudioCache(fixedPlayer: AudioPlayer());
  int currentMoveNumber = 0;
  String currentSfen = "";
  String currentPiecePlace = "ZZZZZZZZZ/1Z11111Z1/ZZZZZZZZZ/111111111/111111111/111111111/ZZZZZZZZZ/1Z11111Z1/ZZZZZZZZZ";
  String currentKif = "";
  List<String> sfenMoveList = [];
  //カメラリスト
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  String directoryPath = "";
  bool _cameraOn = false;
  bool _cameraStreamOn = false;
  bool onProgress = false;
  late CameraImage _savedImage;

  static const platformPieceDetect = MethodChannel('com.nkkuma.dev/piece_detect');

  Widget imageOrIcon() {
    if (_controller == null || _cameraOn == false) {
      return const Icon(Icons.no_sim);
    }
    else {
      return Camera(controller:_controller!);
    }
  }

  // prepare camera
  void initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0],
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.yuv420);
      _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }

        normalDialog(context, "確認", "記録開始します", () => _controller!.startImageStream((CameraImage image) => _processCameraImage(image)));

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
    return (_controller != null) ? Camera(controller:_controller!) : const Icon(Icons.no_sim);
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    Wakelock.enable();
    _player.load("sounds/initial.mp3");
    _player.play("sounds/initial.mp3");
    currentSfen = initial_sfen;
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(currentMoveNumber.toString() + '手目：' + currentKif),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: cameraImageOrIcon()
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: const Text('撮影'),
                        onPressed: () {
                          // set waiting loop
                          if (_cameraStreamOn == false) {
                            _controller!.startImageStream((CameraImage image) => _processCameraImage(image));
                            return;
                          }

                          // take picture
                          // _controller!.takePicture().then((value) {
                          fileController.getImgFile(_savedImage).then((value) {
                          // ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
                            imageFilePath = value.path;
                            setState(() {
                              _cameraOn = false;
                              onProgress = true;
                            });
                            // recognize image
                            FileController.directoryPath(widget.dirName).then((value) async {
                              directoryPath = value;
                              // get piece place
                              Map<String, dynamic> placeRequestMap = {
                                "platform": platformPieceDetect,
                                "methodName": "piece_place_detect",
                                "args": {
                                  'srcPath': imageFilePath!,
                                  'points': widget.relativePoints.toString(),
                                  'dirName': directoryPath
                                }
                              };
                              var detectPlaceJson = jsonDecode(await callInvokeMethod(placeRequestMap) as String);
                              String piecePlace = detectPlaceJson["sfen"];
                              print(detectPlaceJson.toString());

                              // detect movement
                              var moveMap = getMovement(currentPiecePlace, detectPlaceJson["sfen"]);

                              // detect piece
                              int prevSpace = moveMap["prevSpace"]!;
                              int nextSpace = moveMap["nextSpace"]!;
                              String prevPiece = (prevSpace != -1) ? getPieceFromSfen(currentSfen, prevSpace) : "";
                              String nextPiece;
                              String piece;
                              String movePattern = "";
                              if (prevSpace > -1 && nextSpace > -1) {
                                // if user moves piece, just detect nextSpace's piece
                                movePattern = "move";
                                piece = prevPiece;
                                String promotePiece = promoteEnglishPieceName(prevPiece);
                                String pieceNames = (promotePiece.isEmpty) ? prevPiece : prevPiece + "," + promotePiece;
                                Map<String, dynamic> pieceRequestMap = {
                                  "platform": platformPieceDetect,
                                  "methodName": "one_piece_detect",
                                  "args": {
                                    'srcPath': imageFilePath!,
                                    'dirName': directoryPath,
                                    'points': widget.relativePoints.toString(),
                                    'space': (moveMap["nextSpace"]!%10).toString() + "," + (moveMap["nextSpace"]!/10).floor().toString(),
                                    'pieceNames': pieceNames
                                  }
                                };
                                var detectPieceJson = jsonDecode(await callInvokeMethod(pieceRequestMap) as String);
                                nextPiece = detectPieceJson["piece"];
                                // if prevPiece and nextPiece is different, it is "nari"

                              }
                              else if (nextSpace > -1) {
                                // if user put piece, just detect nextSpace's piece
                                movePattern = "put";
                                String pieceNames = (currentMoveNumber%2 == 0)
                                    ? nonPromotedFirstMoveEnglishPieceNameList.join(",")
                                    : nonPromotedSecondMoveEnglishPieceNameList.join(",");
                                Map<String, dynamic> pieceRequestMap = {
                                  "platform": platformPieceDetect,
                                  "methodName": "one_piece_detect",
                                  "args": {
                                    'srcPath': imageFilePath!,
                                    'dirName': directoryPath,
                                    'points': widget.relativePoints.toString(),
                                    'space': (moveMap["nextSpace"]!%10).toString() + "," + (moveMap["nextSpace"]!/10).floor().toString(),
                                    'pieceNames': pieceNames
                                  }
                                };
                                var detectPieceJson = jsonDecode(await callInvokeMethod(pieceRequestMap) as String);
                                piece = detectPieceJson["piece"];
                                nextPiece = detectPieceJson["piece"];
                              }
                              else {
                                // if user take piece, search all pieces and get diff
                                movePattern = "take";
                                piece = prevPiece;
                                String promotePiece = promoteEnglishPieceName(prevPiece);
                                String pieceNames = (promotePiece.isEmpty) ? prevPiece : prevPiece + "," + promotePiece;
                                String tookedSfen = currentSfen;
                                Map<String, dynamic> pieceRequestMap = {
                                  "platform": platformPieceDetect,
                                  "methodName": "all_piece_detect",
                                  "args": {
                                    'srcPath': imageFilePath!,
                                    'dirName': directoryPath,
                                    'points': widget.relativePoints.toString(),
                                    'sfen': tookedSfen,
                                    'pieceNames': pieceNames
                                  }
                                };
                                var detectPieceJson = jsonDecode(await callInvokeMethod(pieceRequestMap) as String);
                                var moveMap = getMovement(currentSfen, detectPieceJson["sfen"]);
                                // prevSpace = moveMap["prevSpace"]!;
                                nextSpace = moveMap["nextSpace"]!;
                                nextPiece = getPieceFromSfen(detectPieceJson["sfen"], nextSpace);
                                // if prevPiece and nextPiece is different, it is "nari"
                              }

                              setState(() {
                                _cameraOn = true;
                                onProgress = false;
                                currentMoveNumber += 1;
                                currentKif = createKif(prevSpace, nextSpace, piece, currentSfen);
                                sfenMoveList.add(createSfenMove(prevSpace, nextSpace, piece, currentSfen));
                                currentPiecePlace = piecePlace;
                                currentSfen = createSfenPhase(prevSpace, nextSpace, piece, currentSfen);
                              });

                              // play sounds
                              List<String> filenames = createAudioFilenameList(prevSpace, nextSpace, piece, currentSfen, movePattern);
                              for (String filename in filenames) {
                                _player.load("sounds/$filename.mp3");
                                _player.play("sounds/$filename.mp3");
                                await Future.delayed(const Duration(seconds: 1));
                              }
                            });
                          });
                        },
                      ),
                      ElevatedButton(
                        child: const Text('投了'),
                        onPressed: () {
                          Wakelock.disable();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Result(
                              moveNumber: currentMoveNumber,
                              winner: (currentMoveNumber%2 == 0) ? "先手の勝ち" : "後手の勝ち",
                              sfen: sfenMoveList2Sfen(sfenMoveList),
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
