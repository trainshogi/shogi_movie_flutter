import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shogi_movie_flutter/frame_painter.dart';

import 'file_controller.dart';
import 'util.dart';

class PieceUpsert extends StatefulWidget {
  final String dirName;
  const PieceUpsert({Key? key, required this.dirName}) : super(key: key);

  @override
  _PieceUpsertState createState() => _PieceUpsertState();
}

class _PieceUpsertState extends State<PieceUpsert> {

  // variables
  File? imageFile;
  Image? image;
  Image? transImage;
  int movePointIndex = 0;
  int pieceNameIndex = 0;
  String pieceGroupName = ""; // initialize in initState
  String pieceNameJapanese = "歩兵";
  GlobalKey globalKeyForPainter = GlobalKey();

  // static variables
  final pieceNameListJapanese = [
    "歩兵", "香車", "桂馬", "銀将", "金将", "角行", "飛車", "王将", "玉将",
    "と金", "成香", "成桂", "成銀", "竜馬", "龍王"
  ];
  final pieceNameListEnglish = [
    "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou", "gyoku",
    "nfu", "nkyo", "nkei", "ngin", "nkaku", "nhisya"
  ];

  // タッチした点を覚えておく
  final _points = <Offset>[];

  void _getImageFromDevice() async {
    File savedFile = await FileController.loadLocalImage(
        pieceGroupName, pieceNameListEnglish[pieceNameIndex] + '.jpg');
    File pointFile = await FileController.loadLocalFile(
        pieceGroupName, pieceNameListEnglish[pieceNameIndex] + '.txt');

    if (savedFile.existsSync()) {
      setState(() {
        // this.imageFile = imageFile;
        imageFile = savedFile; //変更
        image = Image.memory(savedFile.readAsBytesSync());
        transImage = Image.memory(
            savedFile.readAsBytesSync(),
            color: const Color.fromRGBO(255, 255, 255, 0)
        );
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

    var savedFile = await FileController.saveLocalImage(
        imageFile, pieceGroupName, pieceNameListEnglish[pieceNameIndex] + '.jpg'); //追加

    if (savedFile.existsSync()) {
      setState(() {
        // this.imageFile = imageFile;
        this.imageFile = savedFile; //変更
        image = Image.memory(savedFile.readAsBytesSync());
        transImage = Image.memory(
            savedFile.readAsBytesSync(),
            color: const Color.fromRGBO(255, 255, 255, 0)
        );
      });
    }
  }

  // 点を追加
  void _addPoint(TapUpDetails details) {
    // setState()にリストを更新する関数を渡して状態を更新
    setState(() {
      _points.add(details.localPosition);
    });
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
        key: globalKeyForPainter,
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
        image = null;
        transImage = null;
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
    else if (pieceNameIndex == pieceNameListJapanese.length - 1) {
      _saveList();
      successDialog(context, '駒の設定が終了しました。');
    }
    else {
      _saveList();
      setState(() {
        // initialize
        imageFile = null;
        image = null;
        transImage = null;
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
        pieceGroupName, pieceNameListEnglish[pieceNameIndex] + '.txt'); //追加
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
                child: Text(pieceNameListJapanese[pieceNameIndex] + 'の画像設定'),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: imageAndPainter(),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('カメラで撮影'),
                  onPressed: () {
                    // _getAndSaveImageFromDevice(ImageSource.camera);
                    _getAndSaveImageFromDevice(ImageSource.gallery);
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