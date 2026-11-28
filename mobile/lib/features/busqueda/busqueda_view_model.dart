import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/branch.dart';
import '../../data/models/prenda.dart';
import '../../data/models/search_filters.dart';
import '../../data/repositories/branch_repository.dart';
import '../../data/repositories/catalog_failure.dart';
import '../../data/repositories/prenda_repository.dart';

/// Estado visible de la búsqueda: cargando, con resultados, sin resultados o
/// con error.
enum BusquedaStatus { idle, loading, results, empty, error }

/// ViewModel de la búsqueda de prendas. No conoce widgets.
class BusquedaViewModel extends ChangeNotifier {
  BusquedaViewModel(
    this._prendas,
    this._branches, {
    this.debounce = const Duration(milliseconds: 400),
    this.pageSize = 20,
  });

  final PrendaRepository _prendas;
  final BranchRepository _branches;

  /// Espera tras la última letra escrita antes de buscar.
  final Duration debounce;

  /// Cuántos resultados se muestran por bloque.
  final int pageSize;

  BusquedaStatus _status = BusquedaStatus.idle;
  SearchFilters _filters = SearchFilters();
  List<Prenda> _results = const [];
  List<Branch> _branchList = const [];
  String? _errorMessage;
  int _shown = 0;
  int _requestId = 0;
  Timer? _timer;
  bool _disposed = false;

  BusquedaStatus get status => _status;
  SearchFilters get filters => _filters;
  List<Prenda> get results => _results;
  List<Branch> get branches => _branchList;

  /// Mensaje en español del último error, sin detalles técnicos.
  String? get errorMessage => _errorMessage;
  int get activeFilterCount => _filters.activeFilterCount;

  /// Los resultados que ya se muestran (por bloques).
  List<Prenda> get visibleResults =>
      _results.take(_shown).toList(growable: false);

  /// `true` si quedan resultados por mostrar.
  bool get hasMore => _shown < _results.length;

  /// Abre la pantalla: carga las sucursales del filtro y la lista inicial.
  Future<void> init() async {
    await Future.wait([_loadBranches(), search()]);
  }

  Future<void> _loadBranches() async {
    try {
      _branchList = await _branches.list();
      _notify();
    } on CatalogFailure {
      // Sin la lista, el filtro de sucursal queda vacío; la búsqueda sigue.
    } catch (_) {
      // Igual que arriba: no es crítico.
    }
  }

  /// Cambia el texto mientras se escribe: espera un momento y busca.
  void onQueryChanged(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () => updateQuery(text));
  }

  /// Cambia el texto y busca de inmediato.
  Future<void> updateQuery(String text) {
    _timer?.cancel();
    _filters = _filters.copyWith(query: text);
    return search();
  }

  /// Aplica talla, color y sucursal (conserva el texto actual).
  Future<void> applyFilters(SearchFilters filters) {
    _timer?.cancel();
    _filters = SearchFilters(
      query: filters.query.isEmpty ? _filters.query : filters.query,
      size: filters.size,
      color: filters.color,
      branchId: filters.branchId,
    );
    return search();
  }

  /// Quita talla, color y sucursal, y conserva el texto.
  Future<void> clearFilters() {
    _timer?.cancel();
    _filters = _filters.withoutFilters();
    return search();
  }

  /// Busca con los filtros actuales. Ignora la respuesta si hay una búsqueda
  /// más reciente.
  Future<void> search() async {
    final id = ++_requestId;
    _status = BusquedaStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      final found = await _prendas.search(_filters);
      if (id != _requestId) return;
      _results = found;
      _shown = found.length < pageSize ? found.length : pageSize;
      _status = found.isEmpty ? BusquedaStatus.empty : BusquedaStatus.results;
    } on CatalogFailure catch (failure) {
      if (id != _requestId) return;
      _fail(failure.message);
    } catch (_) {
      if (id != _requestId) return;
      _fail(const CatalogFailure(CatalogFailureType.server).message);
    }
    _notify();
  }

  /// Vuelve a intentar la última búsqueda.
  Future<void> retry() => search();

  /// Muestra el siguiente bloque de resultados.
  void loadMore() {
    if (!hasMore) return;
    final next = _shown + pageSize;
    _shown = next > _results.length ? _results.length : next;
    _notify();
  }

  /// Limpia todo el estado (por ejemplo, al cerrar sesión).
  void reset() {
    _timer?.cancel();
    _requestId++;
    _status = BusquedaStatus.idle;
    _filters = SearchFilters();
    _results = const [];
    _shown = 0;
    _errorMessage = null;
    _notify();
  }

  void _fail(String message) {
    _results = const [];
    _shown = 0;
    _errorMessage = message;
    _status = BusquedaStatus.error;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
