/// Sucursal de Moda de Lizz.
class Branch {
  const Branch({required this.id, required this.name});

  final String id;
  final String name;

  /// Crea una sucursal a partir del JSON de la API.
  /// Lanza [FormatException] si falta el identificador o el nombre.
  factory Branch.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Sucursal sin identificador');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Sucursal sin nombre');
    }
    return Branch(id: id, name: name);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is Branch && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
