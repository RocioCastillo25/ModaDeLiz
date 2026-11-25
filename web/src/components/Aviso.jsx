import { useLocation } from 'react-router-dom';

// Muestra el aviso de éxito que deja la pantalla anterior al navegar (navigate(ruta, { state: { aviso } })).
export default function Aviso() {
  const aviso = useLocation().state?.aviso;
  return aviso ? <p className="mensaje exito" role="status">{aviso}</p> : null;
}
