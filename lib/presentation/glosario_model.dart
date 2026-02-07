
// 1. Clase auxiliar para el archivo
class GlossaryFile {
  final String filename;
  final String fileurl;
  final String mimetype;

  GlossaryFile({
    required this.filename, 
    required this.fileurl, 
    required this.mimetype
  });

  factory GlossaryFile.fromJson(Map<String, dynamic> json) {
    return GlossaryFile(
      filename: json['filename'] ?? 'Archivo sin nombre',
      fileurl: json['fileurl'] ?? '',
      mimetype: json['mimetype'] ?? '',
    );
  }
}


class GlossaryEntry {
  final int id;
  final String concept; // El término (ej: "Algoritmo")
  final String definition; // La definición (viene en HTML)
  final String userFullName; // Quién lo escribió
  final bool approved;

 //campo archivos
  final List<GlossaryFile> attachments;

  GlossaryEntry({
    required this.id,
    required this.concept,
    required this.definition,
    required this.userFullName,
    required this.approved,
    required this.attachments, //archivos
  });

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) {
    var list = json['attachments'] as List? ?? [];
    List<GlossaryFile> filesList = list.map((i) => GlossaryFile.fromJson(i)).toList();
    return GlossaryEntry(
      id: json['id'],
      concept: json['concept'] ?? 'Sin término',
      definition: json['definition'] ?? '', 
      userFullName: json['userfullname'] ?? 'Anónimo',
      approved: json['approved'] == 1 || json['approved'] == true,
      attachments: filesList, // Asignamos la lista
    );
  }
}