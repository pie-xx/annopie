import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'folder_prop.dart';
import 'input_dialog.dart';

class EditAreaPage extends StatefulWidget {
  EditAreaPage({Key? key, this.path}) : super(key: key);
  final String? path;
  @override
  EditAreaPageState createState() => EditAreaPageState();
}

class EditAreaPageState extends State<EditAreaPage> {
  late Uint8List imgbin;

  late Image img; 

  int nextpagecount=0;
  int beforepagecount = 0;
  String curfile = "";

  //late ViewStat viewstat;

  bool _visible = true;

  final _transformationController = TransformationController();
  Matrix4 scalevalue = Matrix4.identity();

  late AppBar appbar;

  late DynamicLibrary  dylib ;

  int aindex = -1;
  List<Matrix4> areas = [];

  final textController = TextEditingController();
  late AnnotationProp annotationProp;
  @override
  void initState() {
    
    curfile = widget.path??"";

    annotationProp = AnnotationProp(curfile);
    textController.text = annotationProp.readAnnotation(curfile);

    img = Image.asset("assets/img/default.jpg"); 
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    loadImage(curfile);
    showBar();
  }

  void loadImage(String path) async {
    imgbin = File(path).readAsBytesSync();
    img = Image.memory(imgbin);

    curfile = path;
  }

  @override
  Widget build(BuildContext context) {
    var toolbar = Visibility(
      visible: _visible,
      child: EditAreaPageBottomBar.build(context, this),
    );
    String appbartitle = "${FolderInfo.index(curfile)}/${FolderInfo.length()}: ${FolderInfo.dirName()}";
    Text appbarText = Text(appbartitle, overflow: TextOverflow.fade,);

    double scwidth = MediaQuery.of(context).size.width;
    double scheight = scwidth;

    File f= File(curfile);

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(32.0),
          child: AppBar(title: appbarText, backgroundColor: Colors.orange,)
        ),
        body: 
        SingleChildScrollView(child: 
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text( "${ViewStat.getbasename(curfile)} ${f.lengthSync()}" ),
                TextButton(
                  onPressed: (){
                    FolderInfo.write_annotation(curfile, textController.text);
                    Navigator.pop(context);
                  }, 
                  child: Text("set"),
                  style: TextButton.styleFrom( backgroundColor: Colors.orange, ),),
              ],),
            InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(0.0),
                minScale: 0.1,
                maxScale: 64,
                child: Container(
                  color: Colors.grey,
                  child: 
                  SizedBox(
                      width: scwidth,
                      height: scheight,
                      child: img,
                    ),
                  ),
                ),
            TextField(
              controller: textController,
              decoration: InputDecoration(hintText: "Annotation"),
              maxLines: 5,
            ),
          ],
        ),
        ),
        //bottomNavigationBar:
        //  toolbar
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

  resetScale(){
    _transformationController.value = Matrix4.identity();
  }

  before_area(){
    setState(() {
      --aindex;
      if( aindex < 0 ){
        aindex = areas.length - 1;
      }
      if( areas.length > 0 ){
        _transformationController.value = areas[aindex];
      }
    });
  }
  next_area(){
    setState(() {
      ++aindex;
      if( aindex >= areas.length ){
        aindex = 0;
      }
      if( areas.length > 0 ){
        _transformationController.value = areas[aindex];
      }
    });
  }

  add_area(){
    setState(() {
      areas.add(_transformationController.value);
    });
  }
}

class EditAreaPageBottomBar {

  static BottomNavigationBar build( BuildContext context, EditAreaPageState callback ){

    return 
      BottomNavigationBar( 
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.navigate_before),
            label: "before",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigate_next),
            label: "next",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location),
            label: "add",
          ),
        ],
        onTap:(index) async {  
          switch(index) {
            case 0: callback.before_area(); break; 
            case 1: callback.next_area(); break;
            case 2: callback.add_area(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
      );
  } 
}