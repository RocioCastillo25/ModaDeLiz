/// Estado de una existencia según su cantidad y el umbral de la prenda.
enum StockLevel {
  /// Sin piezas.
  outOfStock,

  /// Quedan pocas piezas (más de cero y no más que el umbral).
  low,

  /// Hay piezas suficientes.
  available,
}

/// Existencia de una prenda en una sucursal, para una talla y un color.
class StockItem {
  const StockItem({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.size,
    required this.color,
    required this.quantity,
  });

  /// Identificador de inventario: es el que se envía al vender.
  final int id;

  /// Identificador de la sucursal, igual que `Branch.id` del usuario.
  final String branchId;
  final String branchName;
  final String size;
  final String color;

  /// Piezas disponibles. Nunca es negativa.
  final int quantity;

  /// Estado derivado de la cantidad y del umbral de alerta de la prenda.
  StockLevel levelFor(int alertThreshold) {
    if (quantity <= 0) return StockLevel.outOfStock;
    if (quantity <= alertThreshold) return StockLevel.low;
    return StockLevel.available;
  }

  /// Indica si esta existencia pertenece a la sucursal dada.
  bool belongsTo(String? userBranchId) =>
      userBranchId != null && userBranchId == branchId;

  StockItem copyWith({int? quantity}) => StockItem(
    id: id,
    branchId: branchId,
    branchName: branchName,
    size: size,
    color: color,
    quantity: quantity ?? this.quantity,
  );

  @override
  bool operator ==(Object other) =>
      other is StockItem &&
      other.id == id &&
      other.branchId == branchId &&
      other.size == size &&
      other.color == color &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(id, branchId, size, color, quantity);
}
