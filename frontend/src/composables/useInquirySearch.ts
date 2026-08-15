import { ref } from 'vue'
import { searchInquiries } from '@/api/inquiries'
import { ApiError } from '@/api/ApiError'
import type { Inquiry } from '@/types/inquiry'
import { useAuth } from './useAuth'

// queryは「実行済み検索語」専用。書き込むのはSearchResultView.vueのルート監視のみに
// 限定し、SearchBox.vue側は入力中の下書きをローカルrefで別管理する(共有stateを
// 入力中の文字で汚染し、表示中の結果と無関係なページ取得や表示分岐が誤作動するのを防ぐ)
const query = ref('')
const inquiries = ref<Inquiry[]>([])
const page = ref(1)
const hasMore = ref(false)
const totalCount = ref(0)
const isLoading = ref(false)
const error = ref<string | null>(null)

let currentController: AbortController | null = null

export function useInquirySearch() {
  async function fetchPage(targetPage: number, mode: 'replace' | 'append') {
    const trimmed = query.value.trim()
    if (!trimmed) {
      currentController?.abort()
      currentController = null
      inquiries.value = []
      totalCount.value = 0
      hasMore.value = false
      isLoading.value = false
      error.value = null
      return
    }

    const controller = new AbortController()
    currentController?.abort()
    currentController = controller

    isLoading.value = true

    try {
      const res = await searchInquiries({ q: trimmed, page: targetPage, signal: controller.signal })

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

  function search() {
    return fetchPage(1, 'replace')
  }

  function loadMore() {
    if (!hasMore.value || isLoading.value) return
    return fetchPage(page.value + 1, 'append')
  }

  return { query, inquiries, hasMore, totalCount, isLoading, error, search, loadMore }
}
