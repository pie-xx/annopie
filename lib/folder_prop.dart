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
