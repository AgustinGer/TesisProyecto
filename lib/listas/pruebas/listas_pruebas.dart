import 'package:flutter/material.dart';

class MenuItem{
  final String title; 
  final String subtittle;
  final String link;
  final IconData icon;

  const MenuItem({
    required this.title, 
    required this.subtittle,
    required this.link, 
    required this.icon});
}

 const appMenuItems = <MenuItem>[
  MenuItem(
    title: 'Programacion', 
    subtittle: 'orientada a objetos', 
    link: '/programa', 
    icon: Icons.keyboard_double_arrow_left_rounded
    ),

  MenuItem(
    title: 'Python', 
    subtittle: 'codigo abierto', 
    link: '/python para principiantes', 
    icon: Icons.priority_high_outlined
    ),

  MenuItem(
    title: 'ALGEBRA', 
    subtittle: 'Matrices', 
    link: '/algebra_baldor', 
    icon: Icons.account_tree
    ),

  MenuItem(
    title: 'FISICA', 
    subtittle: 'electricidad y magnetismo', 
    link: '/programa/fisica', 
    icon: Icons.apple
    ),
];

          /*  ExpansionTile(
              leading: Icon(Icons.add_ic_call_outlined),
              title: Text('ACTIVIDADES'),
              shape: LinearBorder(side: BorderSide.none),
              children: [
                ListTile(
                leading: Icon(Icons.video_call_sharp  , color: Colors.grey),
            // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
                subtitle: Text('Videos de apoyo'),
                onTap: () {
              
             },
            ),
              ],
            
              )*/