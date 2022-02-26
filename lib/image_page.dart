import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
//import 'package:image/image.dart' as imgLib;

//import 'package:flutter_native_image/flutter_native_image.dart';

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

  late FolderProp folderprop;
  late AppBar appbar;
  @override
  void initState() {
    curfile = widget.path??"";
    loadImage(curfile);
    folderprop = FolderProp(curfile);
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    showBar();
  }

  void loadImage(String path) async {
    imgbin = File(path).readAsBytesSync();
    img = Image.memory(imgbin);

    curfile = path;
    
    viewstat = ViewStat(curfile);
    viewstat.setLastPath(curfile);
    viewstat.save();
  }

  @override
  Widget build(BuildContext context) {
    var toolbar = Visibility(
      visible: _visible,
      child: ImgPageBottomBar.build(context, this),
    );

    return Scaffold(
        appBar: AppBar(title: Text(folderprop.dirName() )),                
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

  void toggleBar(){
    setState(() {
      _visible = ! _visible;
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
            icon: Icon(Icons.fit_screen),
            label: "load",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_to_queue),
            label: "save",
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
            case 0: callback.loadScale(); break; 
            case 1: callback.saveScale(); break;
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
            case 5: callback.beforepage(); break;
            case 6: callback.nextpage(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
      );
  } 
}