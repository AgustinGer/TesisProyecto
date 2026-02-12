import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_html/flutter_html.dart'; // Para la descripción
import 'package:flutter_tesis/presentation/model/choice_model.dart';
import 'package:flutter_tesis/presentation/profesor_screen/resultado_eleccion.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


class EleccionScreen extends ConsumerStatefulWidget {
  final int choiceId;      
  final String title;
  final int moduleId;      
  final int courseId;      

  final bool isTeacher;

  const EleccionScreen({
    super.key,
    required this.choiceId,
    required this.title,
    required this.moduleId,
    required this.courseId, 
 
    required this.isTeacher,
 
  });

  @override
  ConsumerState<EleccionScreen> createState() => _EleccionScreenState();
}

class _EleccionScreenState extends ConsumerState<EleccionScreen> {
  bool _isLoading = true;
  bool _isSending = false;
  List<ChoiceOption> _options = [];
  final Set<int> _selectedIds = {}; 
  
  // CONFIGURACIONES MOODLE
  bool _allowMultiple = false; // ¿Permite seleccionar varias?
  bool _allowUpdate = false;   // ¿Permite cambiar el voto después de guardar? [NUEVO]
  bool _hasVoted = false;      // ¿El usuario ya votó anteriormente? [NUEVO]

  int _timeOpen = 0;
  int _timeClose = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatosCompletos();
  }

  Future<void> _cargarDatosCompletos() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      // 1. OBTENER CONFIGURACIÓN (allowmultiple, allowupdate)
      final configResponse = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_choice_get_choices_by_courses',
          'moodlewsrestformat': 'json',
          'courseids[0]': widget.courseId.toString(),
        },
      );
      
      if (configResponse.statusCode == 200) {
        final configData = json.decode(configResponse.body);
        if (configData is Map && configData.containsKey('choices')) {
          final List choices = configData['choices'];
          final myChoice = choices.firstWhere(
            (c) => c['id'] == widget.choiceId, 
            orElse: () => null
          );
          
          if (myChoice != null) {
            setState(() {
              _allowMultiple = (myChoice['allowmultiple'] == 1 || myChoice['allowmultiple'] == true);
              // --- NUEVO: LEEMOS SI SE PERMITE ACTUALIZAR ---
              _allowUpdate = (myChoice['allowupdate'] == 1 || myChoice['allowupdate'] == true);


              _timeOpen = myChoice['timeopen'] ?? 0;
              _timeClose = myChoice['timeclose'] ?? 0;
            });
          }
        }
      }

      // 2. OBTENER OPCIONES Y VOTOS ACTUALES
      final optionsResponse = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_choice_get_choice_options',
          'moodlewsrestformat': 'json',
          'choiceid': widget.choiceId.toString(),
        },
      );

      if (optionsResponse.statusCode == 200) {

        final data = json.decode(optionsResponse.body);
        print("DEBUG JSON MOODLE: ${json.encode(data)}");

        
        if (data is Map && data.containsKey('options')) {
          final List rawOptions = data['options'];
          
          setState(() {
            _options = rawOptions.map((e) => ChoiceOption.fromJson(e)).toList();
            
            _selectedIds.clear();
            _hasVoted = false; // Reseteamos

            for (var op in _options) {
              if (op.checked) {
                _selectedIds.add(op.id);
                _hasVoted = true; // Detectamos si ya había votado
              }
            }
            
            _isLoading = false;
          });
        }
      }
    /* else {
        print("Error del servidor: ${optionsResponse.statusCode}");
     }
        
    } catch (e) {
      print('Error cargando: $e');
    } finally {
      // --- CORRECCIÓN CLAVE ---
      // El loading se apaga SIEMPRE, haya error o haya éxito.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }*/
    }catch (e) {
      print('Error cargando: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarVoto() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos una opción')));
      return;
    }

    setState(() => _isSending = true);
    
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    final Map<String, String> body = {
      'wstoken': token!,
      'wsfunction': 'mod_choice_submit_choice_response',
      'moodlewsrestformat': 'json',
      'choiceid': widget.choiceId.toString(),
    };

    int i = 0;
    for (int id in _selectedIds) {
      body['responses[$i]'] = id.toString();
      i++;
    }

    try {
      final response = await http.post(Uri.parse(apiUrl), body: body);
      final data = json.decode(response.body);

      if (mounted) {
        setState(() => _isSending = false);
        
        if (data is Map && data.containsKey('exception')) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Elección guardada correctamente!'), backgroundColor: Colors.green),
          );
          _cargarDatosCompletos(); 
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _onOptionChanged(int id, bool? selected) {
    setState(() {
      if (_allowMultiple) {
        if (selected == true) _selectedIds.add(id);
        else _selectedIds.remove(id);
      } else {
        _selectedIds.clear(); 
        _selectedIds.add(id); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalVotes = 0;
    for (var op in _options) totalVotes += op.count;

// --- [NUEVO] LÓGICA DE TIEMPO ---
    final now = DateTime.now();
    bool isEarly = false;
    bool isLate = false;

    // Verificamos apertura
    if (_timeOpen > 0) {
      final openDate = DateTime.fromMillisecondsSinceEpoch(_timeOpen * 1000);
      if (now.isBefore(openDate)) isEarly = true;
    }

    // Verificamos cierre
    if (_timeClose > 0) {
      final closeDate = DateTime.fromMillisecondsSinceEpoch(_timeClose * 1000);
      if (now.isAfter(closeDate)) isLate = true;
    }

    // Bloqueo final: 
    // Está bloqueado SI (ya votó Y no puede actualizar) O (es muy temprano) O (es muy tarde)
    // EXCEPCIÓN: Los profesores suelen poder votar o ver cosas siempre, pero asumamos regla general.
    final bool isLocked = (_hasVoted && !_allowUpdate) || isEarly || isLate;

    // Mensaje de estado
    String statusMessage = "";
    Color statusColor = Colors.transparent;
    
    if (isEarly) {
      statusMessage = "Esta actividad abrirá el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_timeOpen * 1000))}";
      statusColor = Colors.orange.shade100;
    } else if (isLate) {
      statusMessage = "Esta actividad cerró el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_timeClose * 1000))}";
      statusColor = Colors.red.shade100;
    } else if (_hasVoted && !_allowUpdate) {
      statusMessage = "Ya has realizado tu elección y no puedes cambiarla.";
      statusColor = Colors.blue.shade100;
    }
    // --- LÓGICA DE BLOQUEO ---
    // Está bloqueado SI (ya votó Y NO se permite actualizar)
    //final bool isLocked = _hasVoted && !_allowUpdate;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,

        actions: [
          // BOTÓN SOLO PARA PROFESORES
          if (widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.people_alt_rounded), // Icono de gente/resultados
              tooltip: 'Ver estudiantes',
              onPressed: () async {
              //onPressed: () {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) => const Center(child: CircularProgressIndicator()),
                );
                // Abrimos el modal con la info que ya tenemos cargada en _options
                /*showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ResultadosEleccionModal(options: _options),
                );*/
                final token = ref.read(authTokenProvider);
                final apiUrl = ref.read(moodleApiUrlProvider);

                try {
                  // 2. CONSULTA ESPECÍFICA DE RESULTADOS
                  final response = await http.post(
                    Uri.parse(apiUrl),
                    body: {
                      'wstoken': token,
                      'wsfunction': 'mod_choice_get_choice_results', // <--- LA NUEVA FUNCIÓN
                      'moodlewsrestformat': 'json',
                      'choiceid': widget.choiceId.toString(),
                    },
                  );

//                  Navigator.pop(context); // Cerrar loading

                  if (context.mounted) Navigator.pop(context);

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    
                    // Debug para ver si ahora sí llegan
                    print("DEBUG RESULTADOS: ${json.encode(data)}");

                    if (data is Map && data.containsKey('options')) {
                      final List rawOptions = data['options'];
                      
                      // 3. ACTUALIZAR NUESTRAS OPCIONES CON LOS DATOS COMPLETOS
                      // Moodle devuelve una estructura similar, pero ahora CON 'userresponses'
                      List<ChoiceOption> fullOptions = rawOptions.map((e) => ChoiceOption.fromJson(e)).toList();

                      // 4. ABRIR EL MODAL CON LA DATA COMPLETA
                      if (context.mounted) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ResultadosEleccionModal(options: fullOptions),
                        );
                      }
                    } else if (data is Map && data.containsKey('exception')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error Moodle: ${data['message']}'), backgroundColor: Colors.red),
                      );
                    }
                  }
                } catch (e) {
                  Navigator.pop(context); // Cerrar loading si falla
                  print("Error al cargar resultados: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al cargar lista de estudiantes'), backgroundColor: Colors.red),
                  );
                }


              },
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

           /*      if (statusMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Icon(isLate ? Icons.lock_clock : Icons.info_outline, color: Colors.black54),
                        const SizedBox(width: 10),
                        Expanded(child: Text(statusMessage, style: const TextStyle(fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),*/

                    const Text("Tu elección:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_allowMultiple)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text("Múltiple", style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                          ),
                        // --- AVISO VISUAL SI ESTÁ BLOQUEADO ---
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text("Voto Finalizado", style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    )
                  ],
                ),
                
                // Mensaje informativo si está bloqueado
                if (isLocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("Ya has realizado tu elección y no está permitido cambiarla.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),

                const SizedBox(height: 10),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: _options.map((option) {
                      double percent = totalVotes > 0 ? (option.count / totalVotes) : 0.0;
                      bool isSelected = _selectedIds.contains(option.id);
                      
                      // Si está bloqueado, deshabilitamos la interacción (onChanged = null)
                      // También si la opción está 'disabled' por Moodle (ej: cupo lleno)
                      bool isDisabled = isLocked || option.disabled;

                      Widget? subtitleWidget;
                      if (option.count > 0) {
                        subtitleWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              LinearProgressIndicator(value: percent, backgroundColor: Colors.grey[200], color: Colors.indigo.shade300),
                              Text("${option.count} votos (${(percent * 100).toStringAsFixed(1)}%)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          );
                      }

                      if (_allowMultiple) {
                        return CheckboxListTile(
                          activeColor: Colors.indigo,
                          title: Text(option.text),
                          subtitle: subtitleWidget,
                          value: isSelected,
                          // Si está bloqueado, pasamos null para que se vea gris y no clicable
                          onChanged: isDisabled ? null : (val) => _onOptionChanged(option.id, val),
                        );
                      } else {
                        return RadioListTile<int>(
                          activeColor: Colors.indigo,
                          title: Text(option.text),
                          subtitle: subtitleWidget,
                          value: option.id,
                          groupValue: _selectedIds.isEmpty ? null : _selectedIds.first,
                          onChanged: isDisabled ? null : (val) => _onOptionChanged(val!, true),
                        );
                      }
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLocked ? Colors.grey : Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    // Deshabilitamos el botón si está bloqueado o enviando
                    onPressed: (_isSending || isLocked) ? null : _enviarVoto,
                    
                    icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(isLocked ? Icons.lock : Icons.check_circle),
                      
                    label: Text(
                      isLocked ? "VOTO REGISTRADO" : (_allowMultiple ? "GUARDAR SELECCIONES" : "GUARDAR MI ELECCIÓN"), 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
               /*    icon: Icon(isLocked ? Icons.lock : Icons.check_circle),
                    label: Text(
                      isLate ? "ACTIVIDAD CERRADA" : 
                      isEarly ? "NO INICIADA" : 
                      (_hasVoted ? "VOTO REGISTRADO" : "GUARDAR MI ELECCIÓN")
                    ),*/

                  ),
                ),
              ],
            ),
          ),
    );
  }
}
