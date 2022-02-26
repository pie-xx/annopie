import 'package:flutter/material.dart';

Future<String?> inputDialog(BuildContext context, String title, String lastdir) async {
  final textController = TextEditingController();
  textController.text = lastdir;

  String? res = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: 
          TextField(
            controller: textController,
//              decoration: InputDecoration(hintText: "ここに入力"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context, textController.text );
              },
            ),
          ],
        );
      });
  return res;
}
