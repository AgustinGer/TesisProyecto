//import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_tesis/presentation/screens.dart';
import 'package:flutter_tesis/presentation/shared/email_login.dart';
import 'package:flutter_tesis/presentation/shared/password_login.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
//import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

//final authTokenProvider = StateProvider<String?>((ref) => null);
//final userIdProvider = StateProvider<int?>((ref) => null);

// --- Pantalla de Login ---

// Esta clase no necesita cambios
class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BodyLogin(),
    );
  }
}

// Convertida a ConsumerStatefulWidget para usar Riverpod
class BodyLogin extends ConsumerStatefulWidget {
  const BodyLogin({super.key});

  @override
  ConsumerState<BodyLogin> createState() => _BodyLoginState();
}

class _BodyLoginState extends ConsumerState<BodyLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Limpiamos la función _login para que haga solo lo necesario
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa email y contraseña')),
      );
      return;
    }

    setState(() { _isLoading = true; });


    const String loginUrl = 'http://192.168.1.45/tesismovil/login/token.php';
    const String apiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
    const String service = 'my_Api';
    //const String adminToken = '3a3559654e6130b6c670c7eb1444a574'; 
    try {
      // --- PASO 1: Validar las credenciales del usuario ---
      final loginResponse = await http.post(
        Uri.parse(loginUrl),
        body: {
          'username': _emailController.text,
          'password': _passwordController.text,
          'service': service,
        },
      );

      final loginData = json.decode(loginResponse.body);

      // Si las credenciales son válidas, Moodle devuelve un token.
      if (loginResponse.statusCode == 200 && loginData.containsKey('token')) {
        final userToken = loginData['token'];
        // --- PASO 2: Obtener el ID del usuario que inició sesión ---
        // Usamos el token de ADMIN para esta llamada, como decidimos.
        final userResponse = await http.post(
          Uri.parse(apiUrl),
          body: {
            'wstoken': userToken,
           // 'wstoken': adminToken,
            'wsfunction': 'core_user_get_users_by_field',
            'moodlewsrestformat': 'json',
            'field': 'email',
            'values[0]': _emailController.text,
          },
        );

        final List<dynamic> userData = json.decode(userResponse.body);
        final int userId = userData[0]['id'];

        // --- PASO 3: Guardar el token de ADMIN y el ID del USUARIO en Riverpod ---
       // ref.read(authTokenProvider.notifier).state = adminToken;
       ref.read(authTokenProvider.notifier).state = userToken;
        ref.read(userIdProvider.notifier).state = userId;

        // --- PASO 4: Navegar a la pantalla de inicio ---
        if (mounted) { // Verificación de seguridad
          context.push('/inicio');
        }

      } else {
        // Si las credenciales son inválidas, muestra el error de Moodle
        final String errorMessage = loginData['error'] ?? 'Datos incorrectos';
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorMessage')),
          );
        }
      }
    } catch (e) {
      // Manejar errores de red o cualquier otra excepción
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión o del servidor.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  @override
  void dispose() {
    // Limpia los controladores cuando el widget se destruye
    _emailController.dispose();
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

            EmailLogin(controller: _emailController),
            
            SizedBox(height: 20),

            Text('Password'),

            PasswordLogin(passwordcontroller: _passwordController),
            
            SizedBox(height: 20),

            Center(
              child: _isLoading
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