import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthProvider';

const ROL_TEXTO = { administrador: 'Administradora', gerente: 'Gerente' };

export default function Layout() {
  const { usuario, logout, demo } = useAuth();

  return (
    <div className="app">
      <header className="barra">
        <div className="marca">
          <img src="/logo.png" alt="" width="40" height="40" />
          <span>CheckLizz</span>
          {demo && <span className="chip">Modo demo</span>}
        </div>
        <nav className="nav">
          <NavLink to="/" end>Catálogo</NavLink>
          <NavLink to="/existencias">Existencias</NavLink>
          <NavLink to="/carga">Carga inicial</NavLink>
        </nav>
        <div className="usuario">
          <span>{usuario.nombre} · {ROL_TEXTO[usuario.rol]}</span>
          <button className="btn secundario" onClick={logout}>Cerrar sesión</button>
        </div>
      </header>
      <main className="contenido">
        <Outlet />
      </main>
    </div>
  );
}
