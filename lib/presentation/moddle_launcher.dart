import 'package:url_launcher/url_launcher.dart';

/// 🔹 FUNCIÓN GENÉRICA PARA ABRIR MOODLE
Future<void> launchMoodleUrl(String url) async {
  final uri = Uri.parse(url);

  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('No se pudo abrir Moodle');
  }
}

Future<void> abrirFormularioCrearUrl({
  required String moodleBaseUrl,
  required int courseId,
  required int sectionNumber,
}) async {
  final uri = Uri.parse(
    '$moodleBaseUrl/course/modedit.php'
    '?add=url'
    '&course=$courseId'
    '&section=$sectionNumber',
  );

  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('No se pudo abrir Moodle');
  }
}

Future<void> abrirFormularioCrearRecurso({
  required String moodleBaseUrl,
  required int courseId,
  required int sectionNumber,
}) async {
  final url =
      '$moodleBaseUrl/course/modedit.php'
      '?add=resource'
      '&course=$courseId'
      '&section=$sectionNumber';

  await launchMoodleUrl(url);
}

Future<void> abrirFormularioCrearCarpeta({
  required String moodleBaseUrl,
  required int courseId,
  required int sectionNumber,
}) async {
  final uri = Uri.parse(
    '$moodleBaseUrl/course/modedit.php'
    '?add=folder'
    '&course=$courseId'
    '&section=$sectionNumber',
  );

  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('No se pudo abrir Moodle para crear carpeta');
  }
}
