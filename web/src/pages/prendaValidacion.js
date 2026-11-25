// Validación del formulario de prenda. Replica los límites de la API (api/src/routes/index.js, esquema prendaNueva)
// solo para dar retroalimentación inmediata; la API sigue siendo quien decide.

export const PRENDA_VACIA = {
  codigo_barras: '', descripcion: '', marca: '', categoria: '', temporada: '', foto_url: '', umbral_alerta: '2',
};

const max = (v, n) => v.trim().length > n;

export function validarPrenda(f, esNueva) {
  const e = {};
  if (esNueva) {
    const c = f.codigo_barras.trim();
    if (c.length < 3) e.codigo_barras = 'Escribe al menos 3 caracteres.';
    else if (c.length > 64) e.codigo_barras = 'Máximo 64 caracteres.';
  }
  const d = f.descripcion.trim();
  if (d.length < 2) e.descripcion = 'La descripción es obligatoria (mínimo 2 caracteres).';
  else if (d.length > 200) e.descripcion = 'Máximo 200 caracteres.';
  if (max(f.marca, 80)) e.marca = 'Máximo 80 caracteres.';
  if (max(f.categoria, 80)) e.categoria = 'Máximo 80 caracteres.';
  if (max(f.temporada, 40)) e.temporada = 'Máximo 40 caracteres.';
  if (f.foto_url.trim()) {
    try { new URL(f.foto_url.trim()); } catch { e.foto_url = 'Escribe una dirección completa, por ejemplo https://…'; }
  }
  if (!/^\d+$/.test(String(f.umbral_alerta).trim())) e.umbral_alerta = 'Escribe un número entero de 0 en adelante.';
  return e;
}

/** Convierte el formulario al cuerpo que espera la API. */
export function aCuerpo(f, esNueva) {
  const texto = (v) => v.trim();
  const cuerpo = {
    descripcion: texto(f.descripcion),
    umbral_alerta: Number(f.umbral_alerta),
    // Al editar se envía '' para poder borrar un campo; al crear se omite si está vacío.
    marca: texto(f.marca) || (esNueva ? undefined : ''),
    categoria: texto(f.categoria) || (esNueva ? undefined : ''),
    temporada: texto(f.temporada) || (esNueva ? undefined : ''),
    // La API exige una URL válida, así que una foto vacía nunca se envía.
    foto_url: texto(f.foto_url) || undefined,
  };
  if (esNueva) cuerpo.codigo_barras = texto(f.codigo_barras);
  return cuerpo;
}

export const aFormulario = (p) => ({
  codigo_barras: p.codigo_barras,
  descripcion: p.descripcion,
  marca: p.marca || '',
  categoria: p.categoria || '',
  temporada: p.temporada || '',
  foto_url: p.foto_url || '',
  umbral_alerta: String(p.umbral_alerta ?? 2),
});
