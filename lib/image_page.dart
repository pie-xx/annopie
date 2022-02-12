import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imgLib;



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

  late Completer<ui.Image> completer;
  late ImageStreamListener ilistener;
  late Image img; 
  //late bool done = false;
  late int pwidth;
  late int pheight;

  late Container ivew;

  bool scallmode = false;
  double oldX=0.0;
  double oldY=0.0;
  double oldmagratio=2.0;

  int nextpagecount=0;
  int beforepagecount = 0;
  String curfile = "";

  late ViewStat viewstat;

  late double vheightShow;
  late double vheightHide;

  bool _visible = true;

  final _transformationController = TransformationController();
  Matrix4 scalevalue = Matrix4.identity();

  @override
  void initState() {

    loadImage(widget.path??"");

    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    showBar();
  }

  void loadImage(String path){
    imgbin = File(path).readAsBytesSync();
    var image = imgLib.decodeImage(imgbin)!;
    pwidth = image.width;
    pheight = image.height;

    img = Image.memory(imgbin);

    curfile = path;
    
    viewstat = ViewStat(curfile);
    viewstat.setLastFile(curfile);
    viewstat.save();
  }

  @override
  Widget build(BuildContext context) {

    var toolbar = Visibility(
      visible: _visible,
      child: ImgPageBottomBar.build(context, this),
    );

    return Scaffold(
        appBar: AppBar(title: Text(widget.path??"" )),                
        body: InteractiveViewer(
            transformationController: _transformationController,
            onInteractionEnd: (details){
              print("onInteractionEnd");
              print(_transformationController.value);
            },
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.1,
            maxScale: 64,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  img,
                ],
              ),
            ),
          ),
        bottomNavigationBar:
          toolbar
      );
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

  nextpage(){
    try {
      var folderprop = FolderProp(curfile);
      bool find = false;
      for( var p in folderprop.plist ){
        if( find ){
          setState(() {
            loadImage(p.path);

            viewstat.setLastFile(p.path);
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
      var folderprop = FolderProp(curfile);
      String beforefile = folderprop.plist[0].path;
      for( var p in folderprop.plist ){
        if( p.path == curfile ){
          setState(() {
            loadImage(beforefile);
          
            viewstat.setLastFile(beforefile);
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
            icon: Icon(Icons.close),
            label: "close menu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brightness_high),
            label: "high",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brightness_low),
            label: "low",
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
            case 0: callback.eraseBar(); break; 
            case 1: callback.loadScale(); break;//callback.contrast(200); break;
            case 2: callback.saveScale(); break;//callback.contrast(150); break;
            case 3: 
              String fname = callback.widget.path??"";
              var annoProp = AnnotationProp(fname);
              var res = await inputDialog(context, 'Annotation', annoProp.readAnnotation(fname));
              if( res != "" ){   
                  annoProp.writeAnnotation(fname, res);
                  annoProp.save();
              }
              break;
            case 4: callback.beforepage(); break;
            case 5: callback.nextpage(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
      );
  } 
}