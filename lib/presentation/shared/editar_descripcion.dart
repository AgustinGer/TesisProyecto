import 'package:flutter/material.dart';

class EditarDescripcion extends StatelessWidget {
  const EditarDescripcion({super.key});

  @override
  Widget build(BuildContext context) {
    final textControler= TextEditingController();
    final focusNode = FocusNode();

    final colors= Theme.of(context).colorScheme;

    /*final outlineInputBorder = UnderlineInputBorder(
      //borderSide: BorderSide(color: colors.primary),
      borderRadius: BorderRadius.circular(5)
    );*/

    final borderStyle = OutlineInputBorder(
      // Establece el color del borde
      borderSide: BorderSide(color: colors.primary), 
      borderRadius: BorderRadius.circular(5),
    );

    final inputDecoration = InputDecoration(
      hintText: 'Soy una persona tranquila,',
      fillColor: Colors.white,
      //enabledBorder: outlineInputBorder,
      enabledBorder: borderStyle,
      //focusedBorder: outlineInputBorder,
      focusedBorder: borderStyle,
      filled: true,
    );
    return TextFormField(
      //keyboardType: , correo
      focusNode: focusNode,
      controller: textControler,
      decoration: inputDecoration,
      onFieldSubmitted: (value) {   //recibir parametros
        // ignore: avoid_print
        print('submit: $value');
        textControler.clear();
        focusNode.requestFocus();
      },
  /*    onChanged: (value) {
        print('changed: $value');
      },*/
    );
  }
}