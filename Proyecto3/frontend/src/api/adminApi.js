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
  }
}