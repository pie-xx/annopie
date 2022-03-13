import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/src/services/hardware_keyboard.dart';

import 'folder_prop.dart';
import 'input_dialog.dart';

class ImagePage extends StatefulWidget {
  ImagePage({Key? key, this.path}) : super(key: key);
  final String? path;
  @override
  ImagePageState createState() => ImagePageState();
}

class ImagePageState extends State<ImagePage> {
  late Uint8List imgbin;

  late Image img; 

  int nextpagecount=0;
  int beforepagecount = 0;
  String curfile = "";

  late ViewStat viewstat;

  bool _visible = true;

  final _transformationController = TransformationController();
  Matrix4 scalevalue = Matrix4.identity();
  List<Matrix4> areas = [];
  int aindex = 0;

  late FolderProp folderprop;
  late AppBar appbar;

  bool loaddone = false;

  HardwareKeyboard keyboard = HardwareKeyboard.instance;

  static const int KEY_Vup = 0x00070080;
  static const int KEY_Vdown = 0x00070081;
  static const int KEY_BackGes = 0x1100000000;
  static const int KEY_Back = 0x110000009e;

  static const int WKEY_ArrowDown = 0x00070051;
  static const int WKEY_ArrowUp = 0x00070052;
  static const int WKEY_Backspace = 0x0007002a;
  static const int WKEY_Escape = 0x00070029;

  @override
  void initState() {
    curfile = widget.path??"";

    viewstat = ViewStat(curfile);
    areas = viewstat.getLastArea();
    aindex=0;

    if(areas.length!=0){
      _transformationController.value = areas[0];
      aindex=0;
    }else{
      _transformationController.value = Matrix4.identity();
    }
    print(_transformationController.value);


    loadImage(curfile);
    folderprop = FolderProp(curfile);
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    keyboard.addHandler((event) { 
      if( event is KeyDownEvent ){
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
    });

    showBar();
    await loadImage(curfile);
    setState(() {
      
    });


  }

  @override
  void dispose() {
    print('ImagePageState dispose');

    super.dispose();
  }

  void kurukuru(){
            showGeneralDialog(
              context: context,
              barrierDismissible: false,
              transitionDuration: Duration(milliseconds: 250), // ダイアログフェードインmsec
              barrierColor: Colors.black.withOpacity(0.5), // 画面マスクの透明度
              pageBuilder: (BuildContext context, Animation animation,
                  Animation secondaryAnimation) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              });
  }
  void kurukuruOff(){
    Navigator.pop(context);
  }

  Future<void>  loadImage(String path) async {
    imgbin = File(path).readAsBytesSync();
    img = Image.memory(imgbin);

    curfile = path;
    
    viewstat = ViewStat(curfile);
    viewstat.setLastPath(curfile);
    viewstat.save();
    loaddone = true;
  }

  @override
  Widget build(BuildContext context) {
    var toolbar = Visibility(
      visible: _visible,
      child: ImgPageBottomBar.build(context, this),
    );
    String appbartitle = "${folderprop.index(curfile)}: ${folderprop.dirName()}";
    if( areas.length > 0 ){
      appbartitle = "${folderprop.index(curfile)}(${aindex+1}/${areas.length}): ${folderprop.dirName()}";
    }
    Text appbarText = Text(appbartitle);

    var iviewer = InteractiveViewer(
            transformationController: _transformationController,
            onInteractionEnd: (details){
              //print("onInteractionEnd");
              //print(_transformationController.value);
            },
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.1,
            maxScale: 64,
            child: 
                Center( child: img, ),
          );

    var scaffold = Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(32.0),
          child: AppBar(title: appbarText,)
        ),  
        body: iviewer,
        bottomNavigationBar:
          toolbar
      );

    return  scaffold;
  }

  void showBar() {
    setState(() {              
      _visible = true;
    });
  }

  void eraseBar(){
    setState(() {              
      _visible = false;
    });
  }

  void toggleBar(){
    setState(() {
      _visible = ! _visible;
    });
  }

  addScale(){
    setState(() {
      areas.add(_transformationController.value);
      aindex = areas.length - 1;
      viewstat.setLastArea(areas);
      viewstat.save();
    });
  }

  clearScale(){
    setState(() {
      areas.clear();
      aindex = 0;
      viewstat.setLastArea(areas);
      viewstat.save();
    });
  }

  before_area(){
    --aindex;
    if( aindex < 0 ){
      aindex = areas.length - 1;
      beforepage();
    }
    if( areas.length > 0 ){
      setState(() {
        _transformationController.value = areas[aindex];
      });
    }
  }
  next_area(){
    ++aindex;
    if( aindex >= areas.length ){
      aindex = 0;
      nextpage();
    }
    if( areas.length > 0 ){
      setState(() {
        _transformationController.value = areas[aindex];
      });
    }
  }


nextpage(){
    try {
      var folderprop = FolderProp(curfile);
      bool find = false;
      for( var p in folderprop.plist ){
        if( find ){
          setState(() {
            loadImage(p.path);

            viewstat.setLastPath(p.path);
            viewstat.save();
          });
          return;
        }
        if( p.path == curfile ){
          find = true;
        }
      }
    }catch(e){
    }
  }

  beforepage(){
    try {

      String beforefile = folderprop.plist[0].path;
      for( var p in folderprop.plist ){
        if( p.path == curfile ){
          setState(() {
            loadImage(beforefile);
          
            viewstat.setLastPath(beforefile);
            viewstat.save();
          });
          return;
        }
        beforefile = p.path;
      }
    }catch(e){
    }
  }

  resetScale(){
    _transformationController.value = Matrix4.identity();
  }

  saveScale(){
    scalevalue = _transformationController.value;
  }
  loadScale(){
    _transformationController.value = scalevalue;
  }
}


class ImgPageBottomBar {

  static BottomNavigationBar build( BuildContext context, ImagePageState callback ){
    return 
      BottomNavigationBar( 
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_to_queue),
            label: "add",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.clear_all),
            label: "clear",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.no_encryption),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.no_encryption),
            label: "",
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.grey.shade400,
            icon: Icon(Icons.announcement),
            label: "annotation",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigate_before),
            label: "before",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigate_next),
            label: "next",
          ),
        ],
        onTap:(index) async {  
          switch(index) {
            case 0: callback.addScale(); break; 
            case 1: callback.clearScale(); break; 
            case 2: break;
            case 3: break;
            case 4: 
              String fname = callback.curfile;
              var annoProp = AnnotationProp(fname);
              var res = await inputDialog(context, 'Annotation', annoProp.readAnnotation(fname));
              if( res != null ){   
                  annoProp.writeAnnotation(fname, res);
                  annoProp.save();
              }
              break;
            case 5: await callback.before_area(); break;
            case 6: await callback.next_area(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
      );
  } 
}