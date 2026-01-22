import 'package:url_launcher/url_launcher.dart';

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
