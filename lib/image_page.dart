import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:image/image.dart' as imgLib;

import 'folder_prop.dart';

class ImagePage extends StatefulWidget {
  ImagePage({Key? key, this.path}) : super(key: key);
  final String? path;
  @override
  ImagePageState createState() => ImagePageState();
}

// MediaQuery.of(context).size  Size(462.0, 876.1)

class ImagePageState extends State<ImagePage> {
  late Uint8List imgbin;

  late Completer<ui.Image> completer;
  late ImageStreamListener ilistener;
  late Image img; 
  //late bool done = false;
  late int pwidth;
  late int pheight;
  late double vwidth;
  late double vheight;
  late double aliX;
  late double aliY;
  //late double baseratio;
  late double magratio;
  late Container ivew;

  bool scallmode = false;
  double oldX=0.0;
  double oldY=0.0;
  double oldmagratio=2.0;

  int nextpagecount=0;
  int beforepagecount = 0;
  String curfile = "";
  double _widthFactor=1.0;
  double _heightFactor=1.0;

  bool _visible = true;

  @override
  void initState() {

    loadImage(widget.path??"");

    magratio = 1.0;
    aliX=0.0;
    aliY=0.0;

    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    vwidth = MediaQuery.of(context).size.width;
    vheight = MediaQuery.of(context).size.height;
  }

  void loadImage(String path){
    imgbin = File(path).readAsBytesSync();
    var image = imgLib.decodeImage(imgbin)!;
    pwidth = image.width;
    pheight = image.height;

    img = Image.memory(imgbin);

    curfile = path;
  }

  @override
  Widget build(BuildContext context) {
    //if( ! done ){
    //  return Container();
    //}

    if(vwidth < vheight){
      double cwidth = ( vwidth / vheight ) * pheight;

      _widthFactor = ( cwidth / pwidth ) / magratio;
      _heightFactor = 1.0 / magratio;
    }else{
      double cheight = ( vheight / vwidth ) * pwidth;

      _widthFactor = 1.0 / magratio;
      _heightFactor = ( cheight / pheight ) / magratio;
    }

    ivew = 
       Container(
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.center,
        child: 
        FittedBox(
            fit: BoxFit.fill,
            child: ClipRect(
              child: Container(
                  child: Align(
                    alignment: Alignment(aliX, aliY),
                    widthFactor: _widthFactor,
                    heightFactor: _heightFactor,
                    child: img,
                    ),
                  ),
              ),
            ),
        );
    
    var toolbar = Visibility(
      visible: _visible,
      child: ImgPageBottomBar.build(context, this),
    );

    return Scaffold(
        body: scallview(),
        bottomNavigationBar:
          toolbar
      );
  }

  GestureDetector scallview(){    
        return GestureDetector(
          onScaleStart: (details){
            scallmode = true;
            oldX = details.focalPoint.dx;
            oldY = details.focalPoint.dy;
            oldmagratio = magratio;
          },
          onScaleUpdate: (details){
            setState(() {
            double dx = details.focalPoint.dx - oldX;
            double dy = details.focalPoint.dy - oldY;
            oldX = details.focalPoint.dx;
            oldY = details.focalPoint.dy;
            aliX = aliX - dx  / 100;
            if( aliX < -1.0){
              aliX = -1.0;
            }
            if( aliX > 1.0 ){
              aliX = 1.0;
            }
            aliY = aliY - dy /100;
            if( aliY < -1.1){
              beforepagecount = beforepagecount + 1;
              aliY = -1.0;
              if( beforepagecount > 10){
                print("before!!");
                //beforepage();
              }
            }else{
              if( aliY > -1.0 ){
                beforepagecount = 0;
              }
            }
            if( aliY > 1.1 ){
              nextpagecount = nextpagecount + 1;
              aliY = 1.0;
              if( nextpagecount > 10){
                print("next!!");
                //nextpage();
              }
            }else{
              if( aliY < 1.0 ){
                nextpagecount = 0;
              }
            }

            magratio = oldmagratio * details.scale;
            if( magratio < 0.5 ){
              magratio = 0.5 ;
            }
            if( magratio > 2 ){
              magratio = 2;
            }
            });
          },
          onScaleEnd: (detail){
            scallmode = false;
          },        
          onDoubleTap: (){
            scallmode = false;
            setState(() {              
            });
          },
          onLongPressMoveUpdate: (detail) async {
            setState(() {              
              _visible = true;
            });
          },
          child: ivew,
        );
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
            aliX=0.0;
            aliY=0.0;
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
            aliX=0.0;
            aliY=0.0;
          });
          return;
        }
      }
    }catch(e){
    }
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
            case 1: //callback.contrast(200); break;
            case 2: //callback.contrast(150); break;
            case 3: 
              //await AnnoDialog( context, ).showDialog(callback.curfile);
              break;
            case 4: callback.beforepage(); break;
            case 5: callback.nextpage(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
      );
  } 
}