

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/theme/app_temas.dart';

final isDarkModeProvider= StateProvider((ref)=> false);

//listado de colores inmutables

final colorListProvider = Provider((ref)=>colorList);

//provider para saber que tema esta seleccionado

final selectColorProvider = StateProvider((ref)=>0);