import { useState } from 'react'
import { useAuth } from '../context/AuthContext'

export default function LoginPage() {
  const { login } = useAuth()

  const [usuario, setUsuario] = useState('')
  const [clave, setClave] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(usuario, clave)
    } catch (err) {
      setError(err.message || 'No se pudo iniciar sesión')
    } finally {
      setLoading(false)
    }
  }

  function cargarAdminDemo() {
    setUsuario('admin')
    setClave('admin123')
  }

  function cargarUsuarioDemo() {
    setUsuario('COL-10001')
    setClave('medgen2026A')
  }

  return (
    <div className="screen-center">
      <div className="card login-card">
        <h1>EDD MedTrack</h1>
        <p className="muted">
          Inicia sesión contra el backend Perl + Mojolicious.
        </p>

        <form onSubmit={handleSubmit} className="form-grid">
          <label>
            Usuario
            <input
              type="text"
              value={usuario}
              onChange={(e) => setUsuario(e.target.value)}
              placeholder="admin o COL-10001"
            />
          </label>

          <label>
            Clave
            <input
              type="password"
              value={clave}
              onChange={(e) => setClave(e.target.value)}
              placeholder="Tu contraseña"
            />
          </label>

          {error && <div className="error-box">{error}</div>}

          <button type="submit" disabled={loading}>
            {loading ? 'Ingresando...' : 'Iniciar sesión'}
          </button>
        </form>

        <div className="demo-buttons">
          <button type="button" className="secondary" onClick={cargarAdminDemo}>
            Cargar admin demo
          </button>
          <button type="button" className="secondary" onClick={cargarUsuarioDemo}>
            Cargar usuario demo
          </button>
        </div>
      </div>
    </div>
  )
}