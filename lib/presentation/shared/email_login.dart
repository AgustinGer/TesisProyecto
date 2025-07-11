import 'package:flutter/material.dart';

class EmailLogin extends StatelessWidget {
  final TextEditingController controller;
  const EmailLogin({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
   // final textControler= TextEditingController();
    final focusNode = FocusNode();

    final outlineInputBorder = UnderlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(5)
    );

    final inputDecoration = InputDecoration(
      hintText: 'what is your email??',
      enabledBorder: outlineInputBorder,
      focusedBorder: outlineInputBorder,
      filled: true,
      suffixIcon: IconButton(
        icon: const Icon(Icons.email),
        onPressed: (){
     //     final textValue= textControler.value.text;
         // final textValue= controller.value.text;
          // ignore: avoid_print
         // print('butoom: $textValue');
         // textControler.clear();
    //      controller.clear();
        },
      ),
    );



    return TextFormField(
      //keyboardType: , correo
      focusNode: focusNode,
    //  controller: textControler,
      controller: controller,
      decoration: inputDecoration,
      onFieldSubmitted: (value) {   //recibir parametros
        // ignore: avoid_print
       // print('submit: $value');
      //  textControler.clear();
    //    controller.clear();
        focusNode.requestFocus();
      },
  /*    onChanged: (value) {
        print('changed: $value');
      },*/
    );
  }
}