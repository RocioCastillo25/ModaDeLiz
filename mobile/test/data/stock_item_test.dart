import 'package:checklizz/data/dto/prenda_ficha_dto.dart';
import 'package:checklizz/data/dto/stock_item_dto.dart';
import 'package:checklizz/data/models/search_filters.dart';
import 'package:checklizz/data/models/stock_item.dart';
import 'package:checklizz/data/repositories/catalog_failure.dart';
import 'package:flutter_test/flutter_test.dart';

StockItem _item(int quantity, {String branch = '1'}) => StockItem(
  id: 1,
  branchId: branch,
  branchName: 'Zacatlán',
  size: 'M',
  color: 'Rosa',
  quantity: quantity,
);

void main() {
  group('StockLevel', () {
    test('cantidad cero es agotado', () {
      expect(_item(0).levelFor(2), StockLevel.outOfStock);
    });

    test('hasta el umbral es existencia baja', () {
      expect(_item(1).levelFor(2), StockLevel.low);
      expect(_item(2).levelFor(2), StockLevel.low);
    });

    test('por encima del umbral hay existencia disponible', () {
      expect(_item(3).levelFor(2), StockLevel.available);
    });

    test('respeta el umbral propio de cada prenda', () {
      expect(_item(3).levelFor(3), StockLevel.low);
    });

    test('identifica si pertenece a la sucursal del usuario', () {
      expect(_item(1, branch: '2').belongsTo('2'), isTrue);
      expect(_item(1, branch: '2').belongsTo('3'), isFalse);
      expect(_item(1).belongsTo(null), isFalse);
    });
  });

  group('SearchFilters', () {
    test('recorta los espacios del texto, la talla y el color', () {
      final filters = SearchFilters(query: '  blusa  ', size: ' M ', color: ' Rosa');
      expect(filters.query, 'blusa');
      expect(filters.size, 'M');
      expect(filters.color, 'Rosa');
    });

    test('un campo en blanco se considera vacío y no se envía', () {
      final filters = SearchFilters(query: '   ', size: '  ', color: '');
      expect(filters.isEmpty, isTrue);
      expect(filters.size, isNull);
      expect(filters.color, isNull);
    });

    test('dos filtros iguales son iguales', () {
      expect(SearchFilters(query: 'a ', size: 'M'), SearchFilters(query: 'a', size: ' M'));
    });

    test('limpiar los filtros conserva el texto', () {
      final filters = SearchFilters(query: 'blusa', size: 'M', branchId: '2');
      final cleared = filters.withoutFilters();
      expect(cleared.query, 'blusa');
      expect(cleared.activeFilterCount, 0);
      expect(filters.activeFilterCount, 2);
    });
  });

  group('DTO de existencias y fichas', () {
    const existencia = {
      'id': 5,
      'id_sucursal': 2,
      'sucursal': 'Zacatlán',
      'talla': 'M',
      'color': 'Rosa',
      'cantidad': 4,
    };

    test('convierte una existencia y usa el id de sucursal como texto', () {
      final item = StockItemDto.fromJson(existencia).toModel();
      expect(item.id, 5);
      expect(item.branchId, '2');
      expect(item.quantity, 4);
    });

    test('una cantidad negativa nunca se muestra', () {
      final item = StockItemDto.fromJson({...existencia, 'cantidad': -3}).toModel();
      expect(item.quantity, 0);
    });

    test('falla si falta un dato de la existencia', () {
      expect(
        () => StockItemDto.fromJson({...existencia}..remove('talla')),
        throwsA(isA<CatalogFailure>()),
      );
    });

    test('la ficha suma las existencias y usa el umbral de la prenda', () {
      final ficha = PrendaFichaDto.fromJson({
        'id': 1,
        'codigo_barras': '750',
        'descripcion': 'Blusa',
        'umbral_alerta': 3,
        'existencias': [existencia, {...existencia, 'id': 6, 'cantidad': 1}],
      }).toModel();
      expect(ficha.totalStock, 5);
      expect(ficha.prenda.alertThreshold, 3);
      expect(ficha.stock, hasLength(2));
    });

    test('sin umbral en la API se usa 2', () {
      final ficha = PrendaFichaDto.fromJson({
        'id': 1,
        'codigo_barras': '750',
        'descripcion': 'Blusa',
        'existencias': <Object>[],
      }).toModel();
      expect(ficha.prenda.alertThreshold, 2);
    });

    test('reemplaza una existencia tras una venta', () {
      final ficha = PrendaFichaDto.fromJson({
        'id': 1,
        'codigo_barras': '750',
        'descripcion': 'Blusa',
        'existencias': [existencia],
      }).toModel();
      final updated = ficha.withStockItem(ficha.stock.first.copyWith(quantity: 1));
      expect(updated.stock.first.quantity, 1);
      expect(updated.totalStock, 1);
    });

    test('falla si la prenda no trae descripción', () {
      expect(
        () => PrendaFichaDto.fromJson({'id': 1, 'codigo_barras': '750'}),
        throwsA(isA<CatalogFailure>()),
      );
    });
  });
}
