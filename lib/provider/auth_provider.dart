// archivo: providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Un provider para guardar el token del usuario
final authTokenProvider = StateProvider<String?>((ref) => null);

// Un provider para guardar el ID del usuario
final userIdProvider = StateProvider<int?>((ref) => null);