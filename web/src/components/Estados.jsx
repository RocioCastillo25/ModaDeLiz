// Los tres estados visibles de toda pantalla que consulta datos: cargando, vacío y error.

export function Cargando({ texto = 'Cargando…' }) {
  return <p className="estado" role="status"><span className="spinner" aria-hidden="true" /> {texto}</p>;
}

export function Vacio({ texto }) {
  return <p className="estado vacio">{texto}</p>;
}

export function ErrorMensaje({ mensaje, onReintentar }) {
  return (
    <div className="estado error" role="alert">
      <p>{mensaje}</p>
      {onReintentar && <button className="btn secundario" onClick={onReintentar}>Reintentar</button>}
    </div>
  );
}
