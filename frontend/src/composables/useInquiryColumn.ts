import { ref } from 'vue'
import { fetchInquiries, type SortMode } from '@/api/inquiries'
import { ApiError } from '@/api/ApiError'
import type { Inquiry, Status } from '@/types/inquiry'
import { useAuth } from './useAuth'

export function useInquiryColumn(status: Status) {
  const inquiries = ref<Inquiry[]>([])
  const page = ref(1)
  const hasMore = ref(false)
  const totalCount = ref(0)
  const sortMode = ref<SortMode>('received_at')
  const isLoading = ref(true)
  const error = ref<string | null>(null)

  let currentController: AbortController | null = null

  async function fetchPage(targetPage: number, mode: 'replace' | 'append') {
    const controller = new AbortController()
    currentController?.abort()
    currentController = controller

    isLoading.value = true

    try {
      const res = await fetchInquiries({
        status,
        page: targetPage,
        sort: sortMode.value,
        signal: controller.signal,
      })

      if (controller !== currentController) return

      error.value = null
      inquiries.value = mode === 'replace' ? res.inquiries : [...inquiries.value, ...res.inquiries]
      page.value = res.meta.page
      hasMore.value = res.meta.has_more
      totalCount.value = res.meta.total_count
    } catch (e) {
      if (controller !== currentController) return

      if (e instanceof ApiError && e.status === 401) {
        useAuth().handleUnauthorized()
      }

      error.value = e instanceof Error ? e.message : '不明なエラーが発生しました'
    } finally {
      if (controller === currentController) {
        isLoading.value = false
      }
    }
  }

  function load() {
    return fetchPage(1, 'replace')
  }

  function loadMore() {
    if (!hasMore.value || isLoading.value) return
    return fetchPage(page.value + 1, 'append')
  }

  function toggleSort() {
    sortMode.value = sortMode.value === 'priority' ? 'received_at' : 'priority'
    return fetchPage(1, 'replace')
  }

  return { inquiries, hasMore, totalCount, isLoading, error, sortMode, load, loadMore, toggleSort }
}
