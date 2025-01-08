import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hsk_learner/utils/platform_info.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hsk_learner/screens/home/load_app.dart';

void main() {
  if (PlatformInfo.isDesktop()) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
	
	final brightness = MediaQuery.platformBrightnessOf(context);

    return Theme(
      data: ThemeData(
		  brightness: brightness,
          fontFamily: '.SF UI Text',
          colorScheme: ColorScheme.fromSwatch(
            brightness: brightness,
			primarySwatch: Colors.blue,
          )),
      child: CupertinoApp(
        theme: CupertinoThemeData(
			brightness: brightness,
            primaryColor: Colors.blue,
            textTheme: CupertinoTextThemeData(
              textStyle: TextStyle(fontFamily: 'Roboto', color: brightness == Brightness.dark ? Colors.white : Colors.black),
              actionTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: brightness == Brightness.dark ? Colors.white : Colors.black),
              navActionTextStyle:
                  const TextStyle(fontFamily: 'Roboto', color: Colors.blue),
              navLargeTitleTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: brightness == Brightness.dark ? Colors.white : Colors.black),
              navTitleTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: brightness == Brightness.dark ? Colors.white : Colors.black),
              pickerTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: brightness == Brightness.dark ? Colors.white : Colors.black),
              dateTimePickerTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: brightness == Brightness.dark ? Colors.white : Colors.black),
            )),
        scrollBehavior: CupertinoScrollBehavior(),
        title: 'Wuxia Learn',
        home: const LoadApp(fdroid: true),
        //home: const MyStatefulWidget(),
      ),
    );
  }
}

class MyApp2 extends StatelessWidget {
  const MyApp2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const CupertinoScrollBehavior(),
      theme: ThemeData.light(useMaterial3: false),
	    darkTheme: ThemeData.dark(useMaterial3: false),
	    themeMode: ThemeMode.system,
      ///title: 'Wuxia Learn',
      title: 'Wuxia Learn',
      home: const LoadApp(fdroid: true),
      //home: const MyStatefulWidget(),
    );
  }
}