/// Criterios de búsqueda de prendas. Es inmutable y comparable.
class SearchFilters {
  SearchFilters({String query = '', String? size, String? color, this.branchId})
    : query = query.trim(),
      size = _clean(size),
      color = _clean(color);

  /// Texto libre (nombre, descripción o marca), ya sin espacios sobrantes.
  final String query;
  final String? size;
  final String? color;

  /// Identificador de la sucursal, igual que `Branch.id`.
  final String? branchId;

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// `true` si no hay ningún criterio.
  bool get isEmpty =>
      query.isEmpty && size == null && color == null && branchId == null;

  /// Cuántos filtros (sin contar el texto) están activos.
  int get activeFilterCount =>
      [size, color, branchId].where((value) => value != null).length;

  SearchFilters copyWith({
    String? query,
    String? Function()? size,
    String? Function()? color,
    String? Function()? branchId,
  }) => SearchFilters(
    query: query ?? this.query,
    size: size != null ? size() : this.size,
    color: color != null ? color() : this.color,
    branchId: branchId != null ? branchId() : this.branchId,
  );

  /// Quita talla, color y sucursal, y conserva el texto.
  SearchFilters withoutFilters() => SearchFilters(query: query);

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.query == query &&
      other.size == size &&
      other.color == color &&
      other.branchId == branchId;

  @override
  int get hashCode => Object.hash(query, size, color, branchId);
}
