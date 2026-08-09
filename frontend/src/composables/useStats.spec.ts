import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ApiError } from '@/api/ApiError'
import type { Stats } from '@/types/stats'

const fetchStatsMock = vi.fn()
const handleUnauthorizedMock = vi.fn()

vi.mock('@/api/stats', () => ({
  fetchStats: (...args: unknown[]) => fetchStatsMock(...args),
}))

vi.mock('./useAuth', () => ({
  useAuth: () => ({ handleUnauthorized: handleUnauthorizedMock }),
}))

import { useStats } from './useStats'

// useStatsはモジュールレベルのsingleton状態を持つため、同じインスタンスをテスト間で
// 使い回し、beforeEachでrefの値を直接リセットする(useStaffs.spec.tsと同じ理由)。
const { stats, isLoading, isLoaded, error, ensureLoaded, reload } = useStats()

const statsFixture: Stats = {
  status_counts: { 未対応: 1, 対応中: 1, 完了: 0 },
  category_counts: { 料金プラン: 0, 使い方: 1, 解約: 0, 不具合: 1, その他: 0 },
  staff_incomplete_counts: [
    { staff_id: 1, name: '田中', count: 1 },
    { staff_id: null, name: '未割当', count: 0 },
  ],
}

describe('useStats', () => {
  beforeEach(() => {
    fetchStatsMock.mockReset()
    handleUnauthorizedMock.mockReset()
    stats.value = null
    isLoading.value = false
    isLoaded.value = false
    error.value = null
  })

  it('ensureLoaded成功時にstatsを設定しisLoadedをtrueにする', async () => {
    fetchStatsMock.mockResolvedValue(statsFixture)

    await ensureLoaded()

    expect(stats.value).toEqual(statsFixture)
    expect(isLoaded.value).toBe(true)
    expect(error.value).toBeNull()
  })

  it('既にロード済みの場合はensureLoadedを再度呼んでも再フェッチしない', async () => {
    fetchStatsMock.mockResolvedValue(statsFixture)

    await ensureLoaded()
    await ensureLoaded()

    expect(fetchStatsMock).toHaveBeenCalledTimes(1)
  })

  it('取得失敗時はerrorをセットし、isLoadedはfalseのまま(再試行可能)にする', async () => {
    fetchStatsMock.mockRejectedValue(new Error('network error'))

    await ensureLoaded()

    expect(stats.value).toBeNull()
    expect(isLoaded.value).toBe(false)
    expect(error.value).toBe('network error')
  })

  it('401の場合はhandleUnauthorizedを呼び、errorはセットしない', async () => {
    fetchStatsMock.mockRejectedValue(new ApiError('ログインが必要です', 401))

    await ensureLoaded()

    expect(handleUnauthorizedMock).toHaveBeenCalledTimes(1)
    expect(error.value).toBeNull()
  })

  it('reloadはisLoaded済みでも再フェッチする', async () => {
    fetchStatsMock.mockResolvedValue(statsFixture)

    await ensureLoaded()
    await reload()

    expect(fetchStatsMock).toHaveBeenCalledTimes(2)
  })

  it('ロード中にreloadを呼んだ場合、そのロードが完了した直後にもう一度フェッチが走る', async () => {
    let resolveFirst: (value: Stats) => void = () => {}
    const firstCall = new Promise<Stats>((resolve) => {
      resolveFirst = resolve
    })
    fetchStatsMock.mockReturnValueOnce(firstCall).mockResolvedValue(statsFixture)

    const ensurePromise = ensureLoaded()
    // 1回目のfetchが進行中(isLoading === true)の間にreloadを呼ぶ
    const reloadPromise = reload()

    expect(fetchStatsMock).toHaveBeenCalledTimes(1)

    resolveFirst(statsFixture)
    await ensurePromise
    await reloadPromise
    await vi.waitFor(() => expect(fetchStatsMock).toHaveBeenCalledTimes(2))
  })

  it('ロード中に呼んだreloadが返すPromiseは、実際の再フェッチの完了を待たずにresolveする', async () => {
    let resolveFirst: (value: Stats) => void = () => {}
    const firstCall = new Promise<Stats>((resolve) => {
      resolveFirst = resolve
    })
    fetchStatsMock.mockReturnValueOnce(firstCall).mockResolvedValue(statsFixture)

    const ensurePromise = ensureLoaded()
    let reloadResolved = false
    const reloadPromise = reload().then(() => {
      reloadResolved = true
    })

    await reloadPromise

    expect(reloadResolved).toBe(true)
    expect(fetchStatsMock).toHaveBeenCalledTimes(1)

    resolveFirst(statsFixture)
    await ensurePromise
  })
})
