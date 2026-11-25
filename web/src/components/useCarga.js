import { useCallback, useEffect, useState } from 'react';

/**
 * Ejecuta una consulta asíncrona y expone su estado (cargando, datos, error) y una función para recargar.
 * `deps` controla cuándo se vuelve a consultar; `esperaMs` agrupa cambios rápidos (p. ej. al teclear).
 */
export function useCarga(consulta, deps, esperaMs = 0) {
  const [estado, setEstado] = useState({ cargando: true, datos: null, error: null });
  const [version, setVersion] = useState(0);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const fn = useCallback(consulta, deps);

  useEffect(() => {
    let vigente = true;
    setEstado((e) => ({ ...e, cargando: true, error: null }));
    const t = setTimeout(() => {
      fn()
        .then((datos) => vigente && setEstado({ cargando: false, datos, error: null }))
        .catch((err) => vigente && setEstado({ cargando: false, datos: null, error: err.message }));
    }, esperaMs);
    return () => { vigente = false; clearTimeout(t); };
  }, [fn, version, esperaMs]);

  return { ...estado, recargar: () => setVersion((v) => v + 1) };
}
