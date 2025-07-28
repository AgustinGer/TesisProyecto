import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class DescriptionScreen extends StatelessWidget {
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
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Html(
          data: description, 
          style: {
            "body": Style(
              fontSize: FontSize(16.0),
              lineHeight: LineHeight.number(1.5),
            ),
            "p": Style( 
               padding: HtmlPaddings.zero,
               margin: Margins.zero,
            ),
          },
        ),
      ),
    );
  }
}