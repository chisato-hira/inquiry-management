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
  <div
    class="flex w-80 shrink-0 flex-col gap-3 rounded-lg border-2 p-3 transition-colors"
    :class="isDropTarget ? 'border-blue-500 border-dashed bg-blue-50' : 'border-transparent bg-slate-100'"
    @dragover.prevent
    @dragenter.prevent="onDragEnter"
    @dragleave.prevent="onDragLeave"
    @drop.prevent="onDrop"
  >
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
