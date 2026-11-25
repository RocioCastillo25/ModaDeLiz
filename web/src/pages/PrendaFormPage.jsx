import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { useRepo } from '../auth/AuthProvider';
import { Cargando, ErrorMensaje } from '../components/Estados';
import { PRENDA_VACIA, aCuerpo, aFormulario, validarPrenda } from './prendaValidacion';

const TEMPORADAS = ['Primavera-Verano', 'Otono-Invierno', 'Todo el anio'];

// Alta (/prendas/nueva) y edición (/prendas/:id/editar) de prendas en un solo formulario.
export default function PrendaFormPage() {
  const { id } = useParams();
  const esNueva = !id;
  const repo = useRepo();
  const navigate = useNavigate();

  const [form, setForm] = useState(PRENDA_VACIA);
  const [errores, setErrores] = useState({});
  const [carga, setCarga] = useState({ cargando: !esNueva, error: null });
  const [enviando, setEnviando] = useState(false);
  const [errorEnvio, setErrorEnvio] = useState(null);
  const [confirmarBaja, setConfirmarBaja] = useState(false);

  useEffect(() => {
    if (esNueva) return;
    repo.getPrenda(id)
      .then((p) => { setForm(aFormulario(p)); setCarga({ cargando: false, error: null }); })
      .catch((e) => setCarga({ cargando: false, error: e.message }));
  }, [repo, id, esNueva]);

  const cambiar = (campo) => (e) => {
    setForm((f) => ({ ...f, [campo]: e.target.value }));
    setErrores((er) => ({ ...er, [campo]: undefined }));
  };

  async function guardar(e) {
    e.preventDefault();
    setErrorEnvio(null);
    const v = validarPrenda(form, esNueva);
    setErrores(v);
    if (Object.keys(v).length) return;

    setEnviando(true);
    try {
      const cuerpo = aCuerpo(form, esNueva);
      const prenda = esNueva ? await repo.crearPrenda(cuerpo) : await repo.actualizarPrenda(id, cuerpo);
      navigate(`/prendas/${prenda.id}`, { state: { aviso: esNueva ? 'Prenda dada de alta.' : 'Cambios guardados.' } });
    } catch (err) {
      if (err.code === 'CODIGO_DUPLICADO' || err.code === 'DUPLICADO') {
        setErrores({ codigo_barras: 'Ya existe una prenda con este código de barras.' });
      } else if (err.detalles?.length) {
        setErrores(Object.fromEntries(err.detalles.map((d) => [d.campo, 'Valor no válido.'])));
        setErrorEnvio('Revisa los campos marcados.');
      } else {
        setErrorEnvio(err.message);
      }
    } finally {
      setEnviando(false);
    }
  }

  async function desactivar() {
    setEnviando(true);
    try {
      await repo.desactivarPrenda(id);
      navigate('/', { state: { aviso: 'La prenda se desactivó y ya no aparece en el catálogo.' } });
    } catch (err) {
      setErrorEnvio(err.message);
      setEnviando(false);
    }
  }

  if (carga.cargando) return <Cargando />;
  if (carga.error) return <ErrorMensaje mensaje={carga.error} />;

  const campo = (nombre, etiqueta, props = {}) => (
    <label className="campo">
      <span>{etiqueta}</span>
      <input value={form[nombre]} onChange={cambiar(nombre)} aria-invalid={!!errores[nombre]} {...props} />
      {errores[nombre] && <span className="error-campo">{errores[nombre]}</span>}
    </label>
  );

  return (
    <section className="formulario-pagina">
      <Link to={esNueva ? '/' : `/prendas/${id}`} className="volver">← {esNueva ? 'Volver al catálogo' : 'Volver a la ficha'}</Link>
      <div className="encabezado"><h1>{esNueva ? 'Nueva prenda' : 'Editar prenda'}</h1></div>

      {errorEnvio && <p className="mensaje falla" role="alert">{errorEnvio}</p>}

      <form className="tarjeta formulario" onSubmit={guardar} noValidate>
        {campo('codigo_barras', 'Código de barras *', {
          disabled: !esNueva, autoFocus: esNueva, inputMode: 'numeric', placeholder: '7501000000011',
        })}
        {!esNueva && <p className="ayuda-form">El código de barras no se puede cambiar después del alta.</p>}
        {campo('descripcion', 'Descripción *', { placeholder: 'Blusa manga corta lisa', autoFocus: !esNueva })}
        <div className="fila">
          {campo('marca', 'Marca', { placeholder: 'Lizz' })}
          {campo('categoria', 'Categoría', { placeholder: 'Blusas', list: 'categorias' })}
        </div>
        <datalist id="categorias">
          {['Blusas', 'Pantalones', 'Vestidos', 'Sueteres', 'Faldas', 'Chamarras'].map((c) => <option key={c} value={c} />)}
        </datalist>
        <div className="fila">
          <label className="campo">
            <span>Temporada</span>
            <select value={form.temporada} onChange={cambiar('temporada')}>
              <option value="">Sin temporada</option>
              {TEMPORADAS.map((t) => <option key={t} value={t}>{t}</option>)}
              {form.temporada && !TEMPORADAS.includes(form.temporada) && <option value={form.temporada}>{form.temporada}</option>}
            </select>
          </label>
          {campo('umbral_alerta', 'Alerta de stock bajo (piezas)', { type: 'number', min: 0, step: 1 })}
        </div>
        {campo('foto_url', 'Foto (dirección web)', { type: 'url', placeholder: 'https://…' })}
        {form.foto_url && !errores.foto_url && <img src={form.foto_url} alt="Vista previa" className="vista-previa" />}

        <div className="acciones">
          <button className="btn" type="submit" disabled={enviando}>
            {enviando ? 'Guardando…' : esNueva ? 'Dar de alta' : 'Guardar cambios'}
          </button>
          <Link to={esNueva ? '/' : `/prendas/${id}`} className="btn secundario">Cancelar</Link>
        </div>
      </form>

      {!esNueva && (
        <div className="tarjeta zona-baja">
          <h3>Desactivar prenda</h3>
          <p className="texto-secundario">Deja de aparecer en el catálogo y en la app. Su historial de inventario se conserva.</p>
          {!confirmarBaja ? (
            <button className="btn peligro" onClick={() => setConfirmarBaja(true)} disabled={enviando}>Desactivar</button>
          ) : (
            <div className="acciones">
              <span>¿Seguro que quieres desactivarla?</span>
              <button className="btn peligro" onClick={desactivar} disabled={enviando}>Sí, desactivar</button>
              <button className="btn secundario" onClick={() => setConfirmarBaja(false)} disabled={enviando}>No</button>
            </div>
          )}
        </div>
      )}
    </section>
  );
}
