<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import type { Inquiry, Status } from '@/types/inquiry'
import { useInquirySearch } from '@/composables/useInquirySearch'
import { useBoardDrag } from '@/composables/useBoardDrag'
import { useStats } from '@/composables/useStats'
import InquiryCard from '@/components/InquiryCard.vue'
import InquiryDetailModal from '@/components/InquiryDetailModal.vue'

const route = useRoute()
const { query, inquiries, hasMore, totalCount, isLoading, error, search, loadMore } = useInquirySearch()
const { moveStatus, clearAllMoveErrors } = useBoardDrag()
const { reload: reloadStats } = useStats()

const selectedInquiryId = ref<number | null>(null)
const pendingCompletionStatus = ref<Status | null>(null)

const hasSearched = computed(() => query.value.trim() !== '')
const isEmpty = computed(() => hasSearched.value && !isLoading.value && !error.value && inquiries.value.length === 0)

function selectCard(id: number) {
  selectedInquiryId.value = id
  pendingCompletionStatus.value = null
}

function closeModal() {
  selectedInquiryId.value = null
  pendingCompletionStatus.value = null
}

// ボード側のuseInquiryColumn各カラムには触れず、検索結果自体の再取得と統計の
// 再取得のみを行う(ボードに戻った時に統計が古いまま残るのを防ぐため明示的にreloadする)
function reloadSearchAndStats() {
  return Promise.all([search(), reloadStats()])
}

function moveOrOpenModal(inquiry: Inquiry, status: Status) {
  if (status === '完了' && !inquiry.staff) {
    selectedInquiryId.value = inquiry.id
    pendingCompletionStatus.value = '完了'
    return
  }
  moveStatus(inquiry, status, reloadSearchAndStats)
}

function onMoveStatus({ inquiry, status }: { inquiry: Inquiry; status: Status }) {
  moveOrOpenModal(inquiry, status)
}

onMounted(() => {
  // ボードでのD&D失敗により残ったmoveErrorが、無関係なこの画面のInquiryCardに
  // 漏れ出さないよう、検索結果画面に入るたびに無条件でリセットする
  clearAllMoveErrors()
})

// immediateを付けないとVueのwatchは初期値では発火せず、SearchBoxからの遷移・
// URL直接入力・リロードいずれでも最初の検索が実行されないバグになるため必須
watch(
  () => route.query.q,
  (q) => {
    query.value = typeof q === 'string' ? q : ''
    search()
  },
  { immediate: true },
)
</script>

<template>
  <main class="flex flex-col gap-3 p-4 lg:p-6">
    <div class="mx-auto flex w-full max-w-2xl flex-col gap-3">
      <RouterLink to="/" class="text-sm text-slate-600 hover:underline">← ボードに戻る</RouterLink>

      <h2 v-if="hasSearched" class="flex items-center gap-2 font-semibold text-slate-800">
        検索結果
        <span class="rounded-full bg-slate-200 px-2 py-0.5 text-xs font-medium text-slate-600">{{ totalCount }}</span>
      </h2>

      <p v-if="!hasSearched" class="text-sm text-slate-500">検索キーワードを入力してください</p>
      <p v-else-if="isLoading && inquiries.length === 0" class="text-sm text-slate-500">検索中...</p>
      <p v-else-if="error" class="text-sm text-red-600">検索に失敗しました: {{ error }}</p>
      <p v-else-if="isEmpty" class="text-sm text-slate-500">該当する問い合わせはありません</p>

      <div class="flex flex-col gap-2">
        <InquiryCard
          v-for="inquiry in inquiries"
          :key="inquiry.id"
          :inquiry="inquiry"
          @select="selectCard"
          @move-status="(status) => onMoveStatus({ inquiry, status })"
        />
      </div>

      <button
        v-if="hasMore"
        type="button"
        class="rounded border border-slate-300 bg-white py-1.5 text-sm text-slate-600 disabled:opacity-50"
        :disabled="isLoading"
        @click="loadMore"
      >
        {{ isLoading ? '読み込み中...' : 'もっと見る' }}
      </button>
    </div>

    <InquiryDetailModal
      v-if="selectedInquiryId"
      :key="selectedInquiryId"
      :inquiry-id="selectedInquiryId"
      :pending-status="pendingCompletionStatus"
      @close="closeModal"
      @updated="reloadSearchAndStats"
    />
  </main>
</template>
