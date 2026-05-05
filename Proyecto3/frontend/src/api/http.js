const API_BASE = import.meta.env.VITE_API_URL || ''

export async function apiRequest(path, options = {}) {
  const {
    method = 'GET',
    body,
    headers = {}
  } = options

  const finalHeaders = { ...headers }
  const config = {
    method,
    credentials: 'include',
    headers: finalHeaders
  }

  if (body instanceof FormData) {
    config.body = body
  } else if (body !== undefined) {
    finalHeaders['Content-Type'] = 'application/json'
    config.body = JSON.stringify(body)
  }

  const response = await fetch(`${API_BASE}${path}`, config)

  const contentType = response.headers.get('content-type') || ''
  const data = contentType.includes('application/json')
    ? await response.json()
    : await response.text()

  if (!response.ok) {
    const message =
      typeof data === 'string'
        ? data
        : data?.mensaje || data?.error || 'Ocurrió un error en la solicitud'

    throw new Error(message)
  }

  return data
}