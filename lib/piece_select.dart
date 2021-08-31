import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/base_img_setting.dart';
import 'package:shogi_movie_flutter/piece_upsert.dart';

class PieceSelect extends StatefulWidget {
  const PieceSelect({Key? key}) : super(key: key);

  @override
  _PieceSelectState createState() => _PieceSelectState();
}

class _PieceSelectState extends State<PieceSelect> {

  // static const TextStyle defaultButtonTextStyle = TextStyle(fontSize: 40);

  Widget savedPieceWidget(String text) {
    return Row(
      children: [
        Expanded(child: ElevatedButton(
          child: Text(text),
          style: ElevatedButton.styleFrom(
            primary: Colors.white,
            onPrimary: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BaseImgSetting(dirName: text)),
            );
          },
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('駒選択'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // const Text('駒選択', style: defaultButtonTextStyle),
            savedPieceWidget('駒１'),
            savedPieceWidget('駒２'),
            savedPieceWidget('駒３'),
          ]
        ),
      )
    );
  }
}
