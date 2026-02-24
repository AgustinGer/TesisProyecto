//import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/moodle_service.dart';
//import 'package:flutter_tesis/presentation/screens.dart';
import 'package:flutter_tesis/presentation/shared/email_login.dart';
import 'package:flutter_tesis/presentation/shared/password_login.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
//import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Limpiamos la función _login para que haga solo lo necesario
  Future<void> _login() async {
    //if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (!_formKey.currentState!.validate()) {
    //  ScaffoldMessenger.of(context).showSnackBar(
      //  const SnackBar(content: Text('Por favor, ingresa email y contraseña')),
      //);
      return;
    }

    setState(() { _isLoading = true; });

    
// 172.29.15.191f
    const String loginUrl = 'http://192.168.1.45/tesismovil/login/token.php';
    //const String apiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
    final apiUrl = ref.watch(moodleApiUrlProvider);

    
   // const String loginUrl = 'http://172.29.15.191/tesismovil/login/token.php';
   // const String apiUrl = 'http://172.29.15.191/tesismovil/webservice/rest/server.php';

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
            'wsfunction': 'core_user_get_users_by_field',
            'moodlewsrestformat': 'json',
            'field': 'email',
            'values[0]': _emailController.text,
          },
        );

        final List<dynamic> userData = json.decode(userResponse.body);
        final int userId = userData[0]['id'];

     //  final apiUrl = ref.read(moodleApiUrlProvider);

        // 1️⃣ ¿Es Admin?
        final isAdmin = await checkIsAdmin(
          apiUrl: apiUrl,
          token: userToken,
        );

        ref.read(isAdminProvider.notifier).state = isAdmin;
        // --- PASO 3: Guardar el token de ADMIN y el ID del USUARIO en Riverpod ---
       ref.read(authTokenProvider.notifier).state = userToken;
       ref.read(userIdProvider.notifier).state = userId;
       ref.read(urlProvider.notifier).state = apiUrl;


       // --- NUEVO: GUARDAR EN DISCO (MEMORIA PERSISTENTE) ---
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', userToken);
        await prefs.setInt('user_id', userId);
        await prefs.setBool('is_admin', isAdmin);

        // --- PASO 4: Navegar a la pantalla de inicio ---
        if (mounted) { // Verificación de seguridad
          //context.push('/inicio');
           context.go('/inicio'); 
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
          const SnackBar(content: Text('Error de identificación.')),
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
       
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          
              SizedBox(height: 50),
              
              Center(
                child: Container(
                 height: 250,
                 width: 250,     
                 decoration: BoxDecoration(
                // color: Colors.black,
                 borderRadius: BorderRadius.circular(20),
                // image: DecorationImage(image: NetworkImage('https://img.freepik.com/vector-premium/logo-nombre-universidad-logo-empresa-llamada-universidad_516670-732.jpg'),fit:BoxFit.cover ),
                 image: DecorationImage(image: AssetImage( 'assets/imagenes/logoEuler.png'), fit: BoxFit.fill),
                
                  ),
                ),
              ),
          
              SizedBox(height: 40),
          
              Text('Email address'),
          
              EmailLogin(controller: _emailController),
              
              SizedBox(height: 20),
          
              Text('Password EDU'),
          
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
                  child: Text('Login', style: TextStyle(color: colors.primary),)),
              )
          
            ],
          ),
         ), 
        ),
      ),
    );
  }
}