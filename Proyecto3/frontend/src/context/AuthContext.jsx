import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { authApi } from '../api/authApi'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [loading, setLoading] = useState(true)
  const [autenticado, setAutenticado] = useState(false)
  const [rol, setRol] = useState(null)
  const [usuario, setUsuario] = useState(null)

  async function refreshSession() {
    try {
      const data = await authApi.me()

      if (data?.autenticado) {
        setAutenticado(true)
        setRol(data.rol || null)
        setUsuario(data.usuario || null)
      } else {
        setAutenticado(false)
        setRol(null)
        setUsuario(null)
      }
    } catch {
      setAutenticado(false)
      setRol(null)
      setUsuario(null)
    } finally {
      setLoading(false)
    }
  }

  async function login(usuarioInput, claveInput) {
    const data = await authApi.login({
      usuario: usuarioInput,
      clave: claveInput
    })

    setAutenticado(true)
    setRol(data.rol || null)
    setUsuario(data.usuario || null)

    return data
  }

  async function logout() {
    try {
      await authApi.logout()
    } finally {
      setAutenticado(false)
      setRol(null)
      setUsuario(null)
    }
  }

  useEffect(() => {
    refreshSession()
  }, [])

  const value = useMemo(() => ({
    loading,
    autenticado,
    rol,
    usuario,
    login,
    logout,
    refreshSession
  }), [loading, autenticado, rol, usuario])

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) {
    throw new Error('useAuth debe usarse dentro de AuthProvider')
  }
  return ctx
}