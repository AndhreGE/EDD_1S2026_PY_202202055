import { apiRequest } from './http'

export const usuarioApi = {
  getPerfil() {
    return apiRequest('/api/usuario/perfil')
  },

  getColaboradores() {
    return apiRequest('/api/usuario/colaboradores')
  },

  getSugerencias() {
    return apiRequest('/api/usuario/sugerencias')
  },

  getSolicitudes() {
    return apiRequest('/api/usuario/solicitudes')
  },

  enviarSolicitud(destino) {
    return apiRequest('/api/usuario/solicitudes', {
      method: 'POST',
      body: { destino }
    })
  },

  aceptarSolicitud(solicitante) {
    return apiRequest('/api/usuario/solicitudes/aceptar', {
      method: 'POST',
      body: { solicitante }
    })
  },

  rechazarSolicitud(solicitante) {
    return apiRequest('/api/usuario/solicitudes/rechazar', {
      method: 'POST',
      body: { solicitante }
    })
  },

  getConversaciones() {
    return apiRequest('/api/usuario/chat/conversaciones')
  },

  getChat(otroId) {
    return apiRequest(`/api/usuario/chat/${otroId}`)
  },

  enviarMensaje(otroId, texto) {
    return apiRequest(`/api/usuario/chat/${otroId}`, {
      method: 'POST',
      body: { texto }
    })
  },

  getInsumosSolicitables() {
    return apiRequest('/api/usuario/insumos-solicitables')
  },

  crearSolicitudReabastecimiento(payload) {
    return apiRequest('/api/usuario/reabastecimiento', {
      method: 'POST',
      body: payload
    })
  },

  getMisSolicitudesReabastecimiento() {
    return apiRequest('/api/usuario/reabastecimiento/mis-solicitudes')
  },

  getEstadoLZW() {
    return apiRequest('/api/usuario/lzw/estado')
  },

  guardarLZW() {
    return apiRequest('/api/usuario/lzw/guardar', {
      method: 'POST'
    })
  },

  recargarLZW() {
    return apiRequest('/api/usuario/lzw/recargar', {
      method: 'POST'
    })
  }
}