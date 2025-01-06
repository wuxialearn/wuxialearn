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
    return Theme(
      data: ThemeData(
          fontFamily: '.SF UI Text',
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          )),
      child: const CupertinoApp(
        theme: CupertinoThemeData(
            primaryColor: Colors.blue,
            brightness: Brightness.light,
            textTheme: CupertinoTextThemeData(
              textStyle: TextStyle(fontFamily: 'Roboto', color: Colors.black),
              actionTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: Colors.black),
              navActionTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: Colors.blue),
              navLargeTitleTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: Colors.black),
              navTitleTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: Colors.black),
              pickerTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: Colors.black),
              dateTimePickerTextStyle:
                  TextStyle(fontFamily: 'Roboto', color: Colors.black),
            )),
        scrollBehavior: CupertinoScrollBehavior(),
        title: 'Wuxia Learn',
        home: LoadApp(),
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
      title: 'Wuxia Learn',
      home: const LoadApp(
        fdroid: false,
      ),
      //home: const MyStatefulWidget(),
    );
  }
}
