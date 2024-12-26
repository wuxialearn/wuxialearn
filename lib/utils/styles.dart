import 'package:flutter/material.dart';

class Styles {
  static ButtonStyle blankButton = ButtonStyle(
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    )),
  );
  static ButtonStyle blankButtonNoPadding = ButtonStyle(
      foregroundColor: WidgetStateProperty.all(Colors.blue),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const WidgetStatePropertyAll<Size>(Size.zero));
  static ButtonStyle blankButton2 = ButtonStyle(
    minimumSize: WidgetStateProperty.all<Size>(const Size.fromHeight(40)),
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    foregroundColor: WidgetStateProperty.all<Color>(const Color(0xFF757575)),
    backgroundColor: WidgetStateProperty.all<Color>(const Color(0xFFEEEEEE)),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    )),
  );
  static ButtonStyle blankButton3 = ButtonStyle(
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    backgroundColor: WidgetStateProperty.all<Color>(const Color(0x00FFFFFF)),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    )),
  );
  static ButtonStyle blankButton4 = ButtonStyle(
    minimumSize: WidgetStateProperty.all<Size>(const Size.fromHeight(40)),
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    foregroundColor: WidgetStateProperty.all(Colors.blue),
    backgroundColor: WidgetStateProperty.all<Color>(const Color(0xFFEEEEEE)),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    )),
  );
  static createButton(color) {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all<Size>(const Size.fromHeight(40)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor:
          WidgetStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor: WidgetStateProperty.all<Color>(color),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      )),
    );
  }

  static createButtonOnlyBottomBorderRadius(color) {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all<Size>(const Size.fromHeight(40)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor:
          WidgetStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor: WidgetStateProperty.all<Color>(color),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      )),
    );
  }

  static createButtonNoBorderRadius(color) {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all<Size>(const Size.fromHeight(40)),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor:
          WidgetStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor: WidgetStateProperty.all<Color>(color),
    );
  }

  static createButton2(color, {Color border = Colors.transparent}) {
    return ButtonStyle(
      elevation: WidgetStateProperty.all<double>(1.5),
      minimumSize: WidgetStateProperty.all<Size>(
        const Size(160, 75),
      ),
      maximumSize: WidgetStateProperty.all<Size>(
        const Size(160, 75),
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor:
          WidgetStateProperty.all<Color>(const Color(0xFF0e0e0e)),
      backgroundColor: WidgetStateProperty.all<Color>(color),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: border, width: 1),
      )),
    );
  }
}
