import 'package:flutter/material.dart';

class TitulosMenu {
  final String tituloMenu;
  final String link;
  final IconData iconTitulo;
  final VoidCallback? onTap; 

  const TitulosMenu({
    required this.tituloMenu, 
    required this.link,
    required this.iconTitulo,
    this.onTap, 
    });
}


const appTitulosMenu= <TitulosMenu>[
  TitulosMenu(
    tituloMenu: 'Perfil', 
    link: '/perfil',
    iconTitulo: Icons.person_search ),

  TitulosMenu(
    tituloMenu: 'Editar Perfil', 
    link: '/editar_perfil',
    iconTitulo: Icons.settings_accessibility_sharp),

  TitulosMenu(
    tituloMenu: 'Calendario', 
    link: '/calendario',
    iconTitulo: Icons.calendar_month_sharp),

  TitulosMenu(
    tituloMenu: 'Cerrar sesión', 
    link: '/login',
    iconTitulo: Icons.logout_outlined,
    ),
    

  TitulosMenu(
    tituloMenu: 'Temas', 
    link: '/theme',
    iconTitulo: Icons.color_lens_rounded),
];