import { ref } from 'vue'
import type { Inquiry, Status } from '@/types/inquiry'
import { updateInquiry } from '@/api/inquiries'
import { ApiError } from '@/api/ApiError'
import { useAuth } from './useAuth'

const draggedInquiry = ref<Inquiry | null>(null)
const movingIds = ref<Set<number>>(new Set())
const moveError = ref<string | null>(null)

export function useBoardDrag() {
  function startDrag(inquiry: Inquiry) {
    draggedInquiry.value = inquiry
  }

  function endDrag() {
    draggedInquiry.value = null
  }

  async function moveStatus(inquiry: Inquiry, status: Status, reload: () => Promise<unknown>) {
    if (inquiry.status === status || movingIds.value.has(inquiry.id)) return

    movingIds.value.add(inquiry.id)
    moveError.value = null

    try {
      await updateInquiry(inquiry.id, { status, lock_version: inquiry.lock_version })
      await reload()
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        useAuth().handleUnauthorized()
      } else if (e instanceof ApiError && e.status === 409) {
        moveError.value = '他のスタッフの操作により更新されています。最新の内容を確認してください'
        await reload()
      } else {
        moveError.value = e instanceof Error ? e.message : 'ステータスの変更に失敗しました'
      }
    } finally {
      movingIds.value.delete(inquiry.id)
    }
  }

  return { draggedInquiry, movingIds, moveError, startDrag, endDrag, moveStatus }
}
