import 'package:flutter/material.dart';

class Styles {
  static ButtonStyle blankButton = ButtonStyle(
    overlayColor: MaterialStateProperty.all(Colors.transparent),
    backgroundColor:
    MaterialStateProperty.all<Color>( Colors.white),
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0),)
    ),
  );
  static ButtonStyle blankButtonNoPadding = ButtonStyle(
    foregroundColor: MaterialStateProperty.all(Colors.blue),
    overlayColor: MaterialStateProperty.all(Colors.transparent),
    padding: const MaterialStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize : const MaterialStatePropertyAll<Size>(Size.zero)
  );
  static ButtonStyle blankButton2 = ButtonStyle(
    minimumSize: MaterialStateProperty.all<Size>(
        const Size.fromHeight(40)),
    overlayColor: MaterialStateProperty.all(Colors.transparent),
    foregroundColor:
    MaterialStateProperty.all<Color>(const Color(0xFF757575)),
    backgroundColor:
    MaterialStateProperty.all<Color>(const Color(0xFFEEEEEE)),
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0),)
    ),
  );
  static ButtonStyle blankButton3 = ButtonStyle(
    overlayColor: MaterialStateProperty.all(Colors.transparent),
    backgroundColor:
    MaterialStateProperty.all<Color>(const Color(0x00FFFFFF)),
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0),)
    ),
  );
  static ButtonStyle blankButton4 = ButtonStyle(
    minimumSize: MaterialStateProperty.all<Size>(
        const Size.fromHeight(40)),
    overlayColor: MaterialStateProperty.all(Colors.transparent),
    foregroundColor:
    MaterialStateProperty.all(Colors.blue),
    backgroundColor:
    MaterialStateProperty.all<Color>(const Color(0xFFEEEEEE)),
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0),)
    ),
  );
  static createButton(color) {
    return ButtonStyle(
      minimumSize: MaterialStateProperty.all<Size>(const Size.fromHeight(40)),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      foregroundColor:
      MaterialStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor:
      MaterialStateProperty.all<Color>(color),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0),)
      ),
    );
  }
  static createButtonOnlyBottomBorderRadius(color) {
    return ButtonStyle(
      minimumSize: MaterialStateProperty.all<Size>(const Size.fromHeight(40)),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      foregroundColor:
      MaterialStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor:
      MaterialStateProperty.all<Color>(color),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),)
      ),
    );
  }
  static createButtonNoBorderRadius(color) {
    return ButtonStyle(
      minimumSize: MaterialStateProperty.all<Size>(const Size.fromHeight(40)),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      foregroundColor:
      MaterialStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor:
      MaterialStateProperty.all<Color>(color),
    );
  }
  static createButton2(color, {Color border = Colors.transparent}) {
    return ButtonStyle(
      elevation: MaterialStateProperty.all<double>(1.5),
      minimumSize: MaterialStateProperty.all<Size>(const Size( 160, 75),),
      maximumSize: MaterialStateProperty.all<Size>(const Size( 160, 75),),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      foregroundColor:
      MaterialStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor:
      MaterialStateProperty.all<Color>(color),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: border, width: 1),
          )
      ),
    );
  }
}


