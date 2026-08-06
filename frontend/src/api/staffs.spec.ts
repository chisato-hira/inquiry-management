import { describe, it, expect, vi, afterEach } from 'vitest'
import { fetchStaffs } from './staffs'

describe('fetchStaffs', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('GET /staffs を呼び、担当者一覧を返す', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => [{ id: 1, name: '山田太郎' }],
    })
    vi.stubGlobal('fetch', fetchMock)

    const result = await fetchStaffs()

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url] = fetchMock.mock.calls[0] as [string | URL, RequestInit]
    expect(String(url)).toBe('http://localhost:3000/staffs')
    expect(result).toEqual([{ id: 1, name: '山田太郎' }])
  })
})
