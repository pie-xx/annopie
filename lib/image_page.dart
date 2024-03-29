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

  List<Widget> mkDrawer(){

    List<Widget> dis=[];
    AnnotationProp annoProp = AnnotationProp(curfile);
    for( FileSystemEntity p in folderprop.plist ){
      if( annoProp.readAnnotation(p.path)!="" ){
          dis.add( mkditem( p, annoProp.readAnnotation(p.path) ) );
      }
    }
    return dis;
  }

    // Drawer用 
  ListTile mkditem( FileSystemEntity p, String title ){

    return ListTile(
        //leading: leading,
        title: Text( title ),
        //subtitle: Text( getbasename(p.path) ),
        onTap: () async {

          Navigator.pop(context);
          
          await loadImage(p.path);

          setState(() {
            viewstat.set_last_ainx(aindex);
            viewstat.setLastPath(p.path);
            viewstat.save();
          });
        },
        dense: false,
      );
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

    IconButton cdbtn =
          IconButton(
            icon: const Icon(Icons.edit_location, color: Colors.white,),
            tooltip: 'edit area',
            onPressed: () async {
              /*
              await Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => EditAreaPage(path: curfile) 
                  )
                );
              */
            },
          );

    String appbartitle = "${folderprop.index(curfile)}/${folderprop.length()}: ${folderprop.dirName()}";
    if( areas.length > 0 ){
      appbartitle = "${folderprop.index(curfile)}/${folderprop.length()}(${aindex+1}/${areas.length}): ${folderprop.dirName()}";
    }
    Text appbarText = Text(appbartitle, overflow: TextOverflow.fade,);

    var iviewer = InteractiveViewer(
            transformationController: _transformationController,
            onInteractionEnd: (details){
              //print("onInteractionEnd");
              //print(_transformationController.value);
            },
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.1,
            maxScale: 64,
            child: Center( child: img, ),
          );
    
    List<Widget> dis = mkDrawer();

      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(32.0),
          child: AppBar(title: appbarText, actions:[cdbtn,], )
        ),       
        drawer: Drawer(child: ListView(children: dis,),),         
        body: 
          iviewer,
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

  Future<void> nextpage() async {
    try {
      var folderprop = FolderProp(curfile);
      bool find = false;
      for( var p in folderprop.plist ){
        if( find ){
          await loadImage(p.path);

          setState(() {
            viewstat.set_last_ainx(aindex);
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

  Future<void> beforepage() async {
    try {

      String beforefile = folderprop.plist[0].path;
      for( var p in folderprop.plist ){
        if( p.path == curfile ){
          await loadImage(beforefile);

          setState(() {
            viewstat.set_last_ainx(aindex);
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

  void resetScale(){
    _transformationController.value = Matrix4.identity();
  }

  void saveScale(){
    scalevalue = _transformationController.value;
  }
  void loadScale(){
    _transformationController.value = scalevalue;
  }

  void addScale(){
    setState(() {
      areas.add(_transformationController.value);
      aindex = areas.length - 1;
      viewstat.setLastArea(areas);
      viewstat.save();
    });
  }

  void clearScale(){
    setState(() {
      areas.clear();
      aindex = 0;
      viewstat.setLastArea(areas);
      viewstat.save();
    });
  }

  Future<void> before_area() async {
    --aindex;
    if( aindex < 0 ){
      aindex = areas.length - 1;
      await beforepage();
    }
    if( areas.length > 0 ){
      setState(() {
        _transformationController.value = areas[aindex];
        viewstat.set_last_ainx(aindex);
        viewstat.save();
      });
    }
  }
  Future<void> next_area() async {
    ++aindex;
    if( aindex >= areas.length ){
      aindex = 0;
      await nextpage();
    }
    if( areas.length > 0 ){
      setState(() {
        _transformationController.value = areas[aindex];
        viewstat.set_last_ainx(aindex);
        viewstat.save();
      });
    }
  }

  Future<void> input_page( int pno ) async {
    String gopath = folderprop.plist[pno].path;
    await loadImage(gopath);
    setState(() {
      viewstat.set_last_ainx(0);
      viewstat.setLastPath(gopath);
      viewstat.save();
    });
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
            backgroundColor: Colors.grey.shade400,
            icon: Icon(Icons.pages),
            label: "page",
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
                  await Future.delayed(Duration(seconds: 1));
                  callback.setState(() {
                  });
              }
              break;
            case 5: 
              var res = await inputDialog(context, 'page', "" );
              if( res != null ){
                await callback.input_page(int.parse(res)); 
              }
              break;
            case 6: await callback.before_area(); break;
            case 7: await callback.next_area(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
      );
  } 
}