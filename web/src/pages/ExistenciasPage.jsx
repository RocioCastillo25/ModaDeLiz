import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../auth/AuthProvider';
import { useCarga } from '../components/useCarga';
import { Cargando, ErrorMensaje, Vacio } from '../components/Estados';
import Existencia from '../components/Existencia';

// Existencias detalladas por prenda + talla + color. Un gerente solo ve su sucursal (la API lo fuerza).
export default function ExistenciasPage() {
  const { repo, usuario } = useAuth();
  const esAdmin = usuario.rol === 'administrador';
  const [sucursalId, setSucursalId] = useState(esAdmin ? '' : String(usuario.sucursalId));
  const [bajoUmbral, setBajoUmbral] = useState(false);

  const sucursales = useCarga(() => repo.listSucursales(), [repo]);
  const filas = useCarga(
    () => repo.listInventario({ sucursalId, bajoUmbral: bajoUmbral ? 'true' : undefined }),
    [repo, sucursalId, bajoUmbral]
  );

  return (
    <section>
      <div className="encabezado">
        <h1>Existencias por sucursal</h1>
      </div>

      <div className="tarjeta filtros">
        <label className="campo">
          <span>Sucursal</span>
          <select value={sucursalId} onChange={(e) => setSucursalId(e.target.value)} disabled={!esAdmin}>
            {esAdmin && <option value="">Todas</option>}
            {sucursales.datos?.map((s) => <option key={s.id} value={s.id}>{s.nombre}</option>)}
          </select>
        </label>
        <label className="check">
          <input type="checkbox" checked={bajoUmbral} onChange={(e) => setBajoUmbral(e.target.checked)} />
          Solo stock bajo o agotado
        </label>
      </div>

      {filas.cargando && <Cargando />}
      {filas.error && <ErrorMensaje mensaje={filas.error} onReintentar={filas.recargar} />}
      {!filas.cargando && !filas.error && filas.datos.length === 0 && <Vacio texto="No hay existencias con estos filtros." />}
      {!filas.cargando && !filas.error && filas.datos.length > 0 && (
        <div className="tabla-contenedor tarjeta">
          <table>
            <thead>
              <tr><th>Código</th><th>Prenda</th><th>Sucursal</th><th>Talla</th><th>Color</th><th className="num">Piezas</th></tr>
            </thead>
            <tbody>
              {filas.datos.map((f) => (
                <tr key={f.id}>
                  <td className="mono">{f.codigo_barras}</td>
                  <td><Link to={`/prendas/${f.id_prenda}`}>{f.descripcion}</Link></td>
                  <td>{f.sucursal}</td>
                  <td>{f.talla}</td>
                  <td>{f.color}</td>
                  <td className="num"><Existencia cantidad={f.cantidad} umbral={f.umbral_alerta} /></td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="pie">{filas.datos.length} registro(s) · {filas.datos.reduce((s, f) => s + f.cantidad, 0)} pieza(s)</p>
        </div>
      )}
    </section>
  );
}
