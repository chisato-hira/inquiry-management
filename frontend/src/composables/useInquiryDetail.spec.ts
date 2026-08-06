import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ApiError } from '@/api/ApiError'
import type { Comment, InquiryDetail } from '@/types/inquiry'
import { useInquiryDetail } from './useInquiryDetail'

const fetchInquiryMock = vi.fn()
const updateInquiryMock = vi.fn()
const createCommentMock = vi.fn()
const handleUnauthorizedMock = vi.fn()

vi.mock('@/api/inquiries', () => ({
  fetchInquiry: (...args: unknown[]) => fetchInquiryMock(...args),
  updateInquiry: (...args: unknown[]) => updateInquiryMock(...args),
}))

vi.mock('@/api/comments', () => ({
  createComment: (...args: unknown[]) => createCommentMock(...args),
}))

vi.mock('./useAuth', () => ({
  useAuth: () => ({ handleUnauthorized: handleUnauthorizedMock }),
}))

function makeInquiry(overrides: Partial<InquiryDetail> = {}): InquiryDetail {
  return {
    id: 1,
    name: '山田太郎',
    email: 'yamada@example.com',
    phone: null,
    category: '不具合',
    content: '画面が表示されません',
    status: '未対応',
    priority: '未設定',
    lock_version: 0,
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
    staff: null,
    comments: [],
    ...overrides,
  }
}

describe('useInquiryDetail', () => {
  beforeEach(() => {
    fetchInquiryMock.mockReset()
    updateInquiryMock.mockReset()
    createCommentMock.mockReset()
    handleUnauthorizedMock.mockReset()
  })

  it('load成功時はinquiryを設定しerrorをクリアする', async () => {
    const detail = makeInquiry()
    fetchInquiryMock.mockResolvedValue(detail)

    const { inquiry, error, load } = useInquiryDetail(1)
    await load()

    expect(inquiry.value).toEqual(detail)
    expect(error.value).toBeNull()
  })

  it('load失敗時はerrorをセットし、inquiryはnullのまま変更しない', async () => {
    fetchInquiryMock.mockRejectedValue(new Error('network error'))

    const { inquiry, error, load } = useInquiryDetail(1)
    await load()

    expect(inquiry.value).toBeNull()
    expect(error.value).toBe('network error')
  })

  it('updateField成功時はPATCH後に再取得し、最新のinquiryに置き換えてtrueを返す', async () => {
    const initial = makeInquiry({ lock_version: 1 })
    const refreshed = makeInquiry({ lock_version: 2, status: '対応中' })
    fetchInquiryMock.mockResolvedValueOnce(initial).mockResolvedValueOnce(refreshed)
    updateInquiryMock.mockResolvedValue({ ...refreshed })

    const { inquiry, saveError, load, updateField } = useInquiryDetail(1)
    await load()

    const result = await updateField({ status: '対応中' })

    expect(result).toBe(true)
    expect(updateInquiryMock).toHaveBeenCalledWith(1, { status: '対応中', lock_version: 1 })
    expect(fetchInquiryMock).toHaveBeenCalledTimes(2)
    expect(inquiry.value).toEqual(refreshed)
    expect(saveError.value).toBeNull()
  })

  it('409競合時はsaveErrorに競合メッセージを残したまま、内部の再取得でinquiryを最新化する', async () => {
    // 再取得(load)自体は成功するため、内部でerror(取得系)はクリアされる。
    // ここではその再取得成功によってsaveError(保存系・競合メッセージ)まで消えてしまわないことを確認する。
    const initial = makeInquiry({ lock_version: 1 })
    const resynced = makeInquiry({ lock_version: 5, status: '完了' })
    fetchInquiryMock.mockResolvedValueOnce(initial).mockResolvedValueOnce(resynced)
    updateInquiryMock.mockRejectedValue(
      new ApiError('他のスタッフの操作により更新されています。最新の内容を確認してください', 409),
    )

    const { inquiry, error, saveError, load, updateField } = useInquiryDetail(1)
    await load()

    const result = await updateField({ status: '対応中' })

    expect(result).toBe(false)
    expect(saveError.value).toBe('他のスタッフの操作により更新されています。最新の内容を確認してください')
    expect(error.value).toBeNull()
    expect(inquiry.value).toEqual(resynced)
  })

  it('409以外のエラー時はsaveErrorにセットし、再取得は行わない', async () => {
    const initial = makeInquiry({ lock_version: 1 })
    fetchInquiryMock.mockResolvedValueOnce(initial)
    updateInquiryMock.mockRejectedValue(new ApiError('指定された担当者が見つかりません', 422))

    const { inquiry, saveError, load, updateField } = useInquiryDetail(1)
    await load()

    const result = await updateField({ staff_id: 999 })

    expect(result).toBe(false)
    expect(saveError.value).toBe('指定された担当者が見つかりません')
    expect(fetchInquiryMock).toHaveBeenCalledTimes(1)
    expect(inquiry.value).toEqual(initial)
  })

  it('updateFieldが401の場合はhandleUnauthorizedを呼び、saveErrorはセットしない', async () => {
    const initial = makeInquiry({ lock_version: 1 })
    fetchInquiryMock.mockResolvedValueOnce(initial)
    updateInquiryMock.mockRejectedValue(new ApiError('ログインが必要です', 401))

    const { saveError, load, updateField } = useInquiryDetail(1)
    await load()

    const result = await updateField({ status: '対応中' })

    expect(result).toBe(false)
    expect(handleUnauthorizedMock).toHaveBeenCalledTimes(1)
    expect(saveError.value).toBeNull()
  })

  it('addComment成功時はローカルにコメントを追記し、再取得は行わない', async () => {
    const initial = makeInquiry({ lock_version: 1, comments: [] })
    fetchInquiryMock.mockResolvedValueOnce(initial)
    const newComment: Comment = {
      id: 99,
      content: '対応済みです',
      comment_type: 'manual',
      created_at: '2026-01-02T00:00:00.000Z',
      staff: { id: 1, name: '山田太郎' },
    }
    createCommentMock.mockResolvedValue(newComment)

    const { inquiry, saveError, load, addComment } = useInquiryDetail(1)
    await load()

    const result = await addComment('対応済みです')

    expect(result).toBe(true)
    expect(inquiry.value?.comments).toEqual([newComment])
    expect(fetchInquiryMock).toHaveBeenCalledTimes(1)
    expect(saveError.value).toBeNull()
  })
})
