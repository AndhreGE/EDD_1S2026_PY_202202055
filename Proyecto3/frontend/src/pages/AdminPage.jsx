import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { adminApi } from '../api/adminApi'

export default function AdminPage() {
  const { usuario, logout } = useAuth()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [resumen, setResumen] = useState(null)
  const [usuarios, setUsuarios] = useState([])
  const [tipoConsulta, setTipoConsulta] = useState('TIPO-01')
  const [usuariosPorTipo, setUsuariosPorTipo] = useState([])
  const [hashResumen, setHashResumen] = useState(null)
  const [colabResumen, setColabResumen] = useState(null)

  async function cargarTodo() {
    setLoading(true)
    setError('')

    try {
      const [resResumen, resUsuarios, resHash, resColab, resTipo] = await Promise.all([
        adminApi.getResumen(),
        adminApi.getUsuarios(),
        adminApi.getHashResumen(),
        adminApi.getColaboracionResumen(),
        adminApi.getUsuariosPorTipo(tipoConsulta)
      ])

      setResumen(resResumen.resumen || null)
      setUsuarios(resUsuarios.usuarios || [])
      setHashResumen(resHash.resumen || null)
      setColabResumen(resColab.resumen || null)
      setUsuariosPorTipo(resTipo.usuarios || [])
    } catch (err) {
      setError(err.message || 'No se pudieron cargar datos de administración')
    } finally {
      setLoading(false)
    }
  }

  async function consultarTipo() {
    setError('')
    try {
      const res = await adminApi.getUsuariosPorTipo(tipoConsulta)
      setUsuariosPorTipo(res.usuarios || [])
    } catch (err) {
      setError(err.message || 'No se pudo consultar el tipo')
    }
  }

  useEffect(() => {
    cargarTodo()
  }, [])

  return (
    <div className="page-shell">
      <header className="topbar">
        <div>
          <h1>Panel Admin</h1>
          <p className="muted">{usuario?.nombre_completo || 'Administrador del Sistema'}</p>
        </div>
        <div className="topbar-actions">
          <button className="secondary" onClick={cargarTodo}>Recargar</button>
          <button onClick={logout}>Cerrar sesión</button>
        </div>
      </header>

      {error && <div className="error-box">{error}</div>}
      {loading && <div className="card">Cargando dashboard admin...</div>}

      {!loading && (
        <>
          <section className="cards-grid">
            <div className="card stat-card">
              <h3>Total usuarios</h3>
              <strong>{resumen?.usuarios ?? 0}</strong>
            </div>

            <div className="card stat-card">
              <h3>Total usuarios hash</h3>
              <strong>{hashResumen?.total_usuarios ?? 0}</strong>
            </div>

            <div className="card stat-card">
              <h3>Colaboraciones activas</h3>
              <strong>{colabResumen?.colaboraciones_activas ?? 0}</strong>
            </div>

            <div className="card stat-card">
              <h3>Usuarios aislados</h3>
              <strong>{colabResumen?.usuarios_aislados ?? 0}</strong>
            </div>
          </section>

          <section className="content-grid">
            <div className="card">
              <h2>Resumen hash</h2>
              <p>Buckets totales: {hashResumen?.buckets_totales ?? 0}</p>
              <p>Buckets utilizados: {hashResumen?.buckets_utilizados ?? 0}</p>
              <p>Factor de carga: {hashResumen?.factor_carga ?? '0.00'}</p>
              <p>Total colisiones: {hashResumen?.total_colisiones ?? 0}</p>
            </div>

            <div className="card">
              <h2>Resumen colaboración</h2>
              <p>Usuarios: {colabResumen?.usuarios ?? 0}</p>
              <p>Sin departamento: {colabResumen?.sin_departamento ?? 0}</p>
              <p>Solicitudes pendientes: {colabResumen?.solicitudes_pendientes ?? 0}</p>
              <p>Solicitudes rechazadas: {colabResumen?.solicitudes_rechazadas ?? 0}</p>
            </div>
          </section>

          <section className="card">
            <h2>Consulta por tipo</h2>
            <div className="toolbar">
              <select value={tipoConsulta} onChange={(e) => setTipoConsulta(e.target.value)}>
                <option value="TIPO-01">TIPO-01</option>
                <option value="TIPO-02">TIPO-02</option>
                <option value="TIPO-03">TIPO-03</option>
                <option value="TIPO-04">TIPO-04</option>
                <option value="TIPO-05">TIPO-05</option>
              </select>
              <button onClick={consultarTipo}>Consultar</button>
            </div>

            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>No. colegio</th>
                    <th>Nombre</th>
                    <th>Tipo</th>
                    <th>Departamento</th>
                    <th>Especialidad</th>
                  </tr>
                </thead>
                <tbody>
                  {usuariosPorTipo.map((u) => (
                    <tr key={u.numero_colegio}>
                      <td>{u.numero_colegio}</td>
                      <td>{u.nombre_completo}</td>
                      <td>{u.tipo_usuario}</td>
                      <td>{u.departamento}</td>
                      <td>{u.especialidad}</td>
                    </tr>
                  ))}
                  {usuariosPorTipo.length === 0 && (
                    <tr>
                      <td colSpan="5">Sin usuarios para este tipo.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </section>

          <section className="card">
            <h2>Todos los usuarios</h2>
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>No. colegio</th>
                    <th>Nombre</th>
                    <th>Tipo</th>
                    <th>Departamento</th>
                    <th>Especialidad</th>
                  </tr>
                </thead>
                <tbody>
                  {usuarios.map((u) => (
                    <tr key={u.numero_colegio}>
                      <td>{u.numero_colegio}</td>
                      <td>{u.nombre_completo}</td>
                      <td>{u.tipo_usuario}</td>
                      <td>{u.departamento}</td>
                      <td>{u.especialidad}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </>
      )}
    </div>
  )
}