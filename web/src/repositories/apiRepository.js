// Repositorio real: habla con la API REST (docs/openapi.yaml). Las páginas nunca llaman a fetch directamente.
import { toQuery } from '../api/httpClient.js';

export function createApiRepository(http) {
  return {
    getMe: () => http.get('/me'),
    listSucursales: () => http.get('/sucursales'),

    buscarPrendas: (filtros) => http.get(`/prendas${toQuery(filtros)}`),
    getPrenda: (id) => http.get(`/prendas/${id}`),
    getPrendaPorCodigo: (codigo) => http.get(`/prendas/codigo/${encodeURIComponent(codigo)}`),
    crearPrenda: (datos) => http.post('/prendas', datos),
    actualizarPrenda: (id, datos) => http.put(`/prendas/${id}`, datos),
    desactivarPrenda: (id) => http.del(`/prendas/${id}`),

    listInventario: (filtros) => http.get(`/inventario${toQuery(filtros)}`),
    fijarExistencia: (datos) => http.put('/inventario', datos),
  };
}
