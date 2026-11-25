import { useMemo, useState } from 'react';
import { useAuth } from '../auth/AuthProvider';
import { useCarga } from '../components/useCarga';
import { ErrorMensaje } from '../components/Estados';
import { MODOS, estaVacia, filaVacia, guardarFilas, normalizar, validarFilas } from './cargaInventario';

const sinAcentos = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').trim().toLowerCase();

// Carga inicial de inventario por filas: captura manual o pegado desde Excel.
export default function CargaInventarioPage() {
  const { repo, usuario } = useAuth();
  const esAdmin = usuario.rol === 'administrador';
  const sucursalFija = esAdmin ? null : usuario.sucursalId;
  const sucursalInicial = sucursalFija ?? '';

  const sucursales = useCarga(() => repo.listSucursales(), [repo]);
  const catalogo = useCarga(() => repo.buscarPrendas({}), [repo]);
  const porCodigo = useMemo(() => new Map((catalogo.datos || []).map((p) => [p.codigo_barras, p])), [catalogo.datos]);

  const [filas, setFilas] = useState(() => [filaVacia(sucursalInicial), filaVacia(sucursalInicial), filaVacia(sucursalInicial)]);
  const [errores, setErrores] = useState({});
  const [guardando, setGuardando] = useState(false);
  const [resumen, setResumen] = useState(null);
  const [modo, setModo] = useState(MODOS.sumar);

  const editar = (id, campo, valor) => {
    setFilas((fs) => fs.map((f) => (f.id === id ? { ...f, [campo]: valor, estado: null } : f)));
    setErrores((e) => ({ ...e, [id]: undefined }));
  };
  const agregar = (n = 1) => setFilas((fs) => [...fs, ...Array.from({ length: n }, () => filaVacia(sucursalInicial))]);
  const quitar = (id) => setFilas((fs) => (fs.length > 1 ? fs.filter((f) => f.id !== id) : fs));

  /** Pegar desde Excel: columnas código, sucursal, talla, color, cantidad (la sucursal es opcional). */
  function pegar(e, idFila) {
    const texto = e.clipboardData.getData('text');
    if (!texto.includes('\t') && !texto.includes('\n')) return; // pegado normal en una celda
    e.preventDefault();
    const nombres = new Map((sucursales.datos || []).map((s) => [sinAcentos(s.nombre), s.id]));
    const nuevas = texto.replace(/\r/g, '').split('\n').filter((l) => l.trim()).map((linea) => {
      const c = linea.split('\t');
      const conSucursal = c.length >= 5;
      const [codigo, suc, talla, color, cantidad] = conSucursal ? c : [c[0], '', c[1], c[2], c[3]];
      const idSucursal = sucursalFija ?? nombres.get(sinAcentos(suc || '')) ?? (/^\d+$/.test((suc || '').trim()) ? Number(suc) : '');
      return { ...filaVacia(), codigo: codigo || '', idSucursal: String(idSucursal), talla: talla || '', color: color || '', cantidad: cantidad || '' };
    });
    setFilas((fs) => {
      const i = fs.findIndex((f) => f.id === idFila);
      const despues = fs.slice(i + 1).filter((f) => !estaVacia(f));
      return [...fs.slice(0, i), ...nuevas, ...despues];
    });
    setResumen(null);
  }

  async function guardar() {
    setResumen(null);
    const pendientes = filas.filter((f) => !estaVacia(f) && f.estado?.tipo !== 'ok').map(normalizar);
    if (pendientes.length === 0) {
      setResumen({ tipo: 'falla', texto: 'No hay filas nuevas para guardar.' });
      return;
    }
    // Mostrar los valores normalizados (talla en mayúsculas, etc.)
    setFilas((fs) => fs.map((f) => pendientes.find((p) => p.id === f.id) || f));
    const v = validarFilas(pendientes, sucursalFija, modo);
    setErrores(v);
    if (Object.keys(v).length) {
      setResumen({ tipo: 'falla', texto: `Corrige ${Object.keys(v).length} fila(s) marcadas antes de guardar. No se guardó nada.` });
      return;
    }

    setGuardando(true);
    const r = await guardarFilas(repo, pendientes, (id, estado) =>
      setFilas((fs) => fs.map((f) => (f.id === id ? { ...f, estado } : f))), modo);
    setGuardando(false);
    setResumen(r.errores === 0
      ? { tipo: 'exito', texto: `Listo: se guardaron ${r.ok} fila(s).` }
      : { tipo: 'falla', texto: `Se guardaron ${r.ok} fila(s); ${r.errores} tuvieron error. Corrígelas y vuelve a guardar: las ya guardadas no se repiten.` });
  }

  const quitarGuardadas = () => {
    setFilas((fs) => {
      const quedan = fs.filter((f) => f.estado?.tipo !== 'ok');
      return quedan.length ? quedan : [filaVacia(sucursalInicial)];
    });
    setResumen(null);
  };

  if (sucursales.error || catalogo.error) {
    return <ErrorMensaje mensaje={sucursales.error || catalogo.error} onReintentar={() => { sucursales.recargar(); catalogo.recargar(); }} />;
  }

  const hayGuardadas = filas.some((f) => f.estado?.tipo === 'ok');

  return (
    <section>
      <div className="encabezado"><h1>Carga inicial de inventario</h1></div>

      <div className="tarjeta instrucciones">
        <p>Captura una fila por cada combinación de <strong>prenda, sucursal, talla y color</strong>.</p>
        <fieldset className="modo" disabled={guardando}>
          <legend>¿Qué hacer con la cantidad?</legend>
          <label className="check">
            <input type="radio" name="modo" checked={modo === MODOS.sumar} onChange={() => setModo(MODOS.sumar)} />
            <span><strong>Sumar</strong> a lo que ya hay <span className="texto-secundario">(si había 6 y capturas 10, quedan 16)</span></span>
          </label>
          <label className="check">
            <input type="radio" name="modo" checked={modo === MODOS.reemplazar} onChange={() => setModo(MODOS.reemplazar)} />
            <span><strong>Reemplazar</strong> lo que hay <span className="texto-secundario">(para corregir un conteo: si había 6 y capturas 10, quedan 10)</span></span>
          </label>
        </fieldset>
        <p className="texto-secundario">
          ¿Lo tienes en Excel? Copia las columnas <em>código, {esAdmin ? 'sucursal, ' : ''}talla, color, cantidad</em> y pégalas en la primera celda de código.
          {!esAdmin && ' Como gerente, todo se carga a tu sucursal.'}
        </p>
      </div>

      {resumen && <p className={`mensaje ${resumen.tipo}`} role="status">{resumen.texto}</p>}

      <div className="tabla-contenedor tarjeta">
        <table className="tabla-captura">
          <thead>
            <tr>
              <th>#</th><th>Código de barras</th><th>Prenda</th><th>Sucursal</th><th>Talla</th><th>Color</th><th className="num">Cantidad</th><th>Estado</th><th />
            </tr>
          </thead>
          <tbody>
            {filas.map((f, i) => {
              const prenda = porCodigo.get(f.codigo.trim());
              const guardada = f.estado?.tipo === 'ok';
              const error = errores[f.id] || (f.estado?.tipo === 'error' ? f.estado.mensaje : null);
              return (
                <tr key={f.id} className={guardada ? 'fila-ok' : error ? 'fila-error' : ''}>
                  <td className="texto-secundario">{i + 1}</td>
                  <td>
                    <input className="celda mono" value={f.codigo} list="codigos" aria-label={`Código, fila ${i + 1}`} disabled={guardada || guardando}
                      onChange={(e) => editar(f.id, 'codigo', e.target.value)} onPaste={(e) => pegar(e, f.id)} />
                  </td>
                  <td className="celda-prenda">{prenda ? prenda.descripcion : f.codigo.trim() ? <span className="texto-secundario">—</span> : ''}</td>
                  <td>
                    <select className="celda" value={f.idSucursal} aria-label={`Sucursal, fila ${i + 1}`} disabled={!esAdmin || guardada || guardando}
                      onChange={(e) => editar(f.id, 'idSucursal', e.target.value)}>
                      <option value="">Elegir…</option>
                      {sucursales.datos?.map((s) => <option key={s.id} value={s.id}>{s.nombre}</option>)}
                    </select>
                  </td>
                  <td><input className="celda corta" value={f.talla} aria-label={`Talla, fila ${i + 1}`} disabled={guardada || guardando}
                    onChange={(e) => editar(f.id, 'talla', e.target.value)} onPaste={(e) => pegar(e, f.id)} /></td>
                  <td><input className="celda" value={f.color} aria-label={`Color, fila ${i + 1}`} disabled={guardada || guardando}
                    onChange={(e) => editar(f.id, 'color', e.target.value)} /></td>
                  <td><input className="celda corta num" value={f.cantidad} inputMode="numeric" aria-label={`Cantidad, fila ${i + 1}`} disabled={guardada || guardando}
                    onChange={(e) => editar(f.id, 'cantidad', e.target.value)} /></td>
                  <td className="celda-estado">
                    {guardada && <span className="badge ok" title={f.estado.mensaje}>✓ {f.estado.mensaje.split(': ').pop()}</span>}
                    {error && <span className="error-campo">{error}</span>}
                  </td>
                  <td>
                    {!guardada && (
                      <button className="btn-icono" onClick={() => quitar(f.id)} disabled={guardando || filas.length === 1}
                        aria-label={`Quitar fila ${i + 1}`} title="Quitar fila">×</button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        <datalist id="codigos">
          {catalogo.datos?.map((p) => <option key={p.id} value={p.codigo_barras}>{p.descripcion}</option>)}
        </datalist>
      </div>

      <div className="acciones barra-acciones">
        <button className="btn secundario" onClick={() => agregar(1)} disabled={guardando}>+ Agregar fila</button>
        <button className="btn secundario" onClick={() => agregar(10)} disabled={guardando}>+ 10 filas</button>
        {hayGuardadas && <button className="btn secundario" onClick={quitarGuardadas} disabled={guardando}>Quitar las ya guardadas</button>}
        <span className="espaciador" />
        <button className="btn" onClick={guardar} disabled={guardando}>
          {guardando ? 'Guardando…' : modo === MODOS.sumar ? 'Sumar al inventario' : 'Reemplazar existencias'}
        </button>
      </div>
    </section>
  );
}
