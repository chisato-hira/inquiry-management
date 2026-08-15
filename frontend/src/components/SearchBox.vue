<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useInquirySearch } from '@/composables/useInquirySearch'

const router = useRouter()
const { query } = useInquirySearch()

// 「入力中の下書き」はローカルで持ち、composableの共有queryを入力中の文字で
// 汚染しない(共有queryは実行済み検索語専用。SearchResultView側のルート監視のみが書き込む)
const draftQuery = ref(query.value)

watch(query, (value) => {
  draftQuery.value = value
})

function onSubmit() {
  const trimmed = draftQuery.value.trim()
  router.push({ name: 'search', query: trimmed ? { q: trimmed } : {} })
}
</script>

<template>
  <form class="flex items-center gap-2 border-b border-slate-200 bg-white px-4 py-2 lg:px-6" @submit.prevent="onSubmit">
    <input
      v-model="draftQuery"
      type="search"
      placeholder="名前・メール・問い合わせ内容で検索"
      class="w-full max-w-md rounded border border-slate-300 px-3 py-1.5 text-sm focus:border-slate-500 focus:outline-none"
    />
    <button
      type="submit"
      class="shrink-0 rounded border border-slate-300 bg-white px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-100"
    >
      検索
    </button>
  </form>
</template>
