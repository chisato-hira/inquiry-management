import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ApiError } from '@/api/ApiError'
import type { Inquiry } from '@/types/inquiry'
import { useBoardDrag } from './useBoardDrag'

const updateInquiryMock = vi.fn()
const handleUnauthorizedMock = vi.fn()

vi.mock('@/api/inquiries', () => ({
  updateInquiry: (...args: unknown[]) => updateInquiryMock(...args),
}))

vi.mock('./useAuth', () => ({
  useAuth: () => ({ handleUnauthorized: handleUnauthorizedMock }),
}))

function makeInquiry(overrides: Partial<Inquiry> = {}): Inquiry {
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
    ...overrides,
  }
}

describe('useBoardDrag', () => {
  beforeEach(() => {
    updateInquiryMock.mockReset()
    handleUnauthorizedMock.mockReset()
    const { endDrag, movingIds, moveError, moveErrorInquiryId } = useBoardDrag()
    endDrag()
    movingIds.value.clear()
    moveError.value = null
    moveErrorInquiryId.value = null
  })

  it('同一ステータスへの移動はAPIを呼ばずno-opになる', async () => {
    const { moveStatus } = useBoardDrag()
    const reload = vi.fn()

    await moveStatus(makeInquiry({ status: '未対応' }), '未対応', reload)

    expect(updateInquiryMock).not.toHaveBeenCalled()
    expect(reload).not.toHaveBeenCalled()
  })

  it('成功時はmoveErrorをクリアし、reloadを呼び、movingIdsから該当IDを除去する', async () => {
    updateInquiryMock.mockResolvedValue({})
    const { moveStatus, movingIds, moveError, moveErrorInquiryId } = useBoardDrag()
    const reload = vi.fn().mockResolvedValue(undefined)

    await moveStatus(makeInquiry({ id: 1, status: '未対応' }), '対応中', reload)

    expect(updateInquiryMock).toHaveBeenCalledWith(1, { status: '対応中', lock_version: 0 })
    expect(reload).toHaveBeenCalled()
    expect(moveError.value).toBeNull()
    expect(moveErrorInquiryId.value).toBeNull()
    expect(movingIds.value.has(1)).toBe(false)
  })

  it('401時はhandleUnauthorizedを呼び、reloadは呼ばれない', async () => {
    updateInquiryMock.mockRejectedValue(new ApiError('unauthorized', 401))
    const { moveStatus } = useBoardDrag()
    const reload = vi.fn()

    await moveStatus(makeInquiry(), '対応中', reload)

    expect(handleUnauthorizedMock).toHaveBeenCalled()
    expect(reload).not.toHaveBeenCalled()
  })

  it('409時はmoveErrorとmoveErrorInquiryIdをセットし、reloadも呼ばれる', async () => {
    updateInquiryMock.mockRejectedValue(new ApiError('conflict', 409))
    const { moveStatus, moveError, moveErrorInquiryId } = useBoardDrag()
    const reload = vi.fn().mockResolvedValue(undefined)

    await moveStatus(makeInquiry({ id: 5 }), '対応中', reload)

    expect(moveError.value).toBe('他のスタッフの操作により更新されています。最新の内容を確認してください')
    expect(moveErrorInquiryId.value).toBe(5)
    expect(reload).toHaveBeenCalled()
  })

  it('その他エラー時はmoveErrorとmoveErrorInquiryIdをセットし、reloadは呼ばれない', async () => {
    updateInquiryMock.mockRejectedValue(new Error('network error'))
    const { moveStatus, moveError, moveErrorInquiryId } = useBoardDrag()
    const reload = vi.fn()

    await moveStatus(makeInquiry({ id: 7 }), '対応中', reload)

    expect(moveError.value).toBe('network error')
    expect(moveErrorInquiryId.value).toBe(7)
    expect(reload).not.toHaveBeenCalled()
  })

  it('clearMoveErrorは該当カードのエラーのみ解除する(詳細モーダル等、D&D以外からの更新成功時に使う)', async () => {
    updateInquiryMock.mockRejectedValue(new Error('network error'))
    const { moveStatus, moveError, moveErrorInquiryId, clearMoveError } = useBoardDrag()
    const reload = vi.fn()

    await moveStatus(makeInquiry({ id: 9 }), '対応中', reload)
    expect(moveErrorInquiryId.value).toBe(9)

    clearMoveError(10) // 別カードのIDを指定しても解除されない
    expect(moveErrorInquiryId.value).toBe(9)

    clearMoveError(9)
    expect(moveError.value).toBeNull()
    expect(moveErrorInquiryId.value).toBeNull()
  })

  it('別のカードで再度moveStatusを呼ぶと、前のカードのエラーはクリアされる', async () => {
    updateInquiryMock.mockRejectedValueOnce(new Error('network error'))
    updateInquiryMock.mockResolvedValueOnce({})
    const { moveStatus, moveError, moveErrorInquiryId } = useBoardDrag()
    const reload = vi.fn().mockResolvedValue(undefined)

    await moveStatus(makeInquiry({ id: 1 }), '対応中', reload)
    expect(moveErrorInquiryId.value).toBe(1)

    await moveStatus(makeInquiry({ id: 2 }), '対応中', reload)
    expect(moveError.value).toBeNull()
    expect(moveErrorInquiryId.value).toBeNull()
  })

  it('あるカードが更新中でも、別のカードのmoveStatus呼び出しは正常に実行される', async () => {
    let resolveFirst: (() => void) | undefined
    updateInquiryMock.mockImplementationOnce(
      () =>
        new Promise<void>((resolve) => {
          resolveFirst = resolve
        }),
    )
    updateInquiryMock.mockResolvedValueOnce({})

    const { moveStatus } = useBoardDrag()
    const reload = vi.fn().mockResolvedValue(undefined)

    const firstMove = moveStatus(makeInquiry({ id: 1 }), '対応中', reload)
    const secondMove = moveStatus(makeInquiry({ id: 2 }), '対応中', reload)

    await secondMove
    expect(updateInquiryMock).toHaveBeenCalledTimes(2)
    expect(reload).toHaveBeenCalledTimes(1)

    resolveFirst?.()
    await firstMove
    expect(reload).toHaveBeenCalledTimes(2)
  })

  it('同じカードへの二重のmoveStatus呼び出しは後者がno-opになる', async () => {
    let resolveFirst: (() => void) | undefined
    updateInquiryMock.mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveFirst = resolve
        }),
    )

    const { moveStatus } = useBoardDrag()
    const reload = vi.fn().mockResolvedValue(undefined)
    const inquiry = makeInquiry({ id: 1 })

    const firstMove = moveStatus(inquiry, '対応中', reload)
    await moveStatus(inquiry, '対応中', reload)

    expect(updateInquiryMock).toHaveBeenCalledTimes(1)

    resolveFirst?.()
    await firstMove
  })
})
