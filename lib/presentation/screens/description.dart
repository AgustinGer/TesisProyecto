import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class DescriptionScreen extends StatelessWidget {
  // El widget recibe la descripción en su constructor
  final String description;

  const DescriptionScreen({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Introducción del Curso '),
      ),
      body: SingleChildScrollView(
        // Añadimos un padding para que el texto no esté pegado a los bordes
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        
        // Usamos el widget Html para renderizar el texto correctamente
        child: Html(
          data: description, // Le pasamos el string con el contenido HTML
          style: {
            // Opcional: puedes definir estilos para las etiquetas HTML
            "body": Style(
              fontSize: FontSize(16.0),
              lineHeight: LineHeight.number(1.5),
            ),
            "p": Style( // Estilo para los párrafos
               padding: HtmlPaddings.zero,
               margin: Margins.zero,
            ),
          },
        ),
      ),
    );
  }
}