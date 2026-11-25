import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import Aviso from '../components/Aviso';
import { useRepo } from '../auth/AuthProvider';
import { useCarga } from '../components/useCarga';
import { Cargando, ErrorMensaje, Vacio } from '../components/Estados';
import Existencia from '../components/Existencia';

const FILTROS_VACIOS = { q: '', categoria: '', talla: '', color: '', sucursalId: '' };

export default function CatalogoPage() {
  const repo = useRepo();
  const navigate = useNavigate();
  const [filtros, setFiltros] = useState(FILTROS_VACIOS);
  const sucursales = useCarga(() => repo.listSucursales(), [repo]);
  const prendas = useCarga(() => repo.buscarPrendas(filtros), [repo, filtros], 300);

  const cambiar = (campo) => (e) => setFiltros((f) => ({ ...f, [campo]: e.target.value }));
  const hayFiltros = Object.values(filtros).some((v) => v.trim() !== '');

  return (
    <section>
      <div className="encabezado">
        <h1>Catálogo de prendas</h1>
        <Link to="/prendas/nueva" className="btn">+ Nueva prenda</Link>
      </div>
      <Aviso />

      <div className="tarjeta filtros" role="search">
        <label className="campo ancho">
          <span>Buscar</span>
          <input type="search" placeholder="Nombre o marca…" value={filtros.q} onChange={cambiar('q')} />
        </label>
        <label className="campo">
          <span>Categoría</span>
          <input value={filtros.categoria} onChange={cambiar('categoria')} placeholder="Blusas…" />
        </label>
        <label className="campo">
          <span>Talla</span>
          <input value={filtros.talla} onChange={cambiar('talla')} placeholder="M, 28…" />
        </label>
        <label className="campo">
          <span>Color</span>
          <input value={filtros.color} onChange={cambiar('color')} placeholder="Rosa…" />
        </label>
        <label className="campo">
          <span>Sucursal</span>
          <select value={filtros.sucursalId} onChange={cambiar('sucursalId')}>
            <option value="">Todas</option>
            {sucursales.datos?.map((s) => <option key={s.id} value={s.id}>{s.nombre}</option>)}
          </select>
        </label>
        {hayFiltros && <button className="btn secundario" onClick={() => setFiltros(FILTROS_VACIOS)}>Limpiar</button>}
      </div>

      {prendas.cargando && <Cargando />}
      {prendas.error && <ErrorMensaje mensaje={prendas.error} onReintentar={prendas.recargar} />}
      {!prendas.cargando && !prendas.error && prendas.datos.length === 0 && (
        <Vacio texto="No hay prendas que coincidan con la búsqueda." />
      )}
      {!prendas.cargando && !prendas.error && prendas.datos.length > 0 && (
        <div className="tabla-contenedor tarjeta">
          <table>
            <thead>
              <tr>
                <th>Código</th><th>Descripción</th><th>Marca</th><th>Categoría</th><th>Temporada</th><th className="num">Existencia total</th>
              </tr>
            </thead>
            <tbody>
              {prendas.datos.map((p) => (
                <tr key={p.id} className="clic" tabIndex={0}
                  onClick={() => navigate(`/prendas/${p.id}`)}
                  onKeyDown={(e) => e.key === 'Enter' && navigate(`/prendas/${p.id}`)}>
                  <td className="mono">{p.codigo_barras}</td>
                  <td>{p.descripcion}</td>
                  <td>{p.marca || '—'}</td>
                  <td>{p.categoria || '—'}</td>
                  <td>{p.temporada || '—'}</td>
                  <td className="num"><Existencia cantidad={p.existencia_total} umbral={p.umbral_alerta} /></td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="pie">{prendas.datos.length} prenda(s)</p>
        </div>
      )}
    </section>
  );
}
