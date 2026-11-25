import { useAuth } from '../auth/AuthProvider';

// Solo en modo demo (VITE_USE_MOCK=true). En modo real el inicio de sesión lo muestra Keycloak.
export default function LoginDemoPage() {
  const { entrarDemo } = useAuth();
  return (
    <div className="centro">
      <div className="tarjeta login">
        <img src="/logo.png" alt="Moda de Liz" width="96" height="96" />
        <h1>CheckLizz</h1>
        <p>Modo demo con datos simulados. Elige con qué rol entrar:</p>
        <button className="btn" onClick={() => entrarDemo('administrador')}>Entrar como administradora</button>
        <button className="btn secundario" onClick={() => entrarDemo('gerente')}>Entrar como gerente (Huauchinango)</button>
      </div>
    </div>
  );
}
