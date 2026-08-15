import { describe, it, expect, vi, afterEach } from 'vitest'
import { createInquiry, fetchInquiry, searchInquiries, updateInquiry } from './inquiries'
import { setCsrfToken, clearCsrfToken } from './csrfToken'

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

describe('fetchInquiry', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('GET /inquiries/:id を呼ぶ', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ id: 1, comments: [] }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await fetchInquiry(1)

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url] = fetchMock.mock.calls[0] as [string | URL, RequestInit]
    expect(String(url)).toBe('http://localhost:3000/inquiries/1')
  })
})

describe('searchInquiries', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('GET /inquiries/search に q・page をクエリパラメータで渡す', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ inquiries: [], meta: { page: 1, per_page: 20, total_count: 0, has_more: false } }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await searchInquiries({ q: '山田', page: 1 })

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0] as [string | URL, RequestInit]
    expect(String(url)).toBe('http://localhost:3000/inquiries/search?q=%E5%B1%B1%E7%94%B0&page=1')
    expect(init.method).toBeUndefined()
  })
})

describe('updateInquiry', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    clearCsrfToken()
  })

  it('PATCH /inquiries/:id に { inquiry: {...} } 形式のボディとX-CSRF-Tokenヘッダを送る', async () => {
    setCsrfToken('token-xyz')
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ id: 1 }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const payload = { status: '対応中' as const, lock_version: 2 }

    await updateInquiry(1, payload)

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0] as [string | URL, RequestInit]
    expect(String(url)).toBe('http://localhost:3000/inquiries/1')
    expect(init.method).toBe('PATCH')
    expect((init.headers as Record<string, string>)['X-CSRF-Token']).toBe('token-xyz')
    expect(JSON.parse(init.body as string)).toEqual({ inquiry: payload })
  })
})
