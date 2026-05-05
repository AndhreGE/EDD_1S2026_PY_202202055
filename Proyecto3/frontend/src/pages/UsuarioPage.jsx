import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { usuarioApi } from '../api/usuarioApi'

function StatCard({ title, value, subtitle }) {
  return (
    <div className="card stat-card">
      <span className="eyebrow">{title}</span>
      <strong>{value}</strong>
      {subtitle ? <p className="muted compact">{subtitle}</p> : null}
    </div>
  )
}

function EmptyState({ text }) {
  return <p className="empty-state">{text}</p>
}

export default function UsuarioPage() {
  const { usuario, logout } = useAuth()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [infoMsg, setInfoMsg] = useState('')

  const [perfil, setPerfil] = useState(null)
  const [colaboradores, setColaboradores] = useState([])
  const [sugerencias, setSugerencias] = useState([])
  const [solicitudes, setSolicitudes] = useState({ recibidas: [], enviadas: [] })
  const [conversaciones, setConversaciones] = useState([])
  const [chatActivo, setChatActivo] = useState(null)
  const [mensajes, setMensajes] = useState([])
  const [nuevoMensaje, setNuevoMensaje] = useState('')

  const [insumos, setInsumos] = useState([])
  const [misSolicitudes, setMisSolicitudes] = useState([])
  const [lzwInfo, setLzwInfo] = useState(null)

  const [formSolicitud, setFormSolicitud] = useState({
    codigo: '',
    cantidad: 1,
    observacion: ''
  })

  async function cargarDashboard() {
    setLoading(true)
    setError('')

    try {
      const [
        resPerfil,
        resColab,
        resSug,
        resSol,
        resConv,
        resInsumos,
        resMisSolicitudes,
        resLzw
      ] = await Promise.all([
        usuarioApi.getPerfil(),
        usuarioApi.getColaboradores(),
        usuarioApi.getSugerencias(),
        usuarioApi.getSolicitudes(),
        usuarioApi.getConversaciones(),
        usuarioApi.getInsumosSolicitables(),
        usuarioApi.getMisSolicitudesReabastecimiento(),
        usuarioApi.getEstadoLZW()
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

      const listaInsumos = resInsumos.insumos || []
      setInsumos(listaInsumos)

      const listaSolicitudes = resMisSolicitudes.solicitudes || []
      setMisSolicitudes(listaSolicitudes)

      setLzwInfo(resLzw || null)

      setFormSolicitud((prev) => ({
        ...prev,
        codigo: prev.codigo || (listaInsumos[0]?.codigo || '')
      }))

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

      const [resConv, resLzw] = await Promise.all([
        usuarioApi.getConversaciones(),
        usuarioApi.getEstadoLZW()
      ])

      setConversaciones(resConv.conversaciones || [])
      setLzwInfo(resLzw || null)
      setInfoMsg('Mensaje enviado correctamente')
    } catch (err) {
      setError(err.message || 'No se pudo enviar el mensaje')
    }
  }

  async function aceptarSolicitud(solicitante) {
    try {
      await usuarioApi.aceptarSolicitud(solicitante)
      setInfoMsg('Solicitud aceptada correctamente')
      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo aceptar la solicitud')
    }
  }

  async function rechazarSolicitud(solicitante) {
    try {
      await usuarioApi.rechazarSolicitud(solicitante)
      setInfoMsg('Solicitud rechazada correctamente')
      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo rechazar la solicitud')
    }
  }

  async function enviarSolicitud(destino) {
    try {
      await usuarioApi.enviarSolicitud(destino)
      setInfoMsg('Solicitud de colaboración enviada correctamente')
      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo enviar la solicitud')
    }
  }

  async function enviarSolicitudInsumo(e) {
    e.preventDefault()

    if (!formSolicitud.codigo) {
      setError('Debe seleccionar un insumo')
      return
    }

    try {
      await usuarioApi.crearSolicitudReabastecimiento({
        codigo: formSolicitud.codigo,
        cantidad: Number(formSolicitud.cantidad),
        observacion: formSolicitud.observacion
      })

      setInfoMsg('Solicitud de reabastecimiento enviada correctamente')
      setFormSolicitud((prev) => ({
        ...prev,
        cantidad: 1,
        observacion: ''
      }))

      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo enviar la solicitud de insumo')
    }
  }

  async function guardarLZW() {
    try {
      const res = await usuarioApi.guardarLZW()
      setLzwInfo(res || null)
      setInfoMsg(res?.mensaje || 'Historial guardado en LZW correctamente')
    } catch (err) {
      setError(err.message || 'No se pudo guardar el historial LZW')
    }
  }

  async function recargarLZW() {
    try {
      const res = await usuarioApi.recargarLZW()
      setLzwInfo(res || null)
      setInfoMsg(res?.mensaje || 'Historial recargado desde LZW correctamente')
      await cargarDashboard()
    } catch (err) {
      setError(err.message || 'No se pudo recargar el historial LZW')
    }
  }

  useEffect(() => {
    cargarDashboard()
  }, [])

  return (
    <div className="page-shell">
      <header className="hero-header">
        <div>
          <div className="hero-badges">
            <span className="phase-badge">EDD MedTrack · Fase 3</span>
            <span className="role-badge">Usuario</span>
          </div>
          <h1>Panel Usuario</h1>
          <p className="muted">{usuario?.nombre_completo}</p>
        </div>

        <div className="topbar-actions">
          <button className="secondary" onClick={cargarDashboard}>Recargar</button>
          <button onClick={logout}>Cerrar sesión</button>
        </div>
      </header>

      {error && <div className="error-box">{error}</div>}
      {infoMsg && <div className="info-box">{infoMsg}</div>}
      {loading && <div className="card">Cargando dashboard usuario...</div>}

      {!loading && (
        <>
          <section className="cards-grid">
            <StatCard title="Mi tipo" value={perfil?.usuario?.tipo_usuario || '-'} subtitle="Perfil del profesional" />
            <StatCard title="Mi departamento" value={perfil?.usuario?.departamento || '-'} subtitle="Área asignada" />
            <StatCard title="Colaboradores" value={colaboradores.length} subtitle="Red directa activa" />
            <StatCard title="Conversaciones" value={conversaciones.length} subtitle="Chats disponibles" />
            <StatCard title="Historial LZW" value={lzwInfo?.existe_archivo ? 'Sí' : 'No'} subtitle={lzwInfo?.archivo_lzw || 'Sin archivo'} />
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Perfil</span>
                  <h2>Mi perfil</h2>
                </div>
              </div>

              <div className="summary-list">
                <div><span>Nombre</span><strong>{perfil?.usuario?.nombre_completo}</strong></div>
                <div><span>No. colegio</span><strong>{perfil?.usuario?.numero_colegio}</strong></div>
                <div><span>Tipo</span><strong>{perfil?.usuario?.tipo_usuario}</strong></div>
                <div><span>Departamento</span><strong>{perfil?.usuario?.departamento}</strong></div>
                <div><span>Especialidad</span><strong>{perfil?.usuario?.especialidad}</strong></div>
              </div>
            </div>

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Permisos</span>
                  <h2>Accesos del usuario</h2>
                </div>
              </div>

              <p><strong>Consulta:</strong> {(perfil?.permisos?.consulta || []).join(', ') || 'Sin permisos'}</p>
              <p><strong>Solicitud:</strong> {(perfil?.permisos?.solicitud || []).join(', ') || 'Sin permisos'}</p>
            </div>
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Compresión</span>
                  <h2>Persistencia LZW del chat</h2>
                </div>
              </div>

              <div className="summary-list">
                <div><span>Archivo</span><strong>{lzwInfo?.archivo_lzw || 'No disponible'}</strong></div>
                <div><span>Existe en disco</span><strong>{lzwInfo?.existe_archivo ? 'Sí' : 'No'}</strong></div>
                <div><span>Tamaño</span><strong>{lzwInfo?.size_bytes ?? 0} bytes</strong></div>
                <div><span>Conversaciones en memoria</span><strong>{lzwInfo?.conversaciones_memoria ?? 0}</strong></div>
                <div><span>Mensajes totales</span><strong>{lzwInfo?.mensajes_totales ?? 0}</strong></div>
              </div>

              <p><strong>Directorio chats:</strong></p>
              <p className="path-text">{lzwInfo?.chats_dir || '-'}</p>

              <div className="toolbar">
                <button onClick={guardarLZW}>Guardar historial</button>
                <button className="secondary" onClick={recargarLZW}>Recargar historial</button>
              </div>

              <p className="muted">
                Esta sección demuestra la escritura y recuperación del historial comprimido en formato LZW.
              </p>
            </div>

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Reabastecimiento</span>
                  <h2>Solicitud de insumos</h2>
                </div>
              </div>

              <form className="form-grid" onSubmit={enviarSolicitudInsumo}>
                <label>
                  Insumo
                  <select
                    value={formSolicitud.codigo}
                    onChange={(e) =>
                      setFormSolicitud((prev) => ({ ...prev, codigo: e.target.value }))
                    }
                  >
                    {insumos.map((i) => (
                      <option key={i.codigo} value={i.codigo}>
                        {i.codigo} - {i.nombre} ({i.fabricante})
                      </option>
                    ))}
                    {insumos.length === 0 && (
                      <option value="">No hay insumos disponibles</option>
                    )}
                  </select>
                </label>

                <label>
                  Cantidad
                  <input
                    type="number"
                    min="1"
                    value={formSolicitud.cantidad}
                    onChange={(e) =>
                      setFormSolicitud((prev) => ({ ...prev, cantidad: e.target.value }))
                    }
                  />
                </label>

                <label>
                  Observación
                  <textarea
                    rows="3"
                    value={formSolicitud.observacion}
                    onChange={(e) =>
                      setFormSolicitud((prev) => ({ ...prev, observacion: e.target.value }))
                    }
                    placeholder="Explica por qué necesitas el insumo"
                  />
                </label>

                <button type="submit" disabled={insumos.length === 0}>
                  Enviar solicitud de insumo
                </button>
              </form>
            </div>
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Historial</span>
                  <h2>Mis solicitudes de reabastecimiento</h2>
                </div>
              </div>

              {misSolicitudes.length === 0 && (
                <EmptyState text="No has enviado solicitudes de reabastecimiento." />
              )}

              <div className="requests-grid one-col">
                {misSolicitudes.map((s) => (
                  <div key={s.id} className="request-item">
                    <div className="request-header">
                      <strong>{s.id}</strong>
                      <span className={`status-badge status-${(s.estado || '').toLowerCase()}`}>
                        {s.estado}
                      </span>
                    </div>
                    <p><strong>Insumo:</strong> {s.codigo_insumo} - {s.nombre_insumo}</p>
                    <p><strong>Cantidad:</strong> {s.cantidad_solicitada}</p>
                    <p><strong>Observación:</strong> {s.observacion || 'Sin observación'}</p>
                    <p><strong>Creada:</strong> {s.timestamp_creacion}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Grafo</span>
                  <h2>Colaboradores</h2>
                </div>
              </div>

              {colaboradores.length === 0 && (
                <EmptyState text="No tienes colaboradores." />
              )}

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
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">BFS</span>
                  <h2>Sugerencias de colaboración</h2>
                </div>
              </div>

              {sugerencias.length === 0 && (
                <EmptyState text="No hay sugerencias disponibles." />
              )}

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

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Solicitudes</span>
                  <h2>Solicitudes recibidas</h2>
                </div>
              </div>

              {solicitudes.recibidas.length === 0 && (
                <EmptyState text="Sin solicitudes recibidas." />
              )}

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
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Solicitudes</span>
                  <h2>Solicitudes enviadas</h2>
                </div>
              </div>

              {solicitudes.enviadas.length === 0 && (
                <EmptyState text="Sin solicitudes enviadas." />
              )}

              {solicitudes.enviadas.map((s, idx) => (
                <div key={`${s.receptor}-${idx}`} className="list-item">
                  <div>
                    <strong>{s.receptor}</strong>
                    <p>Estado: {s.estado}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Mensajería</span>
                  <h2>Conversaciones</h2>
                </div>
              </div>

              {conversaciones.length === 0 && (
                <EmptyState text="Sin conversaciones." />
              )}

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
          </section>

          <section className="card chat-card">
            <div className="section-head">
              <div>
                <span className="eyebrow">Chat interno</span>
                <h2>Chat {chatActivo ? `con ${chatActivo}` : ''}</h2>
              </div>
            </div>

            <div className="messages-box">
              {mensajes.length === 0 && <EmptyState text="Selecciona una conversación." />}
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
          </section>

          <footer className="footer-note">
            <span>EDD MedTrack · Fase 3</span>
            <span>Colaboración · Reabastecimiento · LZW</span>
          </footer>
        </>
      )}
    </div>
  )
}