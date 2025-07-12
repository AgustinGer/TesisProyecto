import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:flutter_tesis/presentation/screens.dart';
import 'package:flutter_tesis/presentation/shared/email_login.dart';
import 'package:flutter_tesis/presentation/shared/password_login.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      body: BodyLogin(),
    );
  }
}

class BodyLogin extends StatefulWidget {
    const BodyLogin({
    super.key,
  });

   @override
  State<BodyLogin> createState() => _BodyLoginState();
}

class _BodyLoginState extends State<BodyLogin>{

  final _usernameController= TextEditingController();
  final _passwordController= TextEditingController();
  bool _isloading= false;

  Future<void> _login() async {
      //validar si los campos en los textfield estan llenos o vacios
     if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa usuario y contraseña')),
      );
      return;
    }

    setState(() {
      _isloading=true;
    });
   
    const String moodleUrl ='http://192.168.1.45/tesismovil/login/token.php';
   // const String moodleUrl = 'http://10.0.2.2/tesismovil/login/token.php';
    const String service = 'my_Api';

    try {
      final response = await http.post(
        Uri.parse(moodleUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': _usernameController.text,
          'password': _passwordController.text,
          'service': service,
        },
      );

  //      print('CÓDIGO DE ESTADO: ${response.statusCode}');
 // print('RESPUESTA DEL SERVIDOR: ${response.body}');

    final Map<String, dynamic> responseData= jsonDecode(response.body);

          if (response.statusCode == 200 && responseData.containsKey('token')) {
        // LOGIN EXITOSO
        final String token = responseData['token'];
       // print('Login exitoso! Token: $token');
        
        // Aquí deberías guardar el token y navegar a la siguiente pantalla
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
        );
       // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Inicio(token: token)));
        // ignore: use_build_context_synchronously
        context.push('/inicio');
      } else {
        final String errorMessage = responseData['error'] ?? 'Error desconocido';
       // print('Error de login: $errorMessage');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
        );
      } 
  
  }catch(e){
   // print('Excepción de red: $e');
      // ignore: use_build_context_synchronously
   /*   ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar al servidor.')),
      );*/
    print('TIPO DE ERROR: ${e.runtimeType}');
    print('MENSAJE DE ERROR DETALLADO: $e');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error inesperado. Revisa la consola.')),
    );
  } finally {
    setState(() {
      _isloading= false;
    });
  }
}

  @override
  void dispose() {
    // Limpia los controladores cuando el widget se destruye
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 70),
       
        child: ListView(
          shrinkWrap: true,
          children: [

        /*Center(
              child: SizedBox(
                child: CircleAvatar(
                   backgroundImage: NetworkImage('https://kachagain.com/llsif/ur/955.png'),
                ),
              ),
            ),*/

            SizedBox(height: 50),
            
            Center(
              child: Container(
               height: 200,
               width: 300,     
               decoration: BoxDecoration(
              // color: Colors.black,
               borderRadius: BorderRadius.circular(20),
               image: DecorationImage(image: NetworkImage('https://img.freepik.com/vector-premium/logo-nombre-universidad-logo-empresa-llamada-universidad_516670-732.jpg'),fit:BoxFit.cover ),
                ),
              ),
            ),

            SizedBox(height: 40),

            Text('Email address or usarname'),

            EmailLogin(controller: _usernameController),
            
            SizedBox(height: 20),

            Text('Password'),

            PasswordLogin(passwordcontroller: _passwordController),
            
            SizedBox(height: 20),

            Center(
              child: _isloading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                onPressed:_login,
                 style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)
                 ),
                child: Text('Log in', style: TextStyle(color: colors.primary),)),
            )

          ],
        ),
      ),
    );
  }
}