
class ChoiceUser {
  final int id;
  final String fullname;
  final String profileImageUrl;

  ChoiceUser({required this.id, required this.fullname, required this.profileImageUrl});

  factory ChoiceUser.fromJson(Map<String, dynamic> json) {
    return ChoiceUser(
     // id: json['userid'] ?? 0,
     // fullname: json['fullname'] ?? 'Usuario',
      id: json['userid'] ?? json['id'] ?? 0,
      fullname: json['fullname'] ?? json['displayname'] ?? 'Estudiante',
      profileImageUrl: json['profileimageurl'] ?? '',
    );
  }
}

class ChoiceOption {
  final int id;
  final String text;
  final int count;
  final bool checked;
  final bool disabled;
  final List<ChoiceUser> userResponses; // <--- NUEVO: Lista de alumnos

  ChoiceOption({
    required this.id,
    required this.text,
    required this.count,
    required this.checked,
    required this.disabled,
    required this.userResponses,
  });

  factory ChoiceOption.fromJson(Map<String, dynamic> json) {
    // Capturamos la lista de alumnos si existe
    var list = json['userresponses'] as List? ?? [];
    List<ChoiceUser> usersList = list.map((i) => ChoiceUser.fromJson(i)).toList();

    return ChoiceOption(
      id: json['id'],
      text: json['text'] ?? '',
     // count: json['countanswer'] ?? 0,
      count: json['countanswer'] ?? json['numberofuser'] ?? 0,
      checked: json['checked'] == true,
      disabled: json['disabled'] == true,
      userResponses: usersList, // <--- Guardamos la lista
    );
  }
}

/*class ChoiceOption {
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
}*/