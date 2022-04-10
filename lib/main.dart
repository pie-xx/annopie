import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'flist_page.dart';
import 'folder_prop.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String lastdir = await getDefaultDir();
  FolderInfo.init(lastdir);

  runApp(MyApp(path: lastdir));
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
    lastdir = ".";
  }
  return lastdir;
}

class MyApp extends StatelessWidget {
  String? path; 
  MyApp({Key? key, this.path}) : super(key: key);
  // This widget is the root of your application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    //  title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FileListPage(targetdir:path, olddir: "",),
    );
  }
}