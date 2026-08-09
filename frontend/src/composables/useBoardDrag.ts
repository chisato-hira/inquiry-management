import { ref } from 'vue'
import type { Inquiry, Status } from '@/types/inquiry'
import { updateInquiry } from '@/api/inquiries'
import { ApiError } from '@/api/ApiError'
import { useAuth } from './useAuth'

const draggedInquiry = ref<Inquiry | null>(null)
const movingIds = ref<Set<number>>(new Set())
const moveError = ref<string | null>(null)
// 失敗した操作とメッセージの結びつきが分かるよう、画面のどこかにバナーを出すのではなく
// 失敗したカード自体にエラーを表示する。表示先を特定するためどのカードで失敗したかを覚えておく
const moveErrorInquiryId = ref<number | null>(null)

export function useBoardDrag() {
  function startDrag(inquiry: Inquiry) {
    draggedInquiry.value = inquiry
  }

  function endDrag() {
    draggedInquiry.value = null
  }

  // 担当者の割り当てなど、ボードのD&D以外(詳細モーダル等)から該当の問い合わせが
  // 更新された場合にも、古くなったエラー表示を解除できるようにする
  function clearMoveError(inquiryId: number) {
    if (moveErrorInquiryId.value === inquiryId) {
      moveError.value = null
      moveErrorInquiryId.value = null
    }
  }

  async function moveStatus(inquiry: Inquiry, status: Status, reload: () => Promise<unknown>) {
    if (inquiry.status === status || movingIds.value.has(inquiry.id)) return

    movingIds.value.add(inquiry.id)
    moveError.value = null
    moveErrorInquiryId.value = null

    try {
      await updateInquiry(inquiry.id, { status, lock_version: inquiry.lock_version })
      await reload()
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        useAuth().handleUnauthorized()
      } else if (e instanceof ApiError && e.status === 409) {
        moveError.value = '他のスタッフの操作により更新されています。最新の内容を確認してください'
        moveErrorInquiryId.value = inquiry.id
        await reload()
      } else {
        moveError.value = e instanceof Error ? e.message : 'ステータスの変更に失敗しました'
        moveErrorInquiryId.value = inquiry.id
      }
    } finally {
      movingIds.value.delete(inquiry.id)
    }
  }

  return { draggedInquiry, movingIds, moveError, moveErrorInquiryId, startDrag, endDrag, moveStatus, clearMoveError }
}
