import '../models/branch.dart';
import '../repositories/auth_failure.dart';

/// Sucursal tal como la entrega `GET /sucursales` (`docs/openapi.yaml`).
class BranchDto {
  const BranchDto({required this.id, required this.name});

  final int id;
  final String name;

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nombre'];
    if (id is! num || name is! String || name.trim().isEmpty) {
      throw const AuthFailure(AuthFailureType.incompleteData);
    }
    return BranchDto(id: id.toInt(), name: name);
  }

  /// Adapter: convierte el DTO en el modelo de la app.
  Branch toBranch() => Branch(id: id.toString(), name: name);
}
