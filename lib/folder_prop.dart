import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderProp {
  late String lastdir;
  late List plist;
  late Directory pDir;

  FolderProp(String _lastdir){
    File f = File(_lastdir);
    if( f.statSync().type != FileSystemEntityType.directory ){
      _lastdir = f.parent.path;
    }
    lastdir=_lastdir;
    pDir = Directory(lastdir);
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

  String parentpath(){
    return pDir.parent.path;
  }

  String dirName(){
    List flist = pDir.path.split("/");
    return flist.last;
  }
}

class ViewStat {
  String _lastpath="";
  String _lastfile="";
  String _lastdir="";
  String _lastcont="";
  List<Matrix4> _lastarea = [];

  final String statfile = "/.annofilers.json";
  final String KEYfile = "lastfile";
  final String KEYcont = "lastcont";
  final String KEYarea = "lastarea";

  ViewStat(String _ldir){    
    File f = File(_ldir);
    if( f.statSync().type != FileSystemEntityType.directory ){
      _ldir = f.parent.path;
    }
    _lastdir=_ldir;

    reload();
  }

  static String getbasename(String path){
    int bl = path.lastIndexOf("\\");
    int li = path.lastIndexOf("/");
    int sp = 0;
    if( bl > li ){
      sp = bl + 1;      
    }else{
      sp = li + 1;
    }
    return path.substring(sp);
  }

  void setLastPath(String fpath) async {
    _lastpath = fpath;
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(KEYfile, _lastpath );
  }
  String getLastFilteTitle(){
    return getbasename(_lastpath);
  }
  String getLastFileFullpath() {
    return _lastpath;
  }

  void setLastCont(String _lcont) async {
    _lastcont = _lcont;
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(KEYcont, _lastcont );
  }
  String getLastCont(){
    return _lastcont;
  }

  void setLastArea( List<Matrix4> areas ){
    _lastarea = areas;
  }
  List<Matrix4> getLastArea(){
    //String areas = _lastarea.toString();
    return _lastarea;
  }
  void loadarea(String areastring){
    _lastarea.clear();
    List lines = areastring.split("\n");
    if( lines.length < 4 )
      return;
    for(int lx=0; lx < lines.length; lx=lx+4){
      List ls = [];
      for(int n=0; n<4; ++n){
        List<double> a = [];
        List plines = lines[n+lx].toString().split("]");
        if( plines.length < 2 )
          return;
        List lv = plines[1].split(",");
        if( lv.length < 4 )
          return;
        for(int m=0; m<4; ++m){
          a.add( double.parse( lv[m]) );
        }
        ls.add(a);
      }
      List<double> as = [];
      for( int x=0; x < 4; ++x) {
        for( int y=0; y<4; ++y ){
          as.add(ls[y][x]);
        }
      }
      Matrix4 area = Matrix4.fromList(as);
      _lastarea.add(area);
    }
  }

  reload() async {
    try{
      File f = File(_lastdir+statfile);
      String fileprop = f.readAsStringSync();
      print(fileprop);
      Map<String, dynamic> response = jsonDecode(fileprop);
      _lastfile = response[KEYfile];
      _lastpath = _lastdir + "/" + _lastfile;
      _lastcont = response[KEYcont];
      loadarea(response[KEYarea]);
    }catch(e){
      print(e);
      SharedPreferences pref = await SharedPreferences.getInstance();
      _lastpath = await pref.getString(KEYfile) ?? "";
      _lastfile = getbasename(_lastpath);
      _lastcont = await pref.getString(KEYcont) ?? "";
      loadarea(await pref.getString(KEYarea) ?? "");
    }
  }

  save() async {
    Map<String, dynamic> answer = {};
    answer[KEYfile] = getLastFilteTitle();
    answer[KEYcont] = _lastcont;
    answer[KEYarea] = _lastarea.toString();
    final json = jsonEncode(answer);
    String jsonstr = json.toString();

    try{
      await File(_lastdir+statfile).writeAsString(jsonstr);
    }catch(e){
      print(e);
    }
  }
}
///////////////////////////////////////
class AnnotationProp {
  String lastdir="";
  Map<String, Annotate> annos = {};
  late List plist;

  AnnotationProp(String _lastdir){
    File f = File(_lastdir);
    if( f.statSync().type != FileSystemEntityType.directory ){
      _lastdir = f.parent.path;
    }
    lastdir=_lastdir;
    plist=[];
    reload();
  }

  reload(){
    try{
      plist = Directory(lastdir).listSync();
      plist.sort((a,b) => a.path.compareTo(b.path));

      File f = File(lastdir+"/.annofilerx.json");
      String fileprop = f.readAsStringSync();
      Map<String, dynamic> response = jsonDecode(fileprop);
      var an = response['annos'];
      for( var item in an.keys){
        var r = an[item];
        Annotate a = Annotate();
        a.text = r['text'];
        print("reload "+item+" "+a.text);
        annos[item] = a;
      }

    }catch(e){
      print(e);
    }
  }

  save() async {
    Map<String, dynamic> answer = {};
    String ans="";
    for( var fname in annos.keys){
      Annotate anno = annos[fname] ?? Annotate();
      if( ans!=""){
        ans = ans + ",";
      }
      ans = ans + '"'+fname+'":{"text":"'+anno.text+'"}';
    }
    var anno = jsonDecode('{'+ans.replaceAll("\n", "\\n")+"}");
    answer['annos']= anno;
    final json = jsonEncode(answer);
    String jsonstr = json.toString();
    await File(lastdir+"/.annofilerx.json").writeAsString(jsonstr);
  }

  String readAnnotation(String fname){
    Annotate anno = annos[ViewStat.getbasename(fname)] ?? Annotate();
    return anno.text;
  }

  writeAnnotation(String fname, String annotation){
    fname = ViewStat.getbasename(fname);
    annos.remove( fname );
    if( annotation!="" ){
      Annotate anno = Annotate();
      anno.text = annotation.replaceAll("\n", "\\n");
      annos[fname] = anno;
    }
  }

  int index(String path){
    for( int n = 0; n < plist.length; ++n ){
      if( plist[n].path.toString().endsWith(ViewStat.getbasename(path)) ){
        return n;
      }
    }
    return -1;
  }

  int total(){
    return plist.length;
  }
}

class Annotate {
  String text="";
  //List<Areadef> areas=[];

  String toString(){
    Map<String, String> answer = {};
    answer['text'] = text;
    //answer['areas']="[]";
    final json = jsonEncode(answer);
    return json;
  }
}
//class Areadef {}