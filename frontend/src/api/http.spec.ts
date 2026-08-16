import { describe, it, expect, vi, afterEach } from 'vitest'
import { request, resolveApiBaseUrl } from './http'
import { ApiError } from './ApiError'

function mockFetchOnce(response: Partial<Response> & { json?: () => Promise<unknown> }) {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
      json: async () => ({}),
      ...response,
    }),
  )
}

describe('resolveApiBaseUrl', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('本番(isProd=true)ではwindow.location.originを使う', () => {
    vi.stubGlobal('window', { location: { origin: 'https://example.com' } })

    expect(resolveApiBaseUrl(true)).toBe('https://example.com')
  })

  it('開発時(isProd=false)はhttp://localhost:3000を使う', () => {
    expect(resolveApiBaseUrl(false)).toBe('http://localhost:3000')
  })
})

describe('request', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('レスポンスボディにerrorフィールドがあればその文言をApiError.messageに使う', async () => {
    mockFetchOnce({
      status: 401,
      json: async () => ({ error: 'メールアドレスまたはパスワードが正しくありません' }),
    })

    await expect(request('/session')).rejects.toMatchObject({
      message: 'メールアドレスまたはパスワードが正しくありません',
      status: 401,
    })
  })

  it('errorフィールドが無い場合はフォールバックの文言を使う', async () => {
    mockFetchOnce({
      status: 500,
      json: async () => ({}),
    })

    await expect(request('/inquiries')).rejects.toMatchObject({
      status: 500,
      message: expect.stringContaining('status: 500'),
    })
  })

  it('JSONでないレスポンスの場合もフォールバックの文言を使う', async () => {
    mockFetchOnce({
      status: 500,
      json: async () => {
        throw new SyntaxError('invalid json')
      },
    })

    await expect(request('/inquiries')).rejects.toBeInstanceOf(ApiError)
  })
})
