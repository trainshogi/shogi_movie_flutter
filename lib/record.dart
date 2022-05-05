import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shogi_movie_flutter/controller/audio_controller.dart';
import 'package:shogi_movie_flutter/controller/camera.dart';
import 'package:shogi_movie_flutter/result.dart';
import 'package:shogi_movie_flutter/util/util.dart';
import 'package:shogi_movie_flutter/util/util_sfen.dart';
import 'package:shogi_movie_flutter/util/util_widget.dart';
import 'package:wakelock/wakelock.dart';

import 'domain/board.dart';
import 'domain/piece.dart';
import 'domain/piece_list.dart';
import 'controller/file_controller.dart';
import 'controller/overlay_loading_molecules.dart';

class Record extends StatefulWidget {
  final String dirName;
  final List<Offset> relativePoints;
  const Record({Key? key, required this.dirName, required this.relativePoints}) : super(key: key);

  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<Record> {
  FileController fileController = FileController();
  AudioController audioController = AudioController();
  String? imageFilePath;
  File? imageFile;
  Image? image;
  int currentMoveNumber = 0;
  // String currentSfen = "";
  Board board = Board();
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
    audioController.play(["initial"]);
    // currentSfen = initial_sfen;
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    Wakelock.disable();
    _controller?.dispose();
    super.dispose();
  }

  void onPressedCamera() {
    // set waiting loop
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
        Map<String, dynamic> detectPlaceJson = await getPiecePlace(
          platformPieceDetect, imageFilePath!, widget.relativePoints, directoryPath);
        String piecePlace = detectPlaceJson["sfen"];
        print(detectPlaceJson.toString());

        // detect movement
        Map<String, int> moveMap = getMovement(currentPiecePlace, detectPlaceJson["sfen"]);

        // detect piece
        int prevSpace = moveMap["prevSpace"]!;
        int nextSpace = moveMap["nextSpace"]!;
        Piece prevPiece = (prevSpace != -1) ? board.board[prevSpace~/10][prevSpace%10] : Piece.NONE;
        Piece nextPiece;
        bool nari = false;
        Piece piece;
        String movePattern = "";
        if (prevSpace > -1 && nextSpace > -1) {
          // if user moves piece, just detect nextSpace's piece
          movePattern = "move";
          piece = prevPiece;
          String pieceNames = (prevPiece.promoted == Piece.NONE)
              ? prevPiece.english : prevPiece.english + "," + prevPiece.promoted.english;
          Map<String, dynamic> detectPieceJson = await onePieceDetect(
              platformPieceDetect, imageFilePath!, widget.relativePoints,
              directoryPath, moveMap, pieceNames);
          nextPiece = Piece.values.firstWhere((e) => e.english == detectPieceJson["piece"]);
          // if prevPiece and nextPiece is different, it is "nari"
          nari = (prevPiece != nextPiece) ? true : false;
        }
        else if (nextSpace > -1) {
          // if user put piece, just detect nextSpace's piece
          movePattern = "put";
          String pieceNames = (currentMoveNumber%2 == 0)
              ? firstNonPromotedPieceList.map((Piece p) => p.english).toList().join(",")
              : secondNonPromotedPieceList.map((Piece p) => p.english).toList().join(",");
          Map<String, dynamic> detectPieceJson = await onePieceDetect(
              platformPieceDetect, imageFilePath!, widget.relativePoints,
              directoryPath, moveMap, pieceNames);
          piece = Piece.values.firstWhere((e) => e.english == detectPieceJson["piece"]);
          nextPiece = Piece.values.firstWhere((e) => e.english == detectPieceJson["piece"]);
        }
        else {
          // if user take piece, search all pieces and get diff
          movePattern = "take";
          piece = prevPiece;
          String pieceNames = (prevPiece.promoted == Piece.NONE)
              ? prevPiece.english : prevPiece.english + "," + prevPiece.promoted.english;
          print(pieceNames);
          print(board.toSfen());
          Map<String, dynamic> detectPieceJson = await allPieceDetect(
              platformPieceDetect, imageFilePath!, widget.relativePoints,
              directoryPath, board, pieceNames);
          Board detectedBoard = Board().fromSfen(detectPieceJson["sfen"]);
          Map<String, int> moveMap = getMovementWithBoard(board, detectedBoard);
          nextSpace = moveMap["nextSpace"]!;
          nextPiece = detectedBoard.board[nextSpace~/10][nextSpace%10];
          // if prevPiece and nextPiece is different, it is "nari"
          nari = (prevPiece != nextPiece) ? true : false;
        }

        setState(() {
          _cameraOn = true;
          onProgress = false;
          currentMoveNumber += 1;
          updateBoard(prevSpace, nextSpace, piece, board, nari);
          currentKif = createKif(prevSpace, nextSpace, piece, board, nari);
          sfenMoveList.add(createSfenMove(prevSpace, nextSpace, piece, board, nari));
          currentPiecePlace = piecePlace;
        });

        // play sounds
        List<String> filenames = createAudioFilenameList(prevSpace, nextSpace, piece, board, movePattern, nari);
        audioController.play(filenames);
      });
    });
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
                        onPressed: onPressedCamera,
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
