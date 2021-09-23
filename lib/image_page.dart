import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:sprintf/sprintf.dart';

class ImagePage extends StatefulWidget {
  ImagePage({Key? key, this.path}) : super(key: key);
  final String? path;
  @override
  ImagePageState createState() => ImagePageState();
}

// MediaQuery.of(context).size  Size(462.0, 876.1)

class ImagePageState extends State<ImagePage> {
  late Completer<ui.Image> completer;
  late ImageStreamListener ilistener;
  late Image img; 
  late bool done = false;
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
  @override
  void initState() {
    // TODO: implement initState
    curfile = widget.path??"";

    magratio = 1.0;
    aliX=0.0;
    aliY=0.0;

    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    img = Image.file(File(curfile));

    completer = new Completer<ui.Image>();

    ilistener = new ImageStreamListener(
      (ImageInfo info, bool _) { 
          completer.complete(info.image);
          print(sprintf("image %s %d x %d", [widget.path, info.image.width, info.image.height]));
          pwidth = info.image.width;
          pheight = info.image.height;

          vwidth = MediaQuery.of(context).size.width;
          vheight = MediaQuery.of(context).size.height;

          done = true;

          setState(() {});
      });

    img.image
        .resolve(new ImageConfiguration())
        .addListener(ilistener);
  }

  @override
  Widget build(BuildContext context) {
    if( ! done ){
      return Container();
    }


    if(vwidth < vheight){
      double cwidth = ( (vwidth as double) / vheight ) * pheight;

      _widthFactor = ( cwidth / pwidth ) / magratio;
      _heightFactor = 1.0 / magratio;
    }else{
      double cheight = ( (vheight as double) / vwidth ) * pwidth;

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

      return scallview();
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
            print("onLongPressMoveUpdate up");
          },
          child: ivew,
        );
  }

}
