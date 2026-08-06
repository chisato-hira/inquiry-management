import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ApiError } from '@/api/ApiError'

const fetchStaffsMock = vi.fn()
const handleUnauthorizedMock = vi.fn()

vi.mock('@/api/staffs', () => ({
  fetchStaffs: (...args: unknown[]) => fetchStaffsMock(...args),
}))

vi.mock('./useAuth', () => ({
  useAuth: () => ({ handleUnauthorized: handleUnauthorizedMock }),
}))

import { useStaffs } from './useStaffs'

// useStaffsはモジュールレベルのsingleton状態を持つため、同じインスタンスをテスト間で
// 使い回し、beforeEachでrefの値を直接リセットする(vi.resetModules()での再読み込みは
// ApiErrorクラスの参照がテストファイル側と食い違いinstanceofが壊れるため使わない)。
const { staffs, isLoading, isLoaded, error, ensureLoaded } = useStaffs()

describe('useStaffs', () => {
  beforeEach(() => {
    fetchStaffsMock.mockReset()
    handleUnauthorizedMock.mockReset()
    staffs.value = []
    isLoading.value = false
    isLoaded.value = false
    error.value = null
  })

  it('ensureLoaded成功時にstaffsを設定しisLoadedをtrueにする', async () => {
    fetchStaffsMock.mockResolvedValue([{ id: 1, name: '山田太郎' }])

    await ensureLoaded()

    expect(staffs.value).toEqual([{ id: 1, name: '山田太郎' }])
    expect(isLoaded.value).toBe(true)
    expect(error.value).toBeNull()
  })

  it('既にロード済みの場合はensureLoadedを再度呼んでも再フェッチしない', async () => {
    fetchStaffsMock.mockResolvedValue([{ id: 1, name: '山田太郎' }])

    await ensureLoaded()
    await ensureLoaded()

    expect(fetchStaffsMock).toHaveBeenCalledTimes(1)
  })

  it('取得失敗時はerrorをセットし、isLoadedはfalseのまま(再試行可能)にする', async () => {
    fetchStaffsMock.mockRejectedValue(new Error('network error'))

    await ensureLoaded()

    expect(staffs.value).toEqual([])
    expect(isLoaded.value).toBe(false)
    expect(error.value).toBe('network error')
  })

  it('401の場合はhandleUnauthorizedを呼び、errorはセットしない', async () => {
    fetchStaffsMock.mockRejectedValue(new ApiError('ログインが必要です', 401))

    await ensureLoaded()

    expect(handleUnauthorizedMock).toHaveBeenCalledTimes(1)
    expect(error.value).toBeNull()
  })
})
