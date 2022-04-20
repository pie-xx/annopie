import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/src/services/hardware_keyboard.dart';
import 'package:flutter/src/services/keyboard_key.dart';

import 'folder_prop.dart';
import 'input_dialog.dart';
import 'editarea_page.dart';

class ImagePage extends StatefulWidget {
  ImagePage({Key? key, this.path}) : super(key: key);
  final String? path;
  @override
  ImagePageState createState() => ImagePageState();
}

class ImagePageState extends State<ImagePage> {
  late Uint8List imgbin;

    Image img= Image.asset("assets/img/default.jpg"); 

  int nextpagecount=0;
  int beforepagecount = 0;
  String curfile = "";

  bool _visible = true;

  final _transformationController = TransformationController();
  Matrix4 scalevalue = Matrix4.identity();
  List<Matrix4> areas = [];
  int aindex = 0;

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
    areas = FolderInfo.get_last_area();
    aindex=0;

    if(areas.length!=0){
      _transformationController.value = areas[0];
      aindex=0;
    }else{
      _transformationController.value = Matrix4.identity();
    }

    loadImage(curfile);

    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    KeyHandler.set_handler({
        PhysicalKeyboardKey.audioVolumeUp.usbHidUsage:before_area, 
        PhysicalKeyboardKey.arrowUp.usbHidUsage:before_area, 
        PhysicalKeyboardKey.audioVolumeDown.usbHidUsage:next_area,
        PhysicalKeyboardKey.arrowDown.usbHidUsage:next_area,
        });

    showBar();
    await loadImage(curfile);
    setState(() {
    });
  }

  @override
  void dispose() {
    print('ImagePageState dispose');

    KeyHandler.reset_handler();
    super.dispose();
  }

  List<Widget> mkDrawer(){
    List<Widget> dis=[ 
      DrawerHeader(
      child: Text(FolderInfo.dirName()),
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
    ),];

    for( FileSystemEntity p in FolderInfo.get_file_list() ){
      if( FolderInfo.read_annotation(p.path)!="" ){
          dis.add( mkditem( p, FolderInfo.read_annotation(p.path) ) );
      }
    }
    return dis;
  }

    // Drawer用 
  ListTile mkditem( FileSystemEntity p, String title ){

    return ListTile(
        title: Text( title ),
        onTap: () async {
          Navigator.pop(context);
          await loadImage(p.path);
          setState(() {
          });
        },
        dense: false,
      );
  }

  Future<void>  loadImage(String path) async {
    imgbin = File(path).readAsBytesSync();
    img = Image.memory(imgbin);

    curfile = path;
  }

  @override
  Widget build(BuildContext context) {
    var toolbar = Visibility(
      visible: _visible,
      child: ImgPageBottomBar.build(context, this),
    );

    IconButton cdbtn =
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white,),
            tooltip: 'back',
            onPressed: () async {
              Navigator.pop(context);
            },
          );

    String appbartitle = "${FolderInfo.index(curfile)}/${FolderInfo.length()}: ${FolderInfo.dirName()}";
    if( areas.length > 0 ){
      appbartitle = "${FolderInfo.index(curfile)}/${FolderInfo.length()}(${aindex+1}/${areas.length}): ${FolderInfo.dirName()}";
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
          child: AppBar(title: appbarText, 
            leading:cdbtn, )
        ),       
        endDrawer: Drawer(child: ListView(children: dis,),),         
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
      bool find = false;
      for( var p in FolderInfo.get_file_list() ){
        if( find ){
          await loadImage(p.path);

          setState(() {
            FolderInfo.set_last_path(p.path);
            print("nextpage ${p.path}");
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

      String beforefile = FolderInfo.get_file_list()[0].path;
      for( var p in FolderInfo.get_file_list() ){
        if( p.path == curfile ){
          await loadImage(beforefile);

          setState(() async {
            await FolderInfo.set_last_path(beforefile);
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
      FolderInfo.set_last_area(areas);
    });
  }

  void clearScale(){
    setState(() {
      areas.clear();
      aindex = 0;
      FolderInfo.set_last_area(areas);
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
      });
    }
  }

  Future<void> input_page( int pno ) async {
    String gopath = FolderInfo.get_file_list()[pno].path;
    await loadImage(gopath);
    setState(() {
      FolderInfo.set_last_path(gopath);
    });
  }
}


class ImgPageBottomBar {
  static final List<BottomNavigationBarItem> items = [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_to_queue),
            label: "add",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.clear_all),
            label: "clear",
          ),
          BottomNavigationBarItem(
            icon: Icon(null),
            label: "",
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.grey.shade400,
            icon: Icon(Icons.settings),
            label: "settings",
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
  ];

  static BottomNavigationBar build( BuildContext context, ImagePageState callback ){

    return 
      BottomNavigationBar( 
        items: items,
        onTap:(index) async {  
          String label = items[index].label.toString();
          switch(label) {
            case "add": callback.addScale(); break; 
            case "clear": callback.clearScale(); break; 
            case "settings":
               await Navigator.push(
                  callback.context,
                  MaterialPageRoute(
                    builder: (context) => EditAreaPage(path: callback.curfile) 
                  )
                );
              break;
            case "page": 
              var res = await inputDialog(context, 'page', "" );
              if( res != null ){
                await callback.input_page(int.parse(res)); 
              }
              break;
            case "before": await callback.before_area(); break;
            case "next": await callback.next_area(); break;
          }
        },
        type: BottomNavigationBarType.fixed,
      );
  } 
}