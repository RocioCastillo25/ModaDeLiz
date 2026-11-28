import { Link, useParams } from 'react-router-dom';
import { useRepo } from '../auth/AuthProvider';
import { useCarga } from '../components/useCarga';
import { Cargando, ErrorMensaje } from '../components/Estados';
import Existencia from '../components/Existencia';
import Aviso from '../components/Aviso';

export default function PrendaDetallePage() {
  const { id } = useParams();
  const repo = useRepo();
  const prenda = useCarga(() => repo.getPrenda(id), [repo, id]);
  const sucursales = useCarga(() => repo.listSucursales(), [repo]);

  if (prenda.cargando || sucursales.cargando) return <Cargando />;
  if (prenda.error || sucursales.error) {
    return <ErrorMensaje mensaje={prenda.error || sucursales.error} onReintentar={() => { prenda.recargar(); sucursales.recargar(); }} />;
  }

  const p = prenda.datos;
  const total = p.existencias.reduce((s, e) => s + e.cantidad, 0);

  return (
    <section>
      <Link to="/" className="volver">← Volver al catálogo</Link>
      <div className="encabezado">
        <h1>{p.descripcion}</h1>
        <Link to={`/prendas/${p.id}/editar`} className="btn secundario">Editar</Link>
      </div>
      <Aviso />

      <div className="ficha">
        <div className="tarjeta datos">
          {p.foto_url ? <img src={p.foto_url} alt={p.descripcion} className="foto" /> : <div className="foto sin-foto">Sin foto</div>}
          <dl>
            <dt>Código de barras</dt><dd className="mono">{p.codigo_barras}</dd>
            <dt>Marca</dt><dd>{p.marca || '—'}</dd>
            <dt>Categoría</dt><dd>{p.categoria || '—'}</dd>
            <dt>Temporada</dt><dd>{p.temporada || '—'}</dd>
            <dt>Alerta de stock bajo</dt><dd>{p.umbral_alerta} pieza(s) o menos</dd>
            <dt>Existencia total</dt><dd><Existencia cantidad={total} umbral={p.umbral_alerta} /></dd>
          </dl>
        </div>

        <div className="sucursales">
          {sucursales.datos.map((s) => {
            const filas = p.existencias.filter((e) => e.id_sucursal === s.id);
            return (
              <div key={s.id} className="tarjeta sucursal">
                <h3>{s.nombre}</h3>
                {filas.length === 0 ? (
                  <p className="texto-secundario">Sin registro en esta sucursal</p>
                ) : (
                  <table>
                    <thead><tr><th>Talla</th><th>Color</th><th className="num">Piezas</th></tr></thead>
                    <tbody>
                      {filas.map((e) => (
                        <tr key={e.id}>
                          <td>{e.talla}</td><td>{e.color}</td>
                          <td className="num"><Existencia cantidad={e.cantidad} umbral={p.umbral_alerta} /></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
