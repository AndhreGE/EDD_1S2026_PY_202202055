import { useEffect, useMemo, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { adminApi } from '../api/adminApi'

const DEPARTAMENTOS = [
  'DEP-MED',
  'DEP-CIR',
  'DEP-LAB',
  'DEP-FAR',
  'DEP-ADM'
]

function normalizarDepartamento(dep) {
  if (!dep) return 'DEP-MED'

  const limpio = String(dep).trim().toUpperCase()

  if (
    limpio === 'SIN_DEP' ||
    limpio === 'SIN-DEP' ||
    limpio === 'SIN DEPARTAMENTO' ||
    limpio === 'SIN_DEPARTAMENTO'
  ) {
    return 'DEP-MED'
  }

  if (DEPARTAMENTOS.includes(limpio)) {
    return limpio
  }

  return 'DEP-MED'
}

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

export default function AdminPage() {
  const { usuario, logout } = useAuth()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [infoMsg, setInfoMsg] = useState('')

  const [resumen, setResumen] = useState(null)
  const [usuarios, setUsuarios] = useState([])
  const [tipoConsulta, setTipoConsulta] = useState('TIPO-01')
  const [usuariosPorTipo, setUsuariosPorTipo] = useState([])
  const [hashResumen, setHashResumen] = useState(null)
  const [colabResumen, setColabResumen] = useState(null)

  const [usuariosAislados, setUsuariosAislados] = useState([])
  const [usuariosSinDepartamento, setUsuariosSinDepartamento] = useState([])
  const [solicitudesReabastecimiento, setSolicitudesReabastecimiento] = useState([])
  const [solicitudesColaboracionPendientes, setSolicitudesColaboracionPendientes] = useState([])

  const [reporteActual, setReporteActual] = useState({
    titulo: '',
    url: ''
  })

  const [deptMap, setDeptMap] = useState({})

  const [archivos, setArchivos] = useState({
    usuarios: null,
    inventario: null,
    colaboraciones: null
  })

  const [nuevoUsuario, setNuevoUsuario] = useState({
    numero_colegio: '',
    nombre_completo: '',
    tipo_usuario: 'TIPO-01',
    departamento: '',
    especialidad: '',
    clave: ''
  })

  const pendientesReabastecimiento = useMemo(
    () => solicitudesReabastecimiento.filter((s) => s.estado === 'PENDIENTE').length,
    [solicitudesReabastecimiento]
  )

  const pendientesColaboracion = useMemo(
    () => solicitudesColaboracionPendientes.filter((s) => (s.estado || 'PENDIENTE') === 'PENDIENTE').length,
    [solicitudesColaboracionPendientes]
  )

  function construirMapaDepartamentos(listaUsuarios, listaPendientes) {
    const mapa = {}

    ;[...(listaUsuarios || []), ...(listaPendientes || [])].forEach((u) => {
      if (!u?.numero_colegio) return
      mapa[u.numero_colegio] = normalizarDepartamento(u.departamento)
    })

    return mapa
  }

  async function cargarTodo() {
    setLoading(true)
    setError('')

    try {
      const [
        resResumen,
        resUsuarios,
        resHash,
        resColab,
        resTipo,
        resAislados,
        resSinDept,
        resReab,
        resSolicitudesColab
      ] = await Promise.all([
        adminApi.getResumen(),
        adminApi.getUsuarios(),
        adminApi.getHashResumen(),
        adminApi.getColaboracionResumen(),
        adminApi.getUsuariosPorTipo(tipoConsulta),
        adminApi.getUsuariosAislados(),
        adminApi.getUsuariosSinDepartamento(),
        adminApi.getSolicitudesReabastecimiento(),
        adminApi.getSolicitudesColaboracionPendientes()
      ])

      const listaUsuarios = resUsuarios.usuarios || []
      const listaPendientes = resSinDept.usuarios || []

      setResumen(resResumen.resumen || null)
      setUsuarios(listaUsuarios)
      setHashResumen(resHash.resumen || null)
      setColabResumen(resColab.resumen || null)
      setUsuariosPorTipo(resTipo.usuarios || [])
      setUsuariosAislados(resAislados.usuarios || [])
      setUsuariosSinDepartamento(listaPendientes)
      setSolicitudesReabastecimiento(resReab.solicitudes || [])
      setSolicitudesColaboracionPendientes(resSolicitudesColab.solicitudes || [])

      setDeptMap(construirMapaDepartamentos(listaUsuarios, listaPendientes))
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

  function onArchivoChange(tipo, file) {
    setArchivos((prev) => ({
      ...prev,
      [tipo]: file || null
    }))
  }

  async function subirArchivo(tipo) {
    setError('')
    setInfoMsg('')

    const archivo = archivos[tipo]
    if (!archivo) {
      setError('Debes seleccionar un archivo antes de cargarlo')
      return
    }

    try {
      let res

      if (tipo === 'usuarios') {
        res = await adminApi.uploadUsuariosJson(archivo)
      } else if (tipo === 'inventario') {
        res = await adminApi.uploadInventarioJson(archivo)
      } else {
        res = await adminApi.uploadColaboracionesJson(archivo)
      }

      setInfoMsg(res.mensaje || `Archivo ${archivo.name} procesado correctamente`)

      setArchivos((prev) => ({
        ...prev,
        [tipo]: null
      }))

      const input = document.getElementById(`file-${tipo}`)
      if (input) input.value = ''

      await cargarTodo()
    } catch (err) {
      setError(err.message || 'No se pudo cargar el archivo seleccionado')
    }
  }

  function onNuevoUsuarioChange(field, value) {
    setNuevoUsuario((prev) => ({
      ...prev,
      [field]: value
    }))
  }

  async function registrarUsuarioManual(e) {
    e.preventDefault()
    setError('')
    setInfoMsg('')

    try {
      const payload = {
        ...nuevoUsuario,
        departamento: nuevoUsuario.departamento.trim()
      }

      const res = await adminApi.crearUsuarioManual(payload)

      setInfoMsg(res.mensaje || 'Usuario registrado correctamente')

      setNuevoUsuario({
        numero_colegio: '',
        nombre_completo: '',
        tipo_usuario: 'TIPO-01',
        departamento: '',
        especialidad: '',
        clave: ''
      })

      await cargarTodo()
    } catch (err) {
      setError(err.message || 'No se pudo registrar el usuario manualmente')
    }
  }

  async function verReporte(tipo) {
    setError('')
    setInfoMsg('')

    try {
      let res
      let titulo = ''

      if (tipo === 'grafo') {
        titulo = 'Grafo de colaboración'
        res = await adminApi.generarReporteGrafo()
      } else if (tipo === 'lista') {
        titulo = 'Lista de adyacencia'
        res = await adminApi.generarReporteListaAdyacencia()
      } else if (tipo === 'hash') {
        titulo = 'Tabla Hash'
        res = await adminApi.generarReporteHash()
      }

      setReporteActual({
        titulo,
        url: res.image_url || ''
      })

      setInfoMsg(res.mensaje || 'Reporte generado correctamente')
    } catch (err) {
      setError(err.message || 'No se pudo generar el reporte')
    }
  }

  function cambiarDepartamento(numeroColegio, valor) {
    setDeptMap((prev) => ({
      ...prev,
      [numeroColegio]: valor
    }))
  }

  async function guardarDepartamento(numeroColegio) {
    const departamento = deptMap[numeroColegio]

    if (!numeroColegio || !departamento) {
      setError('Debe seleccionar un departamento válido')
      return
    }

    setError('')
    setInfoMsg('')

    try {
      const res = await adminApi.asignarDepartamento(numeroColegio, departamento)
      setInfoMsg(res.mensaje || `Departamento actualizado para ${numeroColegio}`)
      await cargarTodo()
    } catch (err) {
      setError(err.message || 'No se pudo actualizar el departamento')
    }
  }

  async function gestionarSolicitud(id, accion) {
    setError('')
    setInfoMsg('')

    try {
      let res

      if (accion === 'aprobar') {
        res = await adminApi.aprobarSolicitudReabastecimiento(id, 'Solicitud aprobada desde panel admin')
      } else if (accion === 'rechazar') {
        res = await adminApi.rechazarSolicitudReabastecimiento(id, 'Solicitud rechazada desde panel admin')
      } else {
        res = await adminApi.atenderSolicitudReabastecimiento(id, 'Solicitud atendida desde panel admin')
      }

      setInfoMsg(res.mensaje || `Solicitud ${id} actualizada`)
      await cargarTodo()
    } catch (err) {
      setError(err.message || 'No se pudo actualizar la solicitud')
    }
  }

  async function aprobarSolicitudColaboracion(solicitante, receptor) {
    setError('')
    setInfoMsg('')

    try {
      const res = await adminApi.aprobarSolicitudColaboracion({
        solicitante,
        receptor
      })

      setInfoMsg(res.mensaje || 'Solicitud de colaboración aprobada')
      await cargarTodo()
    } catch (err) {
      setError(err.message || 'No se pudo aprobar la solicitud de colaboración')
    }
  }

  async function rechazarSolicitudColaboracion(solicitante, receptor) {
    setError('')
    setInfoMsg('')

    try {
      const res = await adminApi.rechazarSolicitudColaboracion({
        solicitante,
        receptor
      })

      setInfoMsg(res.mensaje || 'Solicitud de colaboración rechazada')
      await cargarTodo()
    } catch (err) {
      setError(err.message || 'No se pudo rechazar la solicitud de colaboración')
    }
  }

  useEffect(() => {
    cargarTodo()
  }, [])

  return (
    <div className="page-shell">
      <header className="hero-header">
        <div>
          <div className="hero-badges">
            <span className="phase-badge">EDD MedTrack · Fase 3</span>
            <span className="role-badge">Administrador</span>
          </div>
          <h1>Panel Admin</h1>
          <p className="muted">
            {usuario?.nombre_completo || 'Administrador del Sistema'}
          </p>
        </div>

        <div className="topbar-actions">
          <button className="secondary" onClick={cargarTodo}>Recargar</button>
          <button onClick={logout}>Cerrar sesión</button>
        </div>
      </header>

      {error && <div className="error-box">{error}</div>}
      {infoMsg && <div className="info-box">{infoMsg}</div>}
      {loading && <div className="card">Cargando dashboard admin...</div>}

      {!loading && (
        <>
          <section className="cards-grid">
            <StatCard title="Total usuarios" value={resumen?.usuarios ?? 0} subtitle="AVL + directorio general" />
            <StatCard title="Usuarios hash" value={hashResumen?.total_usuarios ?? 0} subtitle="Consulta por tipo" />
            <StatCard title="Colaboraciones activas" value={colabResumen?.colaboraciones_activas ?? 0} subtitle="Red global" />
            <StatCard title="Pendientes colaboración" value={pendientesColaboracion} subtitle="Solicitudes globales" />
            <StatCard title="Pendientes reabastecimiento" value={pendientesReabastecimiento} subtitle="Lista en cola" />
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Carga manual</span>
                  <h2>Archivos JSON</h2>
                </div>
              </div>

              <p className="muted">
                Selecciona manualmente cada archivo desde tu equipo. Esto sustituye la ruta fija del servidor.
              </p>

              <div className="upload-stack">
                <div className="upload-row">
                  <div>
                    <label className="upload-label" htmlFor="file-usuarios">Usuarios JSON</label>
                    <input
                      id="file-usuarios"
                      type="file"
                      accept=".json,application/json"
                      onChange={(e) => onArchivoChange('usuarios', e.target.files?.[0])}
                    />
                    <p className="file-meta">{archivos.usuarios ? archivos.usuarios.name : 'Ningún archivo seleccionado'}</p>
                  </div>
                  <button onClick={() => subirArchivo('usuarios')}>Cargar usuarios</button>
                </div>

                <div className="upload-row">
                  <div>
                    <label className="upload-label" htmlFor="file-inventario">Inventario JSON</label>
                    <input
                      id="file-inventario"
                      type="file"
                      accept=".json,application/json"
                      onChange={(e) => onArchivoChange('inventario', e.target.files?.[0])}
                    />
                    <p className="file-meta">{archivos.inventario ? archivos.inventario.name : 'Ningún archivo seleccionado'}</p>
                  </div>
                  <button onClick={() => subirArchivo('inventario')}>Cargar inventario</button>
                </div>

                <div className="upload-row">
                  <div>
                    <label className="upload-label" htmlFor="file-colaboraciones">Relaciones de colaboración JSON</label>
                    <input
                      id="file-colaboraciones"
                      type="file"
                      accept=".json,application/json"
                      onChange={(e) => onArchivoChange('colaboraciones', e.target.files?.[0])}
                    />
                    <p className="file-meta">{archivos.colaboraciones ? archivos.colaboraciones.name : 'Ningún archivo seleccionado'}</p>
                  </div>
                  <button onClick={() => subirArchivo('colaboraciones')}>Cargar relaciones</button>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Registro manual</span>
                  <h2>Usuario individual</h2>
                </div>
              </div>

              <p className="muted">
                Si dejas el departamento vacío, el usuario quedará pendiente de asignación.
              </p>

              <form className="form-grid split-form" onSubmit={registrarUsuarioManual}>
                <label>
                  No. colegio
                  <input
                    value={nuevoUsuario.numero_colegio}
                    onChange={(e) => onNuevoUsuarioChange('numero_colegio', e.target.value)}
                    placeholder="COL-90001"
                  />
                </label>

                <label>
                  Tipo de usuario
                  <select
                    value={nuevoUsuario.tipo_usuario}
                    onChange={(e) => onNuevoUsuarioChange('tipo_usuario', e.target.value)}
                  >
                    <option value="TIPO-01">TIPO-01</option>
                    <option value="TIPO-02">TIPO-02</option>
                    <option value="TIPO-03">TIPO-03</option>
                    <option value="TIPO-04">TIPO-04</option>
                    <option value="TIPO-05">TIPO-05</option>
                  </select>
                </label>

                <label className="span-2">
                  Nombre completo
                  <input
                    value={nuevoUsuario.nombre_completo}
                    onChange={(e) => onNuevoUsuarioChange('nombre_completo', e.target.value)}
                    placeholder="Nombre del profesional"
                  />
                </label>

                <label>
                  Departamento
                  <input
                    value={nuevoUsuario.departamento}
                    onChange={(e) => onNuevoUsuarioChange('departamento', e.target.value)}
                    placeholder="Opcional: DEP-MED"
                  />
                </label>

                <label>
                  Especialidad
                  <input
                    value={nuevoUsuario.especialidad}
                    onChange={(e) => onNuevoUsuarioChange('especialidad', e.target.value)}
                    placeholder="Medicina General"
                  />
                </label>

                <label className="span-2">
                  Clave
                  <input
                    type="password"
                    value={nuevoUsuario.clave}
                    onChange={(e) => onNuevoUsuarioChange('clave', e.target.value)}
                    placeholder="Contraseña del usuario"
                  />
                </label>

                <div className="span-2">
                  <button type="submit">Registrar usuario manualmente</button>
                </div>
              </form>
            </div>
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Visualización</span>
                  <h2>Reportes Graphviz</h2>
                </div>
              </div>

              <p className="muted">
                Genera y muestra los reportes gráficos principales de la fase.
              </p>

              <div className="action-grid">
                <button onClick={() => verReporte('grafo')}>Ver grafo</button>
                <button onClick={() => verReporte('lista')}>Ver lista de adyacencia</button>
                <button onClick={() => verReporte('hash')}>Ver tabla hash</button>
              </div>
            </div>

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Tabla Hash</span>
                  <h2>Resumen hash</h2>
                </div>
              </div>

              <div className="summary-list">
                <div><span>Buckets totales</span><strong>{hashResumen?.buckets_totales ?? 0}</strong></div>
                <div><span>Buckets utilizados</span><strong>{hashResumen?.buckets_utilizados ?? 0}</strong></div>
                <div><span>Factor de carga</span><strong>{hashResumen?.factor_carga ?? '0.00'}</strong></div>
                <div><span>Total colisiones</span><strong>{hashResumen?.total_colisiones ?? 0}</strong></div>
              </div>
            </div>
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Grafo</span>
                  <h2>Resumen colaboración</h2>
                </div>
              </div>

              <div className="summary-list">
                <div><span>Usuarios</span><strong>{colabResumen?.usuarios ?? 0}</strong></div>
                <div><span>Sin departamento</span><strong>{colabResumen?.sin_departamento ?? 0}</strong></div>
                <div><span>Solicitudes pendientes</span><strong>{colabResumen?.solicitudes_pendientes ?? 0}</strong></div>
                <div><span>Solicitudes rechazadas</span><strong>{colabResumen?.solicitudes_rechazadas ?? 0}</strong></div>
              </div>
            </div>

            {reporteActual.url ? (
              <div className="card">
                <div className="section-head">
                  <div>
                    <span className="eyebrow">Reporte activo</span>
                    <h2>{reporteActual.titulo}</h2>
                  </div>
                </div>

                <div className="report-frame">
                  <img src={reporteActual.url} alt={reporteActual.titulo} className="report-image" />
                </div>
              </div>
            ) : (
              <div className="card">
                <div className="section-head">
                  <div>
                    <span className="eyebrow">Reporte activo</span>
                    <h2>Sin reporte seleccionado</h2>
                  </div>
                </div>
                <EmptyState text="Genera un reporte desde los botones superiores para visualizarlo aquí." />
              </div>
            )}
          </section>

          <section className="two-col-grid">
            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Pendientes</span>
                  <h2>Usuarios pendientes de asignación</h2>
                </div>
              </div>

              <p className="muted">
                Usuarios sin departamento para asignarlos rápidamente desde este panel.
              </p>

              {usuariosSinDepartamento.length === 0 && (
                <EmptyState text="No hay usuarios pendientes de asignación." />
              )}

              {usuariosSinDepartamento.map((u) => (
                <div key={u.numero_colegio} className="list-item admin-list-item">
                  <div>
                    <strong>{u.nombre_completo}</strong>
                    <p className="item-meta">
                      {u.numero_colegio} · {u.tipo_usuario} · {u.departamento || 'SIN_DEP'}
                    </p>
                  </div>

                  <div className="dept-actions">
                    <select
                      value={deptMap[u.numero_colegio] || 'DEP-MED'}
                      onChange={(e) => cambiarDepartamento(u.numero_colegio, e.target.value)}
                    >
                      {DEPARTAMENTOS.map((dep) => (
                        <option key={dep} value={dep}>{dep}</option>
                      ))}
                    </select>

                    <button onClick={() => guardarDepartamento(u.numero_colegio)}>
                      Asignar
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="card">
              <div className="section-head">
                <div>
                  <span className="eyebrow">Grafo</span>
                  <h2>Usuarios aislados</h2>
                </div>
              </div>

              <p className="muted">
                Profesionales sin conexiones activas en la red de colaboración.
              </p>

              {usuariosAislados.length === 0 && (
                <EmptyState text="No hay usuarios aislados." />
              )}

              {usuariosAislados.map((u) => (
                <div key={u.numero_colegio} className="list-item admin-list-item">
                  <div>
                    <strong>{u.nombre_completo}</strong>
                    <p className="item-meta">
                      {u.numero_colegio} · {u.tipo_usuario} · {u.departamento}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="card">
            <div className="section-head">
              <div>
                <span className="eyebrow">Gestión global</span>
                <h2>Solicitudes de colaboración pendientes globales</h2>
              </div>
            </div>

            <p className="muted">
              El administrador puede revisar y resolver todas las solicitudes de colaboración pendientes del sistema.
            </p>

            {solicitudesColaboracionPendientes.length === 0 && (
              <EmptyState text="No hay solicitudes de colaboración pendientes." />
            )}

            <div className="requests-grid">
              {solicitudesColaboracionPendientes.map((s, idx) => (
                <div
                  key={`${s.solicitante}-${s.receptor}-${idx}`}
                  className="request-item"
                >
                  <div className="request-header">
                    <strong>{s.solicitante} → {s.receptor}</strong>
                    <span className={`status-badge status-${(s.estado || 'pendiente').toLowerCase()}`}>
                      {s.estado || 'PENDIENTE'}
                    </span>
                  </div>

                  <p><strong>Solicitante:</strong> {s.solicitante_nombre || 'N/D'} ({s.solicitante})</p>
                  <p><strong>Tipo / Depto solicitante:</strong> {s.solicitante_tipo || 'N/D'} · {s.solicitante_depto || 'N/D'}</p>
                  <p><strong>Receptor:</strong> {s.receptor_nombre || 'N/D'} ({s.receptor})</p>
                  <p><strong>Tipo / Depto receptor:</strong> {s.receptor_tipo || 'N/D'} · {s.receptor_depto || 'N/D'}</p>

                  <div className="inline-buttons">
                    <button onClick={() => aprobarSolicitudColaboracion(s.solicitante, s.receptor)}>
                      Aprobar
                    </button>
                    <button
                      className="danger"
                      onClick={() => rechazarSolicitudColaboracion(s.solicitante, s.receptor)}
                    >
                      Rechazar
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="card">
            <div className="section-head">
              <div>
                <span className="eyebrow">Lista circular doble</span>
                <h2>Gestión de solicitudes de reabastecimiento</h2>
              </div>
            </div>

            <p className="muted">
              Solicitudes enviadas por usuarios para pedir insumos al sistema.
            </p>

            {solicitudesReabastecimiento.length === 0 && (
              <EmptyState text="No hay solicitudes de reabastecimiento registradas." />
            )}

            <div className="requests-grid">
              {solicitudesReabastecimiento.map((s) => (
                <div key={s.id} className="request-item">
                  <div className="request-header">
                    <strong>{s.id}</strong>
                    <span className={`status-badge status-${(s.estado || '').toLowerCase()}`}>
                      {s.estado}
                    </span>
                  </div>

                  <p><strong>Usuario:</strong> {s.nombre_completo} ({s.numero_colegio})</p>
                  <p><strong>Departamento:</strong> {s.departamento}</p>
                  <p><strong>Insumo:</strong> {s.codigo_insumo} - {s.nombre_insumo}</p>
                  <p><strong>Fabricante:</strong> {s.fabricante || 'N/D'}</p>
                  <p><strong>Cantidad:</strong> {s.cantidad_solicitada}</p>
                  <p><strong>Observación:</strong> {s.observacion || 'Sin observación'}</p>
                  <p><strong>Creada:</strong> {s.timestamp_creacion}</p>

                  <div className="inline-buttons">
                    <button onClick={() => gestionarSolicitud(s.id, 'aprobar')}>
                      Aprobar
                    </button>
                    <button className="danger" onClick={() => gestionarSolicitud(s.id, 'rechazar')}>
                      Rechazar
                    </button>
                    <button className="secondary" onClick={() => gestionarSolicitud(s.id, 'atender')}>
                      Atender
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="card">
            <div className="section-head">
              <div>
                <span className="eyebrow">Tabla Hash</span>
                <h2>Consulta por tipo</h2>
              </div>
            </div>

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
            <div className="section-head">
              <div>
                <span className="eyebrow">Administración</span>
                <h2>Gestión de red de colaboración: asignar o reasignar</h2>
              </div>
            </div>

            <p className="muted">
              Desde aquí puedes ajustar el departamento de cualquier usuario del sistema.
            </p>

            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>No. colegio</th>
                    <th>Nombre</th>
                    <th>Tipo</th>
                    <th>Departamento actual</th>
                    <th>Nuevo departamento</th>
                    <th>Acción</th>
                  </tr>
                </thead>
                <tbody>
                  {usuarios.map((u) => (
                    <tr key={u.numero_colegio}>
                      <td>{u.numero_colegio}</td>
                      <td>{u.nombre_completo}</td>
                      <td>{u.tipo_usuario}</td>
                      <td>{u.departamento}</td>
                      <td>
                        <select
                          value={deptMap[u.numero_colegio] || normalizarDepartamento(u.departamento)}
                          onChange={(e) => cambiarDepartamento(u.numero_colegio, e.target.value)}
                        >
                          {DEPARTAMENTOS.map((dep) => (
                            <option key={dep} value={dep}>{dep}</option>
                          ))}
                        </select>
                      </td>
                      <td>
                        <button className="small-btn" onClick={() => guardarDepartamento(u.numero_colegio)}>
                          Guardar
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          <section className="card">
            <div className="section-head">
              <div>
                <span className="eyebrow">Directorio</span>
                <h2>Todos los usuarios</h2>
              </div>
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

          <footer className="footer-note">
            <span>EDD MedTrack · Fase 3</span>
            <span>Frontend React conectado a backend Perl + Mojolicious</span>
          </footer>
        </>
      )}
    </div>
  )
}