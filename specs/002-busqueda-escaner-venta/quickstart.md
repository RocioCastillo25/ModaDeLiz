# Guía de validación: Consulta de inventario, escáner y venta

Pasos para comprobar que la funcionalidad cumple la especificación. Contratos: [catalog-api.md](contracts/catalog-api.md) e [internal-interfaces.md](contracts/internal-interfaces.md). Modelo: [data-model.md](data-model.md).

## Requisitos previos

- Flutter instalado (canal estable) y teléfono Android con depuración USB; la cámara solo se prueba bien en el teléfono físico.
- Desde `mobile/`: `flutter pub get`.
- Para la prueba contra el sistema real: servicios del Integrante 2 (Keycloak, API y base de datos) encendidos, y el teléfono en la misma red Wi-Fi que su computadora.

## 1. Pruebas automáticas y análisis

```text
flutter analyze
flutter test
```

Resultado esperado: sin avisos y todas las pruebas en verde, incluidas las de los ViewModels de búsqueda, ficha, venta y escáner, la validación de cantidades, el 409 y la renovación de sesión.

## 2. Con datos de ejemplo (sin servicios)

```text
flutter run --dart-define=USE_MOCK=true
```

Entrar con un usuario de ejemplo y comprobar:

| # | Prueba | Resultado esperado |
|---|--------|--------------------|
| 1 | "Buscar" y escribir parte de un nombre, con mayúsculas y espacios de más | Lista con las prendas coincidentes |
| 2 | Combinar filtros de talla, color y sucursal | Solo lo que cumple todo |
| 3 | Buscar algo inexistente | Mensaje de sin resultados |
| 4 | Abrir una ficha | Foto, datos y existencias de las 5 sucursales; la propia destacada |
| 5 | Ver una combinación en cero y otra baja | "Agotado" y "Pocas piezas" con ícono |
| 6 | Jalar para actualizar | Se vuelven a pedir los datos |
| 7 | Descontar una cantidad válida y confirmar | La existencia baja con el valor devuelto |
| 8 | Pedir más piezas de las que hay | Mensaje con la existencia actual; nada cambia |
| 9 | Cantidad vacía, cero, negativa o decimal | No se puede enviar |
| 10 | Doble toque en confirmar | Una sola venta |
| 11 | Intentar vender en una sucursal ajena | No hay acción de venta |
| 12 | Ver "Solicitar traspaso" | Deshabilitado, con "Próximamente" |

## 3. Escáner (teléfono físico)

| # | Prueba | Resultado esperado |
|---|--------|--------------------|
| 1 | Abrir "Escanear" por primera vez | Explicación breve y, al continuar, el permiso del sistema |
| 2 | Escanear una etiqueta registrada | Se abre su ficha |
| 3 | Mantener el código frente a la cámara | Una sola ficha |
| 4 | Escanear un código desconocido | "Prenda no encontrada" y se puede escanear otra vez |
| 5 | Negar el permiso | Se ofrece la búsqueda manual por código |
| 6 | Encender la linterna | Se enciende y se apaga |

## 4. Contra el sistema real

```text
flutter run --dart-define=USE_MOCK=false ^
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 ^
  --dart-define=KEYCLOAK_BASE_URL=http://10.0.2.2:8080
```

En teléfono físico se cambia `10.0.2.2` por la IP de la computadora del Integrante 2, que debe agregarla a `ALLOWED_ISSUERS`. Repetir las pruebas de las secciones 2 y 3 y comprobar además:

- La venta de prueba descuenta y la existencia se ve igual en otra sesión (otra sucursal).
- **Renovación de sesión**: con el token de 5 minutos, esperar a que venza y buscar o vender; la acción debe completarse sin pedir credenciales. Confirmar con el Integrante 2 que el realm entrega el `refresh_token`.
- **Sesión no renovable**: cerrar la sesión de Keycloak desde su consola o desactivar la cuenta; la siguiente acción debe regresar al inicio de sesión con aviso.
- Un 403 (vender en otra sucursal desde otra cuenta) muestra el aviso sin cerrar la sesión.
- Una venta interrumpida por sesión vencida no se descuenta dos veces.

## 5. Cierre del sprint

- APK de prueba para la dueña (`flutter build apk --debug` o el que acuerde el equipo) probado en un teléfono con cámara.
- Evidencia para la bitácora: capturas de búsqueda, ficha, escáner y venta, sin datos personales en la barra de estado.
- Etiqueta `v0.2.0` coordinada con el Integrante 4.
