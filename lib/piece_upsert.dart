import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shogi_movie_flutter/domain/piece.dart';

import 'domain/piece_list.dart';
import 'controller/file_controller.dart';
import 'controller/image_and_painter.dart';
import 'util/util.dart';
import 'util/util_widget.dart';

class PieceUpsert extends StatefulWidget {
  final String dirName;
  const PieceUpsert({Key? key, required this.dirName}) : super(key: key);

  @override
  _PieceUpsertState createState() => _PieceUpsertState();
}

class _PieceUpsertState extends State<PieceUpsert> {

  // variables
  File? imageFile;
  int movePointIndex = 0;
  int pieceNameIndex = 0;
  String pieceGroupName = ""; // initialize in initState
  GlobalKey globalKeyForPainter = GlobalKey();

  // static variables
  final pieceNameList = firstPieceList;

  static const platformPieceDetect = MethodChannel('com.nkkuma.dev/piece_detect');

  // タッチした点を覚えておく
  final _points = <Offset>[];

  void _getImageFromDevice() async {
    File savedFile = await FileController.loadLocalImage(
        pieceGroupName, pieceNameList[pieceNameIndex].english + '.jpg');
    File pointFile = await FileController.loadLocalFile(
        pieceGroupName, pieceNameList[pieceNameIndex].english + '.txt');

    if (savedFile.existsSync()) {
      setState(() {
        imageFile = savedFile; //変更
      });

      // _points file
      if (pointFile.existsSync()) {
        setState(() {
          List<Offset> absolutePoints = string2Offsets(pointFile.readAsStringSync().split("/")[0]);
          _points.addAll(absolutePoints);
        });
      }
    }
  }

  void _getAndSaveImageFromDevice(ImageSource source) async {
    // 撮影/選択したFileが返ってくる
    final ImagePicker _picker = ImagePicker();
    var imageFile = await _picker.pickImage(source: source);
    // 撮影せずに閉じた場合はnullになる
    if (imageFile == null) {
      return;
    }

    var savedFile = await FileController.saveLocalImageWithResize(
        imageFile, pieceGroupName, pieceNameList[pieceNameIndex].english + '.jpg', 320); //追加

    if (savedFile.existsSync()) {
      findContour(savedFile.path).then((value) => {
        setState(() {
          _points.clear();
          value["points"]?.forEach((element) {
            _points.add(Offset(element[0].toDouble(), element[1].toDouble()));
          });
        })
      });
      setState(() {
        // this.imageFile = imageFile;
        this.imageFile = savedFile; //変更
      });
    }
  }

  Future<Map<String, dynamic>> findContour(String imageFilePath) async {
    Map<String, dynamic> pieceRequestMap = {
      "platform": platformPieceDetect,
      "methodName": "find_contours",
      "args": {
        'srcPath': imageFilePath
      }
    };
    return jsonDecode(await callInvokeMethod(pieceRequestMap) as String);
  }

  void _prevPieceButtonPushed() {
    if (imageFile == null) {
      alertDialog(context, '駒の画像が設定されていません。');
    }
    else if (_points.length < 3) {
      alertDialog(context, '駒の枠が設定されていません。');
    }
    else if (pieceNameIndex == 0) {
      alertDialog(context, '前の駒は存在しません。');
    }
    else {
      _saveList();
      setState(() {
        // initialize
        imageFile = null;
        _points.clear();
        // set index
        pieceNameIndex -= 1;
      });
      _getImageFromDevice();
    }
  }

  void _nextPieceButtonPushed() {
    if (imageFile == null) {
      alertDialog(context, '駒の画像が設定されていません。');
    }
    else if (_points.length < 3) {
      alertDialog(context, '駒の枠が設定されていません。');
    }
    else if (pieceNameIndex == pieceNameList.length - 1) {
      _saveList();
      successDialog(context, '駒の設定が終了しました。');
    }
    else {
      _saveList();
      setState(() {
        // initialize
        imageFile = null;
        _points.clear();
        // set index
        pieceNameIndex += 1;
      });
      _getImageFromDevice();
    }
  }

  Size getPainterSize() {
    return (globalKeyForPainter.currentContext?.findRenderObject() as RenderBox).size;
  }

  Future<void> _saveList() async {
    String absoluteConverted = _points.join(":");
    String relativeConverted = absolutePoints2relativePoints(_points, getPainterSize()).join(":");
    print(absoluteConverted + "/" + relativeConverted);
    FileController.saveLocalFile(absoluteConverted + "/" + relativeConverted,
        pieceGroupName, pieceNameList[pieceNameIndex].english + '.txt'); //追加
  }

  @override
  void initState() {
    pieceGroupName = widget.dirName;
    _getImageFromDevice();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('駒画像撮影・枠位置編集'),
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
                child: Text(pieceNameList[pieceNameIndex].japanese + 'の画像設定'),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: ImageAndPainter(
                    maxPointLength: -1, points: _points,
                    imageBytes: imageFile?.readAsBytesSync(),
                    imageWidget: (imageFile == null) ? null : Image.memory(imageFile!.readAsBytesSync()),
                    key: globalKeyForPainter),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('カメラで撮影'),
                  onPressed: () {
                    _getAndSaveImageFromDevice(ImageSource.camera);
                  },
                )
              ),
              Row(
                children: [
                  Container(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        child: const Text('前の駒を設定'),
                        onPressed: () => _prevPieceButtonPushed(),
                      )
                  ),
                  Container(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        child: const Text('次の駒を設定'),
                        onPressed: () => _nextPieceButtonPushed(),
                      )
                  ),
                ],
              )
            ],
          ),
        )
      )
    );
  }
}