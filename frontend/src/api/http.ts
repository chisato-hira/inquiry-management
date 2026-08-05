import { ApiError } from './ApiError'

export const API_BASE_URL = 'http://localhost:3000'

const FALLBACK_ERROR_MESSAGE = 'リクエストに失敗しました'

export async function request<T>(input: string | URL, init: RequestInit = {}): Promise<T> {
  const response = await fetch(input, { ...init, credentials: 'include' })

  if (!response.ok) {
    throw new ApiError(await extractErrorMessage(response), response.status)
  }

  if (response.status === 204) {
    return undefined as T
  }

  return response.json() as Promise<T>
}

async function extractErrorMessage(response: Response): Promise<string> {
  try {
    const body = await response.json()
    if (body && typeof body.error === 'string') {
      return body.error
    }
  } catch {
    // レスポンスボディがJSONでない、またはパースに失敗した場合はフォールバックする
  }

  return `${FALLBACK_ERROR_MESSAGE} (status: ${response.status})`
}
