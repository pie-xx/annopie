import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintf/sprintf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

import 'image_page.dart';
import 'folder_prop.dart';
import 'input_dialog.dart';

class FileListPage extends StatefulWidget {
  FileListPage({Key? key, this.targetdir, this.olddir}) : super(key: key);
  final String? targetdir;
  final String? olddir;

  @override
  FileListPageState createState() => FileListPageState();
}

class FileListPageState extends State<FileListPage> {
  String lastdir = "";
  String selectedfile = "";
  String filterword="";

  bool mkListDone = false;

  late ScrollController _scrollController;
  late FolderProp folderProp;
  late ViewStat viewstat;
  AnnotationProp annoProp = AnnotationProp("");

  late List<Widget> fis ;
  late List<Widget> dis ;

  @override
  void initState() {
    _scrollController = ScrollController();

    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if( Platform.isAndroid ){
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }

    lastdir = widget.targetdir??"";

    viewstat = ViewStat(lastdir);
    selectedfile = viewstat.getLastFilteTitle();
    annoProp = AnnotationProp(lastdir);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastdir', lastdir);
    setState(() {});

  }

  Future<void> makeFolderList( String fw ) async {
    folderProp = FolderProp(lastdir);

    ListTile parentEntry =
      ListTile(
            leading: const Icon(Icons.folder),
            title: Text(".."),
            subtitle: Text( folderProp.parentpath() ),
            onTap: (){ itemOnTap();},
            dense: false,
            );
    
    fis = [ parentEntry ];

    ListTile parentEntryD =
      ListTile(
            leading: const Icon(Icons.folder),
            title: Text(".."),
            subtitle: Text( folderProp.parentpath() ),
            onTap: () {
              Navigator.pop(this.context);
              itemOnTap();
            },
            dense: false,
            );

    dis = [ parentEntryD ];

    for( FileSystemEntity p in folderProp.plist ){
      if( p.path.indexOf(fw)!=-1 ){
        fis.add( mkfitem( p ) );
        if( annoProp.readAnnotation(p.path)!="" ){
          dis.add( mkditem( p ) );
        }
      }
    }
    mkListDone=true;
  }

  void itemOnTap(){
    if( folderProp.parentpath()==widget.olddir){
      Navigator.pop(this.context);
    }else{                
      Navigator.push(
        this.context, 
        MaterialPageRoute(
          builder: (context) => FileListPage( targetdir: folderProp.parentpath(), olddir: lastdir, )
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    makeFolderList( filterword );
  
    IconButton cdbtn =
              IconButton(
                icon: const Icon(Icons.folder),
                tooltip: 'change directory',
                onPressed: () async {
                  //var res = await inputDialog(context, 'Folder', lastdir);
                  var res = await FilePicker.platform.getDirectoryPath();
                  print(sprintf("response of InputDialog = %s",[res]));
                  if( res != null ){                                      
                    Navigator.push(
                      this.context, 
                      MaterialPageRoute(
                        builder: (context) => FileListPage( targetdir: res, olddir: lastdir, )
                      )
                    );
                  }
                },
              );

    if( lastdir=="" || mkListDone==false ){
      return Scaffold(appBar: AppBar(title: Text("Loading... ["+lastdir+"]"),actions:[cdbtn]),);
    }
    if(lastdir.endsWith("/")){
      lastdir = lastdir.substring(0,lastdir.length-1);
    }

    return Scaffold(
      appBar: AppBar(title: Text(ViewStat.getbasename(lastdir) ), 
                actions:[cdbtn,]),
      drawer: Drawer(child: ListView(children: dis,),),
      body:  
          ListView( children: fis, controller: _scrollController,),
 
      persistentFooterButtons:<Widget> [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () async {
                var res = await inputDialog(context, 'search', filterword );
                if( res != null ){
                  setState(() {
                    filterword = res;
                  });
                }
              },
              icon: Icon(Icons.search)),
            Text("search") 
          ]
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () async {
                var res = await inputDialog(context, 'page', "");
                if( res != null ){
                  if( res.endsWith('%')){
                    scrolltoPercent(res);
                  }else{
                    scroll2page(res);
                  }
                }
              },
              icon: Icon(Icons.pages_sharp)),
            Text("Page") 
          ]
        ),
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
  scroll2page(String res){
    double count = 0;
    if(res.endsWith('p')){
      count = double.parse(res.split("p")[0]) / 2;
    }else{
      count = double.parse(res);
    }
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent * count / folderProp.plist.length );
  }
  scrolltoPercent(String res){
    double percent = double.parse(res.split("%")[0])/100;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent * percent );
  }

  // Body用
  ListTile mkfitem( FileSystemEntity p ){
    String subtitlestr = sprintf("%8d", [p.statSync().size]);
    CType ct = check(p);
    final _focusNode = FocusNode(); 
    switch( ct ){ 
    case CType.Folder:
      subtitlestr = "";

      return ListTile(
        leading:  Icon(Icons.folder),
        title:    Text(p.path.substring(lastdir.length+1)),
        subtitle: Text(subtitlestr),
        selected: selectedfile==ViewStat.getbasename(p.path),
        onLongPress: (){ editAnnotation(p.path); },
        onTap: () async {
          Navigator.push(
            this.context, 
            MaterialPageRoute(
              builder: (context) => FileListPage( targetdir: p.path, olddir: lastdir,)
            )
          );
          setState(() {
            selectedfile = ViewStat.getbasename(p.path);
          });
        },
      );
    case CType.Image:
      return ListTile(
            leading:  Image.file(File(p.path), cacheWidth: 80, errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return const Text('😢');
              },),
            title: Text(p.path.substring(lastdir.length+1)),
            subtitle: Text( annoProp.readAnnotation(p.path) +" "+ subtitlestr ),
            selected: selectedfile==ViewStat.getbasename(p.path),
            onLongPress: (){ editAnnotation(p.path); },
            onTap: () async {
              FocusScope.of(context).requestFocus(_focusNode);
              await Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => ImagePage(path: p.path) 
                  )
                );
                
              setState(() {
                viewstat.reload();
                this.selectedfile = viewstat.getLastFilteTitle();
                annoProp.reload();
                scrollList(selectedfile);
              });
            },
            dense: false,
      ); 
    default:
      return ListTile(
            leading:  Icon(Icons.text_snippet_outlined),
            title: Text(p.path.substring(lastdir.length+1)),
            subtitle: Text( subtitlestr ),
            selected: selectedfile==ViewStat.getbasename(p.path),
            onLongPress: (){ editAnnotation(p.path); },
            onTap: () async {
              setState(() {
                selectedfile = ViewStat.getbasename(p.path);
              });
            },
            dense: false,
      );
    } 
  }

  // Drawer用 
  ListTile mkditem( p ){
    CType ct = check(p);
    return ListTile(
        //leading: leading,
        title: Text( annoProp.readAnnotation(p.path) ),
        //subtitle: Text( getbasename(p.path) ),
        onTap: () async {
          switch(ct){
          case CType.Folder:
            Navigator.push(
              this.context, 
              MaterialPageRoute(
                builder: (context) => FileListPage( targetdir: p.path, olddir: lastdir,)
              )
            );
            break;
          default:
            Navigator.pop(context);
            setState(() {
              viewstat.reload();
              annoProp.reload();
              selectedfile = ViewStat.getbasename(p.path);

              scrollList(selectedfile);
            });            
          }
        },
        dense: false,
      );
  }

  editAnnotation(String fname) async {
        var res = await inputDialog(context, 'Annotation', annoProp.readAnnotation(fname));
        if( res != null ){   
          setState(() {                                   
            annoProp.writeAnnotation(fname, res);
            annoProp.save();
          });
        }
  }

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
        if( p.path.toLowerCase().endsWith(".mp3") || p.path.toLowerCase().endsWith(".wav") || p.path.toLowerCase().endsWith(".amr") 
        || p.path.toLowerCase().endsWith(".m4a") || p.path.toLowerCase().endsWith(".ogg") ){
          return CType.Sound;
        }else
        if(p.path.toLowerCase().endsWith(".jpg")||p.path.toLowerCase().endsWith(".jpeg")|| p.path.toLowerCase().endsWith(".png") 
        || p.path.toLowerCase().endsWith(".gif")|| p.path.toLowerCase().endsWith(".bmp") ){
          return CType.Image;
        }else
        if( p.path.toLowerCase().endsWith(".json")|| p.path.toLowerCase().endsWith(".txt") || p.path.toLowerCase().endsWith(".xml") ){
          return CType.Text;
        }else
        if( p.path.toLowerCase().endsWith(".mp4")|| p.path.toLowerCase().endsWith(".mpg") ){
          return CType.Movie;
        }
        break;
    }
    
    return CType.Other;
  }
