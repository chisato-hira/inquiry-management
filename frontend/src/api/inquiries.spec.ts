import { describe, it, expect, vi, afterEach } from 'vitest'
import { createInquiry } from './inquiries'

describe('createInquiry', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('POST /inquiries に { inquiry: {...} } 形式のボディを送る', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 201,
      json: async () => ({ id: 1 }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const payload = {
      name: '山田太郎',
      email: 'yamada@example.com',
      phone: '',
      category: '不具合' as const,
      content: '画面が表示されません',
    }

    await createInquiry(payload)

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0] as [string | URL, RequestInit]
    expect(String(url)).toBe('http://localhost:3000/inquiries')
    expect(init.method).toBe('POST')
    expect(JSON.parse(init.body as string)).toEqual({ inquiry: payload })
  })
})
