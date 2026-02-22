import 'package:flutter/material.dart';


class PasswordLogin extends StatefulWidget {
  final TextEditingController passwordcontroller;
  const PasswordLogin({super.key, required this.passwordcontroller});

  @override
  State<PasswordLogin> createState() => _PasswordLoginState();
}

class _PasswordLoginState extends State<PasswordLogin> {
  bool _obscureText = true; // estado inicial oculto

  @override
  Widget build(BuildContext context) {
    //final focusNode = FocusNode();

    final outlineInputBorder = UnderlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(5),
    );

    final inputDecoration = InputDecoration(
      hintText: 'what is your password??',
      enabledBorder: outlineInputBorder,
      focusedBorder: outlineInputBorder,
      filled: true,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility, // cambia el icono
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText; // alternar estado
          });
         // debugPrint("👁 Password visibility: ${_obscureText ? "OCULTO" : "VISIBLE"}");
        },
      ),
    );

    return TextFormField(
    //  focusNode: focusNode,
      controller: widget.passwordcontroller,
      obscureText: _obscureText,
      decoration: inputDecoration,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Falta rellenar el campo password'; 
        }
        return null; 
      },
    );
  }
}

