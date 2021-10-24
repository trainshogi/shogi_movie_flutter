import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/util.dart';

import 'frame_painter.dart';

class ImageAndPainter extends StatefulWidget {
  final int maxPointLength;
  // タッチした点を覚えておく
  final List<Offset> points;
  final Uint8List? imageBytes;
  final Widget? imageWidget;
  const ImageAndPainter({Key? key, 
    required this.maxPointLength,
    required this.points,
    required this.imageBytes,
    required this.imageWidget,
  }) : super(key: key);

  @override
  _ImageAndPainterState createState() => _ImageAndPainterState();
}

class _ImageAndPainterState extends State<ImageAndPainter> {

  int movePointIndex = 0;

  // 点を追加
  void _addPoint(TapUpDetails details) {
    // setState()にリストを更新する関数を渡して状態を更新
    if (widget.maxPointLength <= 0 || (widget.maxPointLength > 0 && widget.points.length < widget.maxPointLength)) {
      setState(() {
        widget.points.add(details.localPosition);
      });
    }
    else {
      alertDialog(context, "枠の角は" + widget.maxPointLength.toString() + "点より多く設定できません");
    }
  }

  // singleTapに制御がいかないようにここは必要。
  void _catchDoubleTap() {
  }

  void _deletePoint(TapDownDetails details) {
    if (widget.points.isNotEmpty) {
      int removePointIndex = getNearestPointIndex(widget.points, details.localPosition);
      setState(() {
        widget.points.removeAt(removePointIndex);
      });
    }
  }

  void _setMovePointIndex(DragStartDetails details) {
    if (widget.points.isNotEmpty) {
      movePointIndex = getNearestPointIndex(widget.points, details.localPosition);
      setState(() {
        widget.points[movePointIndex] = details.localPosition;
      });
    }
  }

  void _movePoint(DragUpdateDetails details) {
    if (widget.points.isNotEmpty) {
      setState(() {
        widget.points[movePointIndex] = details.localPosition;
      });
    }
  }

  Widget imageAndPainter() {
    if (widget.imageBytes == null) {
      return const Icon(Icons.no_sim);
    }
    else {
      return Stack(
        children: [
          widget.imageWidget!,
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
              painter: FramePainter(widget.points),
              // タッチを有効にするため、childが必要
              child: Image.memory(
                  widget.imageBytes!,
                  color: const Color.fromRGBO(255, 255, 255, 0)
              )
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return imageAndPainter();
  }
}
