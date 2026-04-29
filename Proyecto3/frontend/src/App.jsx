import { useAuth } from './context/AuthContext'
import LoginPage from './pages/LoginPage'
import AdminPage from './pages/AdminPage'
import UsuarioPage from './pages/UsuarioPage'

export default function App() {
  const { loading, autenticado, rol } = useAuth()

  if (loading) {
    return (
      <div className="screen-center">
        <div className="card loading-card">
          <h2>Cargando sesión...</h2>
          <p>Conectando con el backend.</p>
        </div>
      </div>
    )
  }

  if (!autenticado) {
    return <LoginPage />
  }

  if (rol === 'ADMIN') {
    return <AdminPage />
  }

  return <UsuarioPage />
}