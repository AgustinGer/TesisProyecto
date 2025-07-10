import 'package:flutter/material.dart';


const Color _customColor = Color(0xFF49149F);
const colorList = <Color>[
  _customColor,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.yellow,
  Colors.orange,
  Colors.pink,
];


class AppTemas {

  final int selectColor;
  final bool isdarkmode;
  //final colors= Theme.of(context!).colorScheme;

  AppTemas({
    this.isdarkmode=false,
    this.selectColor=0
  }): assert (selectColor >=0 && selectColor <= colorList.length -1,'los colores solo van de 0 a 6');
  
 // static BuildContext? get context => null;

  ThemeData theme(){
    return ThemeData(
      brightness: isdarkmode ? Brightness.dark: Brightness.light,
      useMaterial3: true,
      colorSchemeSeed: colorList[selectColor],
      appBarTheme: AppBarTheme(
      backgroundColor: isdarkmode ? null : colorList[selectColor]
      )
     // brightness: Brightness.dark  //modo oscuro
    );
  }
}