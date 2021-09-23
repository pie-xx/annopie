import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintf/sprintf.dart';

import 'image_page.dart';

class FileListPage extends StatefulWidget {
  FileListPage({Key? key, required String this.targetdir, required String this.olddir}) : super(key: key);
  final String targetdir;
  final String olddir;

  @override
  FileListPageState createState() => FileListPageState();
}

class FileListPageState extends State<FileListPage> {
  String lastdir = "";
  late String _target;
  String selectedfile = "";

  bool mklist_done = false;

  late ScrollController _scrollController;
  late FolderProp folderProp;

  late List<Widget> fis ;

  @override
  void initState() {
    _scrollController = ScrollController();

    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if( widget.targetdir != ""){
      lastdir = widget.targetdir;
    }else{
      lastdir = await getDefaultDir();
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastdir', lastdir);
    setState(() {});
  }

  Future<void> makeFolderList() async {
    folderProp = FolderProp(lastdir);
    Directory pDir = Directory(lastdir);

    ListTile parentEntry =
      ListTile(
            leading: const Icon(Icons.folder),
            title: Text(".."),
            subtitle: Text( pDir.parent.path ),
            onTap: () => {
              if( pDir.parent.path==widget.olddir){
                Navigator.pop(this.context)
              }else{                
                Navigator.push(
                  this.context, 
                  MaterialPageRoute(
                    builder: (context) => FileListPage( targetdir: pDir.parent.path, olddir: lastdir, )
                  )
                )
              }
            },
            dense: false,
            );

    fis = [
      parentEntry
    ];

    for( FileSystemEntity p in folderProp.plist ){
      fis.add(mkfitem( p ));
    }

    mklist_done=true;
  }

  @override
  Widget build(BuildContext context) {
    makeFolderList();
    IconButton cdbtn =
              IconButton(
                icon: const Icon(Icons.folder),
                tooltip: 'change directory',
                onPressed: () async {
                  var res = await InputDialog(context, lastdir);
                  print(sprintf("response of InputDialog = %s",[res]));
                  if( res != "" ){                                      
                    Navigator.push(
                      this.context, 
                      MaterialPageRoute(
                        builder: (context) => FileListPage( targetdir: res, olddir: lastdir, )
                      )
                    );
                  }
                },
              );

    if( lastdir=="" || mklist_done==false ){
      return Scaffold(appBar: AppBar(title: Text("Loading..."),actions:[cdbtn]),);
    }
    if(lastdir.endsWith("/")){
      lastdir = lastdir.substring(0,lastdir.length-1);
    }

    return Scaffold(
      appBar: AppBar(title: Text(getbasename(lastdir) ), 
                actions:[cdbtn,]),
      body:  
          ListView( children: fis, controller: _scrollController,),
 
      persistentFooterButtons:<Widget> [

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: (){
                _scrollController.jumpTo(0);
              },
              icon: Icon(Icons.keyboard_arrow_up)),
            Text("Top") 
          ]
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: (){
                scrollList(selectedfile);
              },
              icon: Icon(Icons.keyboard_arrow_right)),
            Text("LastView") 
          ]
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: (){
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              },
              icon: Icon(Icons.keyboard_arrow_down)),
            Text("Bottom") 
          ]
        ),
      ],

    );
  }

  scrollList(String fname){
    int cindex = folderProp.index(fname);
    if( cindex != -1 ){
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent * cindex / folderProp.plist.length );
    }
  }

  // Body用
  ListTile mkfitem( FileSystemEntity p ){
    String subtitlestr = sprintf("%8d", [p.statSync().size]);
    CType ct = check(p);

    switch( ct ){ 
    case CType.Folder:
      try {
        subtitlestr = sprintf("%8d files", [Directory(p.path).listSync().length]); 
      }catch(e){
        subtitlestr = subtitlestr + "  ???";
      }
      return ListTile(
        leading:  Icon(Icons.folder),
        title:    Text(p.path.substring(lastdir.length+1)),
        subtitle: Text(subtitlestr),
        selected: selectedfile==getbasename(p.path),
        onTap: () async {
          Navigator.push(
            this.context, 
            MaterialPageRoute(
              builder: (context) => FileListPage( targetdir: p.path, olddir: lastdir,)
            )
          );
          setState(() {
            selectedfile = getbasename(p.path);
          });
        },
      );
    case CType.Image:
      return ListTile(
            leading:  Image.file(File(p.path), cacheWidth: 80, errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return const Text('😢');
              },),
            title: Text(p.path.substring(lastdir.length+1)),
            subtitle: Text( subtitlestr ),
            selected: selectedfile==getbasename(p.path),
            onTap: () async {
              await Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => ImagePage(path: p.path) 
                  )
                );
              setState(() {
                selectedfile = getbasename(p.path);
              });
            },
            dense: false,
      ); 
    default:
      return ListTile(
            leading:  Icon(Icons.text_snippet_outlined),
            title: Text(p.path.substring(lastdir.length+1)),
            subtitle: Text( subtitlestr ),
            selected: selectedfile==getbasename(p.path),
            onTap: () async {
              setState(() {
                selectedfile = getbasename(p.path);
              });
            },
            dense: false,
      );
    } 
  }

  Future<String> getDefaultDir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastdir = prefs.getString("lastdir") ?? "";
    try{
    if( lastdir==""){
      Directory _tdir = await getApplicationDocumentsDirectory();
      lastdir = _tdir.path;
    }
    }catch(e){
      print(e.toString());
    }
    return lastdir;
  }

  Future<String> InputDialog(BuildContext context, String lastdir) async {
    final textController = TextEditingController();
    textController.text = lastdir;

    String? res = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Folder'),
            content: TextField(
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
    return res??"";
  }

}


  String getbasename(String path){
    int li = path.lastIndexOf("/");
    return path.substring(li+1);
  }

  enum CType {
    Folder,
    Text,
    Image,
    Sound,
    Movie,
    Other
  }

   CType check( FileSystemEntity p ){
    switch( p.statSync().type ){
      case FileSystemEntityType.directory:
        return CType.Folder;
      case FileSystemEntityType.file:
        if( p.path.endsWith(".mp3") || p.path.endsWith(".wav") || p.path.endsWith(".amr") || p.path.endsWith(".m4a") || p.path.endsWith(".ogg") ){
          return CType.Sound;
        }else
        if(p.path.endsWith(".jpg")|| p.path.endsWith(".JPG")|| p.path.endsWith(".png") || p.path.endsWith(".gif")|| p.path.endsWith(".bmp") ){
          return CType.Image;
        }else
        if( p.path.endsWith(".json")|| p.path.endsWith(".txt") || p.path.endsWith(".xml") ){
          return CType.Text;
        }else
        if( p.path.endsWith(".mp4")|| p.path.endsWith(".mpg") ){
          return CType.Movie;
        }
        break;
    }
    
    return CType.Other;
  }

class FolderProp {
  late String lastdir;
  late List plist;

  FolderProp(String _lastdir){
    lastdir=_lastdir;
    plist=[];
    reload();
  }
  
  reload(){
    try{
      plist = Directory(lastdir).listSync();
      plist.sort((a,b) => a.path.compareTo(b.path));
    }catch(e){
      print(e);
    }
  }

  int index(String path){
    for( int n = 0; n < plist.length; ++n ){
      if( plist[n].path.toString().endsWith(path) ){
        return n;
      }
    }
    return -1;
  }
}