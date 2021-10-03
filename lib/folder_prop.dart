import 'dart:io';
import 'dart:convert';

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
}

class ViewStat {
  String lastfile="";
  String lastdir="";
  final String statfile = "/.annofilers.json";

  ViewStat(String _lastdir){    
    File f = File(_lastdir);
    if( f.statSync().type != FileSystemEntityType.directory ){
      _lastdir = f.parent.path;
    }
    lastdir=_lastdir;
    reload();
  }

  reload(){
    try{
      File f = File(lastdir+statfile);
      String fileprop = f.readAsStringSync();
      Map<String, dynamic> response = jsonDecode(fileprop);
      lastfile = response['lastfile'];

    }catch(e){
      print(e);
    }
  }

  setLastFile(String fpath){
    lastfile = getbasename(fpath);
  }

  static String getbasename(String path){
    int li = path.lastIndexOf("/");
    return path.substring(li+1);
  }

  save() async {
    Map<String, dynamic> answer = {};
    answer['lastfile'] = lastfile;
    final json = jsonEncode(answer);
    String jsonstr = json.toString();

    await File(lastdir+statfile).writeAsString(jsonstr);
  }
}
///////////////////////////////////////
class AnnotationProp {
  String lastdir="";
  Map<String, Annotate> annos = {};
  late List plist;

  AnnotationProp(String _lastdir){
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