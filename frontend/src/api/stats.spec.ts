import { describe, it, expect, vi, afterEach } from 'vitest'
import { fetchStats } from './stats'

describe('fetchStats', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('GET /stats を呼び、統計情報を返す', async () => {
    const statsResponse = {
      status_counts: { 未対応: 1, 対応中: 1, 完了: 0 },
      category_counts: { 料金プラン: 0, 使い方: 1, 解約: 0, 不具合: 1, その他: 0 },
      staff_incomplete_counts: [
        { staff_id: 1, name: '田中', count: 1 },
        { staff_id: null, name: '未割当', count: 0 },
      ],
    }
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => statsResponse,
    })
    vi.stubGlobal('fetch', fetchMock)

    const result = await fetchStats()

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url] = fetchMock.mock.calls[0] as [string | URL, RequestInit]
    expect(String(url)).toBe('http://localhost:3000/stats')
    expect(result).toEqual(statsResponse)
  })
})
