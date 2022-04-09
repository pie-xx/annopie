import 'package:flutter/material.dart';
import 'package:flutter/src/services/hardware_keyboard.dart';

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

class KeyHandler {
  static HardwareKeyboard keyboard = HardwareKeyboard.instance;

  static const int KEY_Vup = 0x00070080;
  static const int KEY_Vdown = 0x00070081;
  static const int KEY_BackGes = 0x1100000000;
  static const int KEY_Back = 0x110000009e;

  static const int WKEY_ArrowDown = 0x00070051;
  static const int WKEY_ArrowUp = 0x00070052;
  static const int WKEY_Backspace = 0x0007002a;
  static const int WKEY_Escape = 0x00070029;

  static Map<int,Function> dispatcher = {};

  static void set_handler(Map<int,Function> dis ){
    dispatcher=dis;
    keyboard.addHandler(key_handler);
  }

  static void reset_handler(){
    keyboard.removeHandler(key_handler);
  }

  static bool key_handler(event) { 
    if( event is KeyDownEvent ){
      for( int p in dispatcher.keys ){
        if(event.physicalKey.usbHidUsage == p ){
          dispatcher[p]!();
          return true;
        }        
      }
    }
    return false;
  }
}
/*
        switch( event.physicalKey.usbHidUsage ){
          case KEY_Vdown:
          case WKEY_ArrowDown:
            next_area();
            break;
          case KEY_Vup:
          case WKEY_ArrowUp:
            before_area();
            break;
          case KEY_Back:
          case KEY_BackGes:
          case WKEY_Backspace:
          case WKEY_Escape:
            Navigator.pop(context);
            break;
        }
    }
    return true;
*/
