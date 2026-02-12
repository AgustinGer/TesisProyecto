class ChoiceOption {
  final int id;
  final String text;
  final int count;       // Cuántos votos tiene (si es visible)
  final bool checked;    // Si el usuario ya votó por esta
  final bool disabled;   // Si está deshabilitada (ej: cupo lleno)

  ChoiceOption({
    required this.id,
    required this.text,
    required this.count,
    required this.checked,
    required this.disabled,
  });

  factory ChoiceOption.fromJson(Map<String, dynamic> json) {
    return ChoiceOption(
      id: json['id'],
      text: json['text'] ?? '',
      count: json['countanswer'] ?? 0,
      checked: json['checked'] == true,
      disabled: json['disabled'] == true,
    );
  }
}