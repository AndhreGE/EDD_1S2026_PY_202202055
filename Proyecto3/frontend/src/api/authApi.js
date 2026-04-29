import { apiRequest } from './http'

export const authApi = {
  login(payload) {
    return apiRequest('/api/auth/login', {
      method: 'POST',
      body: payload
    })
  },

  me() {
    return apiRequest('/api/auth/me')
  },

  logout() {
    return apiRequest('/api/auth/logout', {
      method: 'POST'
    })
  }
}