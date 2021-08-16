import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/piece_upsert.dart';

class PieceSelect extends StatefulWidget {
  const PieceSelect({Key? key}) : super(key: key);

  @override
  _PieceSelectState createState() => _PieceSelectState();
}

class _PieceSelectState extends State<PieceSelect> {

  static const TextStyle defaultButtonTextStyle = TextStyle(fontSize: 40);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Text('駒選択', style: defaultButtonTextStyle),
            ElevatedButton(
              child: const Text('駒1', style: defaultButtonTextStyle),
              style: ElevatedButton.styleFrom(
                primary: Colors.blueAccent,
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
            ),
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
          ]
        ),
      )
    );
  }
}
