import 'package:flutter/material.dart';
import 'package:flutter_tesis/presentation/shared/email_login.dart';
import 'package:flutter_tesis/presentation/shared/password_login.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      body: _BodyLogin(),
    );
  }
}

class _BodyLogin extends StatelessWidget {
 /* const _bodyLogin({
    super.key,
  });*/
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
   // final colors= Theme.of(context).colorScheme;
    return SafeArea(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 70),
       
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

        /*    Center(
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

            EmailLogin(),
            
            SizedBox(height: 20),

            Text('Password'),

            PasswordLogin(),
            
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: (){}, 
                    child: Text('Log in', style: TextStyle(color: colors.primary),))
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}