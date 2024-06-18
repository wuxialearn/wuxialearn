import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

///calling Platform on web causes an exception so
///we must test for web first and return before calling
///platform
class PlatformInfo{
  PlatformInfo._();
  static bool isWeb(){
    return kIsWeb;
  }
  static bool isDesktop(){
    if(kIsWeb){
      return false;
    }
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }
  static bool isMobile(){
    if(kIsWeb){
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }
  static bool isWindows(){
    if(kIsWeb){
      return false;
    }
    return Platform.isWindows;
  }
  static bool isLinux(){
    if(kIsWeb){
      return false;
    }
    return Platform.isLinux;
  }
  static bool isMacOs(){
    if(kIsWeb){
      return false;
    }
    return Platform.isMacOS;
  }
  static bool isIOs(){
    if(kIsWeb){
      return false;
    }
    return Platform.isIOS;
  }
  static bool isAndroid(){
    if(kIsWeb){
      return false;
    }
    return Platform.isAndroid;
  }
}