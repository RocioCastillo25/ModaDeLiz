import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth/AuthProvider';
import Layout from './components/Layout';
import { Cargando, ErrorMensaje } from './components/Estados';
import LoginDemoPage from './pages/LoginDemoPage';
import CatalogoPage from './pages/CatalogoPage';
import ExistenciasPage from './pages/ExistenciasPage';
import PrendaDetallePage from './pages/PrendaDetallePage';

export default function App() {
  const { cargando, error, demo, usuario } = useAuth();

  if (cargando) return <div className="centro"><Cargando texto="Iniciando sesión…" /></div>;
  if (error) return <div className="centro"><ErrorMensaje mensaje={error} onReintentar={() => window.location.reload()} /></div>;
  if (demo && !usuario) return <LoginDemoPage />;

  // La web es para administradora y gerentes; los empleados usan la app móvil.
  if (usuario.rol === 'empleado') {
    return (
      <div className="centro">
        <div className="tarjeta aviso">
          <h2>Usa la app móvil</h2>
          <p>Tu cuenta es de empleado. Consulta y descuenta existencias desde la app CheckLizz en tu celular.</p>
        </div>
      </div>
    );
  }

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<CatalogoPage />} />
        <Route path="prendas/:id" element={<PrendaDetallePage />} />
        <Route path="existencias" element={<ExistenciasPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
