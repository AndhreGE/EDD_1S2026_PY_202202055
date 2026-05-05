import { apiRequest } from './http'

export const adminApi = {
  getResumen() {
    return apiRequest('/api/admin/resumen')
  },

  getUsuarios() {
    return apiRequest('/api/admin/usuarios')
  },

  getUsuariosPorTipo(tipo) {
    return apiRequest(`/api/admin/usuarios/tipo/${tipo}`)
  },

  getHashResumen() {
    return apiRequest('/api/admin/hash/resumen')
  },

  getColaboracionResumen() {
    return apiRequest('/api/admin/colaboracion/resumen')
  },

  getUsuariosAislados() {
    return apiRequest('/api/admin/colaboracion/aislados')
  },

  getUsuariosSinDepartamento() {
    return apiRequest('/api/admin/colaboracion/sin-departamento')
  },

  getSolicitudesColaboracionPendientes() {
    return apiRequest('/api/admin/colaboracion/solicitudes-pendientes')
  },

  aprobarSolicitudColaboracion(payload) {
    return apiRequest('/api/admin/colaboracion/solicitudes/aprobar', {
      method: 'POST',
      body: payload
    })
  },

  rechazarSolicitudColaboracion(payload) {
    return apiRequest('/api/admin/colaboracion/solicitudes/rechazar', {
      method: 'POST',
      body: payload
    })
  },

  asignarDepartamento(numeroColegio, departamento) {
    return apiRequest(`/api/admin/usuarios/${numeroColegio}/departamento`, {
      method: 'POST',
      body: { departamento }
    })
  },

  uploadUsuariosJson(file) {
    const form = new FormData()
    form.append('archivo', file)

    return apiRequest('/api/admin/cargas/usuarios/upload', {
      method: 'POST',
      body: form
    })
  },

  uploadInventarioJson(file) {
    const form = new FormData()
    form.append('archivo', file)

    return apiRequest('/api/admin/cargas/inventario/upload', {
      method: 'POST',
      body: form
    })
  },

  uploadColaboracionesJson(file) {
    const form = new FormData()
    form.append('archivo', file)

    return apiRequest('/api/admin/cargas/colaboraciones/upload', {
      method: 'POST',
      body: form
    })
  },

  crearUsuarioManual(payload) {
    return apiRequest('/api/admin/usuarios/manual', {
      method: 'POST',
      body: payload
    })
  },

  generarReporteGrafo() {
    return apiRequest('/api/admin/reportes/grafo')
  },

  generarReporteListaAdyacencia() {
    return apiRequest('/api/admin/reportes/lista-adyacencia')
  },

  generarReporteHash() {
    return apiRequest('/api/admin/reportes/hash')
  },

  getSolicitudesReabastecimiento() {
    return apiRequest('/api/admin/reabastecimiento')
  },

  aprobarSolicitudReabastecimiento(id, observacion = '') {
    return apiRequest(`/api/admin/reabastecimiento/${id}/aprobar`, {
      method: 'POST',
      body: { observacion }
    })
  },

  rechazarSolicitudReabastecimiento(id, observacion = '') {
    return apiRequest(`/api/admin/reabastecimiento/${id}/rechazar`, {
      method: 'POST',
      body: { observacion }
    })
  },

  atenderSolicitudReabastecimiento(id, observacion = '') {
    return apiRequest(`/api/admin/reabastecimiento/${id}/atender`, {
      method: 'POST',
      body: { observacion }
    })
  }
}