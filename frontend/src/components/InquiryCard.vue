<script setup lang="ts">
import { computed } from 'vue'
import type { Inquiry, Status } from '@/types/inquiry'
import { STATUSES } from '@/types/inquiry'
import { isOverdue } from '@/utils/inquiry'
import { CATEGORY_COLORS } from '@/utils/categoryColors'
import { useBoardDrag } from '@/composables/useBoardDrag'

const props = defineProps<{
  inquiry: Inquiry
}>()

const emit = defineEmits<{
  select: [id: number]
  'move-status': [status: Status]
}>()

const { draggedInquiry, movingIds, moveError, moveErrorInquiryId, startDrag, endDrag } = useBoardDrag()

const overdue = computed(() => isOverdue(props.inquiry))
const isMoving = computed(() => movingIds.value.has(props.inquiry.id))
const isDragging = computed(() => draggedInquiry.value?.id === props.inquiry.id)
const hasMoveError = computed(() => moveErrorInquiryId.value === props.inquiry.id)

function onDragStart() {
  startDrag(props.inquiry)
}

function onDragEnd() {
  endDrag()
}

function onMobileStatusChange(event: Event) {
  const value = (event.target as HTMLSelectElement).value as Status
  emit('move-status', value)
}
</script>

<template>
  <div
    class="w-full cursor-grab rounded-md border p-3 shadow-sm active:cursor-grabbing"
    :class="[
      hasMoveError
        ? 'border-2 border-red-500 bg-red-100'
        : overdue
          ? 'border-red-400 bg-red-50'
          : 'border-slate-200 bg-white',
      isDragging ? 'opacity-40' : '',
    ]"
    :draggable="!isMoving"
    @dragstart="onDragStart"
    @dragend="onDragEnd"
  >
    <button type="button" class="w-full text-left" @click="emit('select', inquiry.id)">
      <p class="break-words font-medium text-slate-900">{{ inquiry.name }}</p>
      <div class="mt-1 flex flex-wrap gap-x-3 gap-y-1 break-words text-sm text-slate-600 2xl:text-base">
        <span class="inline-flex items-center gap-1.5">
          <span
            class="inline-block h-2 w-2 shrink-0 rounded-full"
            :style="{ backgroundColor: CATEGORY_COLORS[inquiry.category] }"
          ></span>
          {{ inquiry.category }}
        </span>
        <span>優先度: {{ inquiry.priority ?? '未設定' }}</span>
        <span :class="inquiry.staff ? '' : 'font-semibold text-amber-600'">
          担当: {{ inquiry.staff?.name ?? '未割当' }}
        </span>
      </div>
    </button>

    <label class="mt-2 block text-xs text-slate-600 lg:hidden" draggable="false">
      ステータス
      <select
        :value="inquiry.status"
        :disabled="isMoving"
        draggable="false"
        class="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm disabled:opacity-50"
        @mousedown.stop
        @click.stop
        @change="onMobileStatusChange"
      >
        <option v-for="s in STATUSES" :key="s" :value="s">{{ s }}</option>
      </select>
    </label>

    <p v-if="hasMoveError" class="mt-2 text-xs font-semibold text-red-700" draggable="false">
      {{ moveError }}
    </p>
  </div>
</template>
