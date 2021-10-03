import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shogi_movie_flutter/result.dart';
import 'package:shogi_movie_flutter/util_sfen.dart';

import 'file_controller.dart';

class Record extends StatefulWidget {
  final String dirName;
  final List<Offset> relativePoints;
  const Record({Key? key, required this.dirName, required this.relativePoints}) : super(key: key);

  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<Record> {
  String? imageFilePath;
  File? imageFile;
  Image? image;
  final AudioCache _player = AudioCache(fixedPlayer: AudioPlayer());
  int currentMoveNumber = 0;
  String currentSfen = "";
  String currentKif = "";
  List<String> sfenMoveList = [];
  //カメラリスト
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  String directoryPath = "";
  bool pending = false;

  static const platformPieceDetect = MethodChannel('com.nkkuma.dev/piece_detect');

  Widget imageOrIcon() {
    if (_controller == null || pending == true) {
      return const Icon(Icons.no_sim);
    }
    else {
      return
        Container(
          padding: const EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 0.0),
          // child: CameraPreview(_controller!)
          child: const Icon(Icons.no_sim)
        );
    }
  }

  // prepare camera
  void initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }

        //カメラ接続時にbuildするようsetStateを呼び出し
        setState(() {});
      });
    }
  }

  @override
  void initState(){
    super.initState();
    _player.load("sounds/initial.mp3");
    _player.play("sounds/initial.mp3");
    initCamera();
    currentSfen = initial_sfen;
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller!.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('棋譜記録'),
        ),
        body: Center(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(currentMoveNumber.toString() + '手目：' + currentKif),
                  imageOrIcon(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: const Text('撮影'),
                        onPressed: () {
                          // set waiting loop
                          // take picture
                          setState(() {
                            pending = true;
                          });
                          // imageFilePath = (await _controller!.takePicture()).path;
                          ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
                            imageFilePath = value?.path;
                            // recognize image
                            FileController.directoryPath(widget.dirName).then((value) {
                              directoryPath = value;
                              platformPieceDetect.invokeMethod(
                                  'piece_detect',
                                  <String, String>{
                                    'srcPath': imageFilePath!,
                                    'points': widget.relativePoints.toString(),
                                    'dirName': directoryPath
                                  }
                              ).then((result) async {
                                // create diff and sound list
                                List<String> move = getKifMovement(currentSfen, jsonDecode(result)['sfen']);

                                setState(() {
                                  pending = false;
                                  currentMoveNumber += 1;
                                  currentKif = sfenList2Kif(move);
                                  sfenMoveList.add(getSfenMovement(currentSfen, jsonDecode(result)['sfen']));
                                });

                                // play sounds
                                List<String> filenames = sfenList2AudioFilename(move);
                                for (String filename in filenames) {
                                  _player.load("sounds/$filename.mp3");
                                  _player.play("sounds/$filename.mp3");
                                  await Future.delayed(const Duration(seconds: 1));
                                }
                              });
                            });
                          });
                        },
                      ),
                      ElevatedButton(
                        child: const Text('投了'),
                        onPressed: () {
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
            )
        )
    );
  }
}
