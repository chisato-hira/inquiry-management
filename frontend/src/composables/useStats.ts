import { ref } from 'vue'
import { fetchStats } from '@/api/stats'
import { ApiError } from '@/api/ApiError'
import type { Stats } from '@/types/stats'
import { useAuth } from './useAuth'

const stats = ref<Stats | null>(null)
const isLoaded = ref(false)
const isLoading = ref(false)
const error = ref<string | null>(null)
let pendingReload = false

export function useStats() {
  async function load() {
    if (isLoading.value) {
      pendingReload = true
      return
    }

    isLoading.value = true

    try {
      stats.value = await fetchStats()
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
      if (pendingReload) {
        pendingReload = false
        load()
      }
    }
  }

  function ensureLoaded() {
    if (isLoaded.value || isLoading.value) return Promise.resolve()
    return load()
  }

  function reload() {
    return load()
  }

  return { stats, isLoading, isLoaded, error, ensureLoaded, reload }
}
