// lib/models/user.dart
import 'package:hive/hive.dart';

part 'user.g.dart'; // Archivo generado por Hive

@HiveType(typeId: 0) // typeId debe ser único para cada modelo
class User {
  @HiveField(0) // Cada campo debe tener un HiveField único
  final String displayName;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String uid;

  User({
    required this.displayName,
    required this.email,
    required this.uid,
  });
}