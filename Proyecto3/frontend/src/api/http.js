async function parseJsonSafe(response) {
  const text = await response.text()
  if (!text) return {}
  try {
    return JSON.parse(text)
  } catch {
    return { ok: 0, mensaje: text }
  }
}

export async function apiRequest(path, options = {}) {
  const config = {
    method: options.method || 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    },
    credentials: 'include'
  }

  if (options.body !== undefined) {
    config.body = typeof options.body === 'string'
      ? options.body
      : JSON.stringify(options.body)
  }

  const response = await fetch(path, config)
  const data = await parseJsonSafe(response)

  if (!response.ok) {
    throw new Error(data?.mensaje || `Error HTTP ${response.status}`)
  }

  return data
}