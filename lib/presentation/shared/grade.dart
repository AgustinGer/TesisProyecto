class GradeItem {
  final String itemname;
  final String gradeformatted;
  final String rangeformatted;
  final String? feedback;
  final bool isCategory; // Para saber si es el total de una categoría

  GradeItem({
    required this.itemname,
    required this.gradeformatted,
    required this.rangeformatted,
    this.feedback,
    this.isCategory = false,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      // A veces Moodle devuelve null en el nombre si es una categoría raíz
      itemname: json['itemname'] ?? 'Elemento de calificación', 
      gradeformatted: json['gradeformatted'] ?? '-',
   //   rangeformatted: json['rangeformatted'] ?? '',
      rangeformatted: (json['rangeformatted'] ?? '')
    .toString()
    .replaceAll('&ndash;', '–'),
      feedback: json['feedback'],
      // Moodle suele marcar los totales con 'itemtype': 'course' o 'category'
      isCategory: json['itemtype'] == 'course' || json['itemtype'] == 'category',
    );
  }
}