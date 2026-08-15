// @vitest-environment happy-dom
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ref } from 'vue'
import { mount } from '@vue/test-utils'
import type { Inquiry } from '@/types/inquiry'

const searchMock = vi.fn()
const loadMoreMock = vi.fn()
const reloadStatsMock = vi.fn()
const clearAllMoveErrorsMock = vi.fn()
const moveStatusMock = vi.fn()

const queryRef = ref('')
const inquiriesRef = ref<Inquiry[]>([])
const hasMoreRef = ref(false)
const totalCountRef = ref(0)
const isLoadingRef = ref(false)
const errorRef = ref<string | null>(null)

vi.mock('vue-router', () => ({
  useRoute: () => ({ query: { q: '山田' } }),
}))

vi.mock('@/composables/useInquirySearch', () => ({
  useInquirySearch: () => ({
    query: queryRef,
    inquiries: inquiriesRef,
    hasMore: hasMoreRef,
    totalCount: totalCountRef,
    isLoading: isLoadingRef,
    error: errorRef,
    search: searchMock,
    loadMore: loadMoreMock,
  }),
}))

vi.mock('@/composables/useBoardDrag', () => ({
  useBoardDrag: () => ({
    moveStatus: moveStatusMock,
    clearAllMoveErrors: clearAllMoveErrorsMock,
  }),
}))

vi.mock('@/composables/useStats', () => ({
  useStats: () => ({ reload: reloadStatsMock }),
}))

import SearchResultView from './SearchResultView.vue'

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

describe('SearchResultView', () => {
  beforeEach(() => {
    searchMock.mockReset()
    loadMoreMock.mockReset()
    reloadStatsMock.mockReset()
    clearAllMoveErrorsMock.mockReset()
    moveStatusMock.mockReset()
    queryRef.value = ''
    inquiriesRef.value = []
    hasMoreRef.value = false
    totalCountRef.value = 0
    isLoadingRef.value = false
    errorRef.value = null
  })

  it('初回マウント時にroute.query.qがqueryに反映され検索が実行される(immediate watchの回帰テスト)', () => {
    mount(SearchResultView, {
      global: { stubs: { InquiryCard: true, InquiryDetailModal: true } },
    })

    expect(queryRef.value).toBe('山田')
    expect(searchMock).toHaveBeenCalledTimes(1)
  })

  it('マウント時にuseBoardDrag().clearAllMoveErrorsを呼ぶ', () => {
    mount(SearchResultView, {
      global: { stubs: { InquiryCard: true, InquiryDetailModal: true } },
    })

    expect(clearAllMoveErrorsMock).toHaveBeenCalledTimes(1)
  })

  it('InquiryDetailModalのupdatedイベントで検索結果の再取得とuseStats().reload()の両方が呼ばれる', async () => {
    inquiriesRef.value = [makeInquiry({ id: 42 })]

    const wrapper = mount(SearchResultView, {
      global: { stubs: { InquiryCard: true, InquiryDetailModal: true } },
    })
    searchMock.mockClear() // マウント時のimmediate watch呼び出し分をリセット

    await wrapper.findComponent({ name: 'InquiryCard' }).vm.$emit('select', 42)
    await wrapper.findComponent({ name: 'InquiryDetailModal' }).vm.$emit('updated')

    expect(searchMock).toHaveBeenCalledTimes(1)
    expect(reloadStatsMock).toHaveBeenCalledTimes(1)
  })
})
