import { ref } from 'vue'
import { fetchStaffs } from '@/api/staffs'
import { ApiError } from '@/api/ApiError'
import type { Staff } from '@/types/inquiry'
import { useAuth } from './useAuth'

const staffs = ref<Staff[]>([])
const isLoaded = ref(false)
const isLoading = ref(false)
const error = ref<string | null>(null)

export function useStaffs() {
  async function ensureLoaded() {
    if (isLoaded.value || isLoading.value) return

    isLoading.value = true

    try {
      staffs.value = await fetchStaffs()
      isLoaded.value = true
      error.value = null
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        useAuth().handleUnauthorized()
      } else {
        error.value = e instanceof Error ? e.message : '不明なエラーが発生しました'
      }
    } finally {
      isLoading.value = false
    }
  }

  return { staffs, isLoading, isLoaded, error, ensureLoaded }
}
