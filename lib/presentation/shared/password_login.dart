import 'package:flutter/material.dart';

class PasswordLogin extends StatelessWidget {
  final TextEditingController passwordcontroller;
  const PasswordLogin({super.key, required this.passwordcontroller});

  @override
  Widget build(BuildContext context) {
    //final textControler= TextEditingController();
    final focusNode = FocusNode();

    final outlineInputBorder = UnderlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(5)
    );

    final inputDecoration = InputDecoration(
      hintText: 'what is your password??',
      enabledBorder: outlineInputBorder,
      focusedBorder: outlineInputBorder,
      filled: true,
      suffixIcon: IconButton(
        icon: const Icon(Icons.password),
        onPressed: (){
          
         // final textValue= textControler.value.text;
          // ignore: avoid_print
         // print('butoom: $textValue');
         // textControler.clear();
  //       passwordcontroller.clear();
        },
      ),
    );



    return TextFormField(
      //keyboardType: , correo
      focusNode: focusNode,
     // controller: textControler,
      controller: passwordcontroller,
      decoration: inputDecoration,
       validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Falta rellenar el campo password'; // Mensaje de error en rojo
        }
        return null; // Válido
      },
 /*     onFieldSubmitted: (value) {   //recibir parametros
        // ignore: avoid_print
        //print('submit: $value');
        //textControler.clear();
      //  passwordcontroller.clear();
        focusNode.requestFocus();
      },*/
  /*    onChanged: (value) {
        print('changed: $value');
      },*/
    );
  }
}