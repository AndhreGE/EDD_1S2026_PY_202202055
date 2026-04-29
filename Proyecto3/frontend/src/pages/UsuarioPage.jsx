import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { usuarioApi } from '../api/usuarioApi'

export default function UsuarioPage() {
  const { usuario, logout } = useAuth()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const [perfil, setPerfil] = useState(null)
  const [colaboradores, setColaboradores] = useState([])
  const [sugerencias, setSugerencias] = useState([])
  const [solicitudes, setSolicitudes] = useState({ recibidas: [], enviadas: [] })
  const [conversaciones, setConversaciones] = useState([])
  const [chatActivo, setChatActivo] = useState(null)
  const [mensajes, setMensajes] = useState([])
  const [nuevoMensaje, setNuevoMensaje] = useState('')

  async function cargarDashboard() {
    setLoading(true)
    setError('')

    try {
      const [resPerfil, resColab, resSug, resSol, resConv] = await Promise.all([
        usuarioApi.getPerfil(),
        usuarioApi.getColaboradores(),
        usuarioApi.getSugerencias(),
        usuarioApi.getSolicitudes(),
        usuarioApi.getConversaciones()
      ])

      setPerfil(resPerfil)
      setColaboradores(resColab.colaboradores || [])
      setSugerencias(resSug.sugerencias || [])
      setSolicitudes({
        recibidas: resSol.recibidas || [],
        enviadas: resSol.enviadas || []
      })

      const convs = resConv.conversaciones || []
      setConversaciones(convs)

      if (convs.length > 0) {
        await abrirChat(convs[0].con_usuario)
      } else {
        setChatActivo(null)
        setMensajes([])
      }
    } catch (err) {
      setError(err.message || 'No se pudo cargar el dashboard del usuario')
    } finally {
      setLoading(false)
    }
  }

  async function abrirChat(otroId) {
    try {
      const res = await usuarioApi.getChat(otroId)
      setChatActivo(otroId)
      setMensajes(res.mensajes || [])
    } catch (err) {
      setError(err.message || 'No se pudo abrir la conversación')
    }
  }

  async function enviarMensaje() {
    if (!chatActivo || !nuevoMensaje.trim()) return

    try {
      await usuarioApi.enviarMensaje(chatActivo, nuevoMensaje.trim())
      setNuevoMensaje('')
      await abrirChat(chatActivo)

      const resConv = await usuarioApi.getConversaciones()
      setConversaciones(resConv.conversaciones || [])
    } catch (err) {
      setError(err.message || 'No se pudo enviar el mensaje')
    }
  }

  async function aceptarSolicitud(solicitante) {
    try {
      await usuarioApi.aceptarSolicitud(solicitante)
      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo aceptar la solicitud')
    }
  }

  async function rechazarSolicitud(solicitante) {
    try {
      await usuarioApi.rechazarSolicitud(solicitante)
      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo rechazar la solicitud')
    }
  }

  async function enviarSolicitud(destino) {
    try {
      await usuarioApi.enviarSolicitud(destino)
      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo enviar la solicitud')
    }
  }

  useEffect(() => {
    cargarDashboard()
  }, [])

  return (
    <div className="page-shell">
      <header className="topbar">
        <div>
          <h1>Panel Usuario</h1>
          <p className="muted">{usuario?.nombre_completo}</p>
        </div>
        <div className="topbar-actions">
          <button className="secondary" onClick={cargarDashboard}>Recargar</button>
          <button onClick={logout}>Cerrar sesión</button>
        </div>
      </header>

      {error && <div className="error-box">{error}</div>}
      {loading && <div className="card">Cargando dashboard usuario...</div>}

      {!loading && (
        <>
          <section className="cards-grid">
            <div className="card stat-card">
              <h3>Mi tipo</h3>
              <strong>{perfil?.usuario?.tipo_usuario || '-'}</strong>
            </div>
            <div className="card stat-card">
              <h3>Mi departamento</h3>
              <strong>{perfil?.usuario?.departamento || '-'}</strong>
            </div>
            <div className="card stat-card">
              <h3>Colaboradores</h3>
              <strong>{colaboradores.length}</strong>
            </div>
            <div className="card stat-card">
              <h3>Conversaciones</h3>
              <strong>{conversaciones.length}</strong>
            </div>
          </section>

          <section className="content-grid">
            <div className="card">
              <h2>Mi perfil</h2>
              <p><strong>Nombre:</strong> {perfil?.usuario?.nombre_completo}</p>
              <p><strong>No. colegio:</strong> {perfil?.usuario?.numero_colegio}</p>
              <p><strong>Tipo:</strong> {perfil?.usuario?.tipo_usuario}</p>
              <p><strong>Departamento:</strong> {perfil?.usuario?.departamento}</p>
              <p><strong>Especialidad:</strong> {perfil?.usuario?.especialidad}</p>
            </div>

            <div className="card">
              <h2>Permisos</h2>
              <p><strong>Consulta:</strong> {(perfil?.permisos?.consulta || []).join(', ') || 'Sin permisos'}</p>
              <p><strong>Solicitud:</strong> {(perfil?.permisos?.solicitud || []).join(', ') || 'Sin permisos'}</p>
            </div>
          </section>

          <section className="content-grid">
            <div className="card">
              <h2>Colaboradores</h2>
              {colaboradores.length === 0 && <p className="muted">No tienes colaboradores.</p>}
              {colaboradores.map((c) => (
                <div key={c.numero_colegio} className="list-item">
                  <div>
                    <strong>{c.nombre_completo}</strong>
                    <p>{c.numero_colegio} · {c.tipo_usuario} · {c.departamento}</p>
                  </div>
                  <button onClick={() => abrirChat(c.numero_colegio)}>Abrir chat</button>
                </div>
              ))}
            </div>

            <div className="card">
              <h2>Sugerencias</h2>
              {sugerencias.length === 0 && <p className="muted">No hay sugerencias.</p>}
              {sugerencias.map((s) => (
                <div key={s.numero_colegio} className="list-item">
                  <div>
                    <strong>{s.nombre_completo}</strong>
                    <p>{s.numero_colegio} · {s.tipo_usuario} · {s.departamento}</p>
                    <p>Colaboradores en común: {s.colaboradores_en_comun}</p>
                  </div>
                  <button onClick={() => enviarSolicitud(s.numero_colegio)}>
                    Enviar solicitud
                  </button>
                </div>
              ))}
            </div>
          </section>

          <section className="content-grid">
            <div className="card">
              <h2>Solicitudes recibidas</h2>
              {solicitudes.recibidas.length === 0 && <p className="muted">Sin solicitudes recibidas.</p>}
              {solicitudes.recibidas.map((s, idx) => (
                <div key={`${s.solicitante}-${idx}`} className="list-item">
                  <div>
                    <strong>{s.solicitante}</strong>
                    <p>Estado: {s.estado}</p>
                  </div>
                  <div className="inline-buttons">
                    <button onClick={() => aceptarSolicitud(s.solicitante)}>Aceptar</button>
                    <button className="danger" onClick={() => rechazarSolicitud(s.solicitante)}>Rechazar</button>
                  </div>
                </div>
              ))}
            </div>

            <div className="card">
              <h2>Solicitudes enviadas</h2>
              {solicitudes.enviadas.length === 0 && <p className="muted">Sin solicitudes enviadas.</p>}
              {solicitudes.enviadas.map((s, idx) => (
                <div key={`${s.receptor}-${idx}`} className="list-item">
                  <div>
                    <strong>{s.receptor}</strong>
                    <p>Estado: {s.estado}</p>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="chat-layout">
            <div className="card">
              <h2>Conversaciones</h2>
              {conversaciones.length === 0 && <p className="muted">Sin conversaciones.</p>}
              {conversaciones.map((c) => (
                <div
                  key={c.con_usuario}
                  className={`list-item clickable ${chatActivo === c.con_usuario ? 'active' : ''}`}
                  onClick={() => abrirChat(c.con_usuario)}
                >
                  <div>
                    <strong>{c.con_usuario}</strong>
                    <p>{c.ultimo_mensaje}</p>
                  </div>
                  <span className="small-badge">{c.cantidad_mensajes}</span>
                </div>
              ))}
            </div>

            <div className="card chat-card">
              <h2>Chat {chatActivo ? `con ${chatActivo}` : ''}</h2>

              <div className="messages-box">
                {mensajes.length === 0 && <p className="muted">Selecciona una conversación.</p>}
                {mensajes.map((m) => (
                  <div
                    key={m.id}
                    className={`message-bubble ${m.de === usuario?.numero_colegio ? 'mine' : 'theirs'}`}
                  >
                    <div className="message-meta">
                      <strong>{m.de}</strong>
                      <span>{m.timestamp}</span>
                    </div>
                    <div>{m.texto}</div>
                  </div>
                ))}
              </div>

              <div className="chat-input-row">
                <input
                  type="text"
                  value={nuevoMensaje}
                  onChange={(e) => setNuevoMensaje(e.target.value)}
                  placeholder="Escribe un mensaje..."
                  disabled={!chatActivo}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      enviarMensaje()
                    }
                  }}
                />
                <button onClick={enviarMensaje} disabled={!chatActivo || !nuevoMensaje.trim()}>
                  Enviar
                </button>
              </div>
            </div>
          </section>
        </>
      )}
    </div>
  )
}