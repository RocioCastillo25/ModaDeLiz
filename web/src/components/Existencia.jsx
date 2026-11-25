// Indicador de existencia: el estado se distingue con texto, no solo con color.
export default function Existencia({ cantidad, umbral = 2 }) {
  if (cantidad === 0) return <span className="badge agotado">{cantidad} · Agotado</span>;
  if (cantidad <= umbral) return <span className="badge bajo">{cantidad} · Bajo</span>;
  return <span className="badge ok">{cantidad}</span>;
}
