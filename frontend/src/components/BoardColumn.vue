<script setup lang="ts">
import { onMounted, computed, ref } from 'vue'
import type { Inquiry, Status } from '@/types/inquiry'
import { useInquiryColumn } from '@/composables/useInquiryColumn'
import { useBoardDrag } from '@/composables/useBoardDrag'
import InquiryCard from './InquiryCard.vue'

const props = defineProps<{
  status: Status
  title: string
}>()

const emit = defineEmits<{
  select: [id: number]
  drop: [status: Status]
  'move-status': [payload: { inquiry: Inquiry; status: Status }]
}>()

const { inquiries, hasMore, isLoading, error, sortMode, load, loadMore, toggleSort } =
  useInquiryColumn(props.status)
const { draggedInquiry } = useBoardDrag()

const isEmpty = computed(() => !isLoading.value && !error.value && inquiries.value.length === 0)

const dragCounter = ref(0)
const isDropTarget = computed(
  () => dragCounter.value > 0 && draggedInquiry.value !== null && draggedInquiry.value.status !== props.status,
)

function onDragEnter() {
  dragCounter.value++
}

function onDragLeave() {
  dragCounter.value = Math.max(0, dragCounter.value - 1)
}

function onDrop() {
  dragCounter.value = 0
  emit('drop', props.status)
}

onMounted(() => {
  load()
})

defineExpose({ reload: load })
</script>

<template>
  <!-- lg(1024px)未満は3カラムが収まらないため縦積み(1カラム)。カラム幅上限はmax-w-md(448px、lg以上でも共通)で、全幅ストレッチにも固定幅の窮屈さにもせず中間の見やすさを狙う。1024px以上は3カラムがflex-1で画面幅に応じて均等に伸縮し、448pxに達したら頭打ちになる(超ワイドモニターでカードが際限なく間延びしないため)。2xl(1536px)以上は上限をmax-w-lg(512px)に引き上げ、InquiryCard.vueの2xl:text-baseと連動させて「箱だけ広がって文字は据え置き」にならないようにする。詳細はIssue #39 -->
  <div
    class="mx-auto flex w-full max-w-md flex-col gap-3 rounded-lg border-2 p-3 transition-colors lg:mx-0 lg:w-auto lg:flex-1 2xl:max-w-lg"
    :class="isDropTarget ? 'border-blue-500 border-dashed bg-blue-50' : 'border-transparent bg-slate-100'"
    @dragover.prevent
    @dragenter.prevent="onDragEnter"
    @dragleave.prevent="onDragLeave"
    @drop.prevent="onDrop"
  >
    <div class="sticky top-0 z-10 flex flex-col gap-2 bg-slate-100 pb-2 lg:static lg:gap-3 lg:bg-transparent lg:pb-0">
      <div class="flex items-center justify-between">
        <h2 class="font-semibold text-slate-800">{{ title }}</h2>
        <button
          type="button"
          class="rounded border px-2 py-1 text-xs disabled:opacity-50"
          :class="
            sortMode === 'priority'
              ? 'border-slate-800 bg-slate-800 text-white'
              : 'border-slate-300 bg-white text-slate-600'
          "
          :disabled="isLoading"
          @click="toggleSort"
        >
          優先度順
        </button>
      </div>

      <p
        v-if="isDropTarget"
        class="rounded border-2 border-dashed border-blue-400 bg-blue-100 py-2 text-center text-sm font-semibold text-blue-700"
      >
        ここにドロップしてステータスを「{{ title }}」に変更
      </p>
    </div>

    <p v-if="isLoading && inquiries.length === 0" class="text-sm text-slate-500">取得中...</p>
    <p v-else-if="error" class="text-sm text-red-600">取得に失敗しました: {{ error }}</p>
    <p v-else-if="isEmpty" class="text-sm text-slate-500">該当する問い合わせはありません</p>

    <div class="flex flex-col gap-2">
      <InquiryCard
        v-for="inquiry in inquiries"
        :key="inquiry.id"
        :inquiry="inquiry"
        @select="emit('select', $event)"
        @move-status="(status) => emit('move-status', { inquiry, status })"
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
</template>
