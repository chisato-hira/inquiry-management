import { describe, it, expect, vi, afterEach } from 'vitest'
import { createComment } from './comments'
import { setCsrfToken, clearCsrfToken } from './csrfToken'

describe('createComment', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    clearCsrfToken()
  })

  it('POST /inquiries/:id/comments に { comment: { content } } 形式のボディとX-CSRF-Tokenヘッダを送る', async () => {
    setCsrfToken('token-xyz')
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 201,
      json: async () => ({
        id: 10,
        content: 'コメント本文',
        comment_type: 'manual',
        created_at: '2026-01-01T00:00:00.000Z',
        staff: { id: 1, name: '山田太郎' },
      }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await createComment(5, 'コメント本文')

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0] as [string | URL, RequestInit]
    expect(String(url)).toBe('http://localhost:3000/inquiries/5/comments')
    expect(init.method).toBe('POST')
    expect((init.headers as Record<string, string>)['X-CSRF-Token']).toBe('token-xyz')
    expect(JSON.parse(init.body as string)).toEqual({ comment: { content: 'コメント本文' } })
  })
})
