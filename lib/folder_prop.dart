import 'dart:io';

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