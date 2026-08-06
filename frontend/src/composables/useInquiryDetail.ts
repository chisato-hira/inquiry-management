import { ref } from 'vue'
import { fetchInquiry, updateInquiry } from '@/api/inquiries'
import { createComment } from '@/api/comments'
import { ApiError } from '@/api/ApiError'
import type { InquiryDetail, Priority, Status } from '@/types/inquiry'
import { useAuth } from './useAuth'

export function useInquiryDetail(id: number) {
  const inquiry = ref<InquiryDetail | null>(null)
  const isLoading = ref(true)
  const isSaving = ref(false)
  const error = ref<string | null>(null)
  const saveError = ref<string | null>(null)

  async function load() {
    isLoading.value = true

    try {
      const data = await fetchInquiry(id)
      inquiry.value = data
      error.value = null
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        useAuth().handleUnauthorized()
        return
      }
      // 失敗時もinquiry.valueは書き換えない(初回取得前はnullのまま、再取得失敗時は直前の内容を残す)
      error.value = e instanceof Error ? e.message : '不明なエラーが発生しました'
    } finally {
      isLoading.value = false
    }
  }

  async function updateField(patch: {
    status?: Status
    priority?: Priority
    staff_id?: number | ''
  }): Promise<boolean> {
    if (isSaving.value || !inquiry.value) return false

    isSaving.value = true
    saveError.value = null

    try {
      await updateInquiry(inquiry.value.id, { ...patch, lock_version: inquiry.value.lock_version })
      await load()
      return true
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        useAuth().handleUnauthorized()
        return false
      }
      if (e instanceof ApiError && e.status === 409) {
        saveError.value = e.message
        await load()
        return false
      }
      saveError.value = e instanceof Error ? e.message : '不明なエラーが発生しました'
      return false
    } finally {
      isSaving.value = false
    }
  }

  async function addComment(content: string): Promise<boolean> {
    if (isSaving.value || !inquiry.value) return false

    isSaving.value = true
    saveError.value = null

    try {
      const comment = await createComment(inquiry.value.id, content)
      inquiry.value.comments.push(comment)
      return true
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        useAuth().handleUnauthorized()
        return false
      }
      saveError.value = e instanceof Error ? e.message : '不明なエラーが発生しました'
      return false
    } finally {
      isSaving.value = false
    }
  }

  return { inquiry, isLoading, isSaving, error, saveError, load, updateField, addComment }
}
