// Cliente HTTP (patrón Decorator): envuelve fetch y agrega el token Bearer a cada petición.
// Traduce las respuestas de error de la API a un ApiError con un mensaje apto para el usuario.

export class ApiError extends Error {
  constructor(status, code, message, detalles) {
    super(message);
    this.status = status;
    this.code = code;
    this.detalles = detalles;
  }
}

const MENSAJES = {
  0: 'No hay conexión con el servidor. Revisa tu internet e intenta de nuevo.',
  401: 'Tu sesión expiró. Vuelve a iniciar sesión.',
  403: 'No tienes permiso para esta acción.',
  404: 'No se encontró lo que buscabas.',
  500: 'Ocurrió un error en el servidor. Intenta más tarde.',
};

export function createHttpClient({ baseUrl, getToken }) {
  async function request(method, path, body) {
    const token = await getToken();
    let res;
    try {
      res = await fetch(`${baseUrl}${path}`, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
    } catch {
      throw new ApiError(0, 'SIN_CONEXION', MENSAJES[0]);
    }

    const data = await res.json().catch(() => null);
    if (!res.ok) {
      // 400 y 409 traen mensajes de negocio útiles (código duplicado, datos inválidos)
      const usarMensajeApi = res.status === 400 || res.status === 409;
      const mensaje = usarMensajeApi && data?.mensaje ? data.mensaje : MENSAJES[res.status] || MENSAJES[500];
      throw new ApiError(res.status, data?.error, mensaje, data?.detalles);
    }
    return data;
  }

  return {
    get: (path) => request('GET', path),
    post: (path, body) => request('POST', path, body),
    put: (path, body) => request('PUT', path, body),
    del: (path) => request('DELETE', path),
  };
}

/** Convierte un objeto de filtros en query string, omitiendo los vacíos. */
export function toQuery(params = {}) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && String(v).trim() !== '') q.set(k, String(v).trim());
  });
  const s = q.toString();
  return s ? `?${s}` : '';
}
