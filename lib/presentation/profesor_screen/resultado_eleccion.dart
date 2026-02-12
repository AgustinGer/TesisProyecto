import 'package:flutter/material.dart';
import 'package:flutter_tesis/presentation/model/choice_model.dart';

/*
class ResultadosEleccionModal extends StatelessWidget {
  final List<ChoiceOption> options;

  const ResultadosEleccionModal({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabecera
          Container(
            width: 40, height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text("Resultados de la Elección", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: Text("${option.count}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                    title: Text(option.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${option.userResponses.length} estudiantes"),
                    children: [
                      if (option.userResponses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Nadie ha elegido esta opción aún.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        )
                      else
                        ...option.userResponses.map((student) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: student.profileImageUrl.isNotEmpty 
                                ? NetworkImage(student.profileImageUrl) 
                                : null,
                              child: student.profileImageUrl.isEmpty 
                                ? const Icon(Icons.person, color: Colors.grey) 
                                : null,
                            ),
                            title: Text(student.fullname, style: const TextStyle(fontSize: 14)),
                            dense: true,
                          );
                        }),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CERRAR"),
            ),
          )
        ],
      ),
    );
  }
}*/

class ResultadosEleccionModal extends StatelessWidget {
  final List<ChoiceOption> options;

  const ResultadosEleccionModal({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Barra superior de "arrastrar"
          Container(
            width: 40, height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text("Resultados de la Elección", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                
                // LÓGICA CLAVE:
                // Si hay votos (count > 0) PERO la lista de nombres está vacía...
                // significa que es ANÓNIMO o PRIVADO.
                final bool isAnonymous = (option.count > 0 && option.userResponses.isEmpty);
                final bool noVotes = (option.count == 0);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: Text("${option.count}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                    title: Text(option.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      noVotes ? "Sin votos" : "${option.count} votos registrados"
                    ),
                    children: [
                      // CASO 1: NADIE VOTÓ
                      if (noVotes)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Nadie ha elegido esta opción aún.", 
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                          ),
                        ),

                      // CASO 2: HAY VOTOS, PERO SON ANÓNIMOS
                      if (isAnonymous)
                         Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.orange.shade50,
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip_outlined, color: Colors.orange.shade800, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "No se ha habilitado para ver los resultados completos (Anónimo).", 
                                  style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // CASO 3: HAY VOTOS Y NOMBRES (NORMAL)
                      if (!noVotes && !isAnonymous)
                        ...option.userResponses.map((student) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: (student.profileImageUrl.isNotEmpty) 
                                ? NetworkImage(student.profileImageUrl) 
                                : null,
                              child: student.profileImageUrl.isEmpty 
                                ? const Icon(Icons.person, color: Colors.grey) 
                                : null,
                            ),
                            title: Text(student.fullname, style: const TextStyle(fontSize: 14)),
                            dense: true,
                          );
                        }),
                        
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CERRAR"),
            ),
          )
        ],
      ),
    );
  }
}