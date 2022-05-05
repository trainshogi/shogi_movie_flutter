import 'package:flutter/material.dart';

void alertDialog(BuildContext context, String alertSentence) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("エラー"),
        content: Text(alertSentence),
        actions: <Widget>[
          // ボタン領域
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

void successDialog(BuildContext context, String alertSentence) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("成功"),
        content: Text(alertSentence),
        actions: <Widget>[
          // ボタン領域
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

void normalDialog(BuildContext context, String title, String alertSentence, Future<void> Function() onPressedFunction) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(title),
        content: Text(alertSentence),
        actions: <Widget>[
          // ボタン領域
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              onPressedFunction();
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

void textDialog(BuildContext context, String alertSentence) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("成功"),
        content: Text(alertSentence),
        actions: <Widget>[
          // ボタン領域
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

// 全画面プログレスダイアログを表示する関数
void showProgressDialog(BuildContext context) {
  showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
  );
}

Widget progressIndicatorOrEmpty(bool onProgress) {
  if (onProgress) {
    return const CircularProgressIndicator();
  }
  else {
    return Container();
  }
}