import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ApiError } from '@/api/ApiError'

const searchInquiriesMock = vi.fn()
const handleUnauthorizedMock = vi.fn()

vi.mock('@/api/inquiries', () => ({
  searchInquiries: (...args: unknown[]) => searchInquiriesMock(...args),
}))

vi.mock('./useAuth', () => ({
  useAuth: () => ({ handleUnauthorized: handleUnauthorizedMock }),
}))

import { useInquirySearch } from './useInquirySearch'

// useInquirySearchはモジュールレベルのsingleton状態を持つため、同じインスタンスを
// テスト間で使い回し、beforeEachでrefの値を直接リセットする(vi.resetModules()での
// 再読み込みはApiErrorクラスの参照がテストファイル側と食い違いinstanceofが壊れるため使わない)
const { query, inquiries, hasMore, totalCount, isLoading, error, search, loadMore } = useInquirySearch()

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

describe('useInquirySearch', () => {
  beforeEach(() => {
    searchInquiriesMock.mockReset()
    handleUnauthorizedMock.mockReset()
    query.value = ''
    inquiries.value = []
    hasMore.value = false
    totalCount.value = 0
    isLoading.value = false
    error.value = null
  })

  it('空文字でsearch()するとAPIを呼ばず結果が空になる', async () => {
    query.value = '   '

    await search()

    expect(searchInquiriesMock).not.toHaveBeenCalled()
    expect(inquiries.value).toEqual([])
    expect(totalCount.value).toBe(0)
  })

  it('検索成功時にinquiries・totalCount・hasMoreが更新される', async () => {
    query.value = '山田'
    searchInquiriesMock.mockResolvedValue({
      inquiries: [{ id: 1, name: '山田太郎' }],
      meta: { page: 1, per_page: 20, total_count: 1, has_more: false },
    })

    await search()

    expect(inquiries.value).toEqual([{ id: 1, name: '山田太郎' }])
    expect(totalCount.value).toBe(1)
    expect(hasMore.value).toBe(false)
    expect(error.value).toBeNull()
  })

  it('401エラー時はhandleUnauthorizedを呼ぶ', async () => {
    query.value = '山田'
    searchInquiriesMock.mockRejectedValue(new ApiError('ログインが必要です', 401))

    await search()

    expect(handleUnauthorizedMock).toHaveBeenCalledTimes(1)
  })

  it('連続してsearch()した場合、古いリクエストの結果は無視される', async () => {
    query.value = '山田'
    const first = deferred<{ inquiries: unknown[]; meta: { page: number; per_page: number; total_count: number; has_more: boolean } }>()
    const second = deferred<{ inquiries: unknown[]; meta: { page: number; per_page: number; total_count: number; has_more: boolean } }>()
    searchInquiriesMock.mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise)

    const firstSearch = search()
    const secondSearch = search()

    second.resolve({ inquiries: [{ id: 2 }], meta: { page: 1, per_page: 20, total_count: 1, has_more: false } })
    await secondSearch
    first.resolve({ inquiries: [{ id: 1 }], meta: { page: 1, per_page: 20, total_count: 1, has_more: false } })
    await firstSearch

    expect(inquiries.value).toEqual([{ id: 2 }])
  })

  it('loadMoreはhasMoreがfalseなら何もしない', async () => {
    hasMore.value = false

    await loadMore()

    expect(searchInquiriesMock).not.toHaveBeenCalled()
  })
})
