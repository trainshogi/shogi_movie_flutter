import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/base_img_setting.dart';
import 'package:shogi_movie_flutter/piece_upsert.dart';

class PieceSelectAndEdit extends StatefulWidget {
  const PieceSelectAndEdit({Key? key}) : super(key: key);

  @override
  _PieceSelectAndEditState createState() => _PieceSelectAndEditState();
}

class _PieceSelectAndEditState extends State<PieceSelectAndEdit> {

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
          },
        )),
        ElevatedButton(
          child: const Text('変更'),
          style: ElevatedButton.styleFrom(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PieceUpsert()),
            );
          },
        ),
        ElevatedButton(
          child: const Text('削除'),
          style: ElevatedButton.styleFrom(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
          },
        ),
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
