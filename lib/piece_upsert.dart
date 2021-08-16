import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'file_controller.dart';

class PieceUpsert extends StatefulWidget {
  const PieceUpsert({Key? key}) : super(key: key);

  @override
  _PieceUpsertState createState() => _PieceUpsertState();
}

class _PieceUpsertState extends State<PieceUpsert> {

  String pieceNameJapanese = "歩";
  File? imageFile;
  Image? image;
  Image? transImage;

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

    var savedFile = await FileController.saveLocalImage(imageFile, 'fu.jpg'); //追加

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
  void _addPoint(TapDownDetails details) {
    // setState()にリストを更新する関数を渡して状態を更新
    setState(() {
      _points.add(details.localPosition);
    });
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
            // TapDownイベントを検知
            onTapDown: _addPoint,
            // カスタムペイント
            child: CustomPaint(
              painter: MyPainter(_points),
              // タッチを有効にするため、childが必要
              child: transImage,
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('カメラで撮影'),
                  onPressed: () {
                    _getAndSaveImageFromDevice(ImageSource.camera); // New Line
                  },
                )),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('ライブラリから選択'),
                  onPressed: () {},
                )),
            ],
          ),
        )
      )
    );
  }
}

class MyPainter extends CustomPainter{
  final List<Offset> _points;
  final _rectPaint = Paint()..color = Colors.blue;

  MyPainter(this._points);

  @override
  void paint(Canvas canvas, Size size) {
    // 記憶している点を描画する
    for (var offset in _points) {
      canvas.drawRect(Rect.fromCenter(center: offset, width: 20.0, height: 20.0), _rectPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}