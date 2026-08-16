import { ApiError } from './ApiError'

// 本番ビルドではnginxがフロントエンド・APIを同一オリジンで配信するため相対パス(空文字)にする。
// 開発時はVite(5173)とRails(3000)がオリジンが異なるため、絶対URLで指定する。
export const API_BASE_URL = import.meta.env.PROD ? '' : 'http://localhost:3000'

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
