<script setup lang="ts">
import { computed } from 'vue'
import type { Inquiry } from '@/types/inquiry'
import { isOverdue } from '@/utils/inquiry'

const props = defineProps<{
  inquiry: Inquiry
}>()

const emit = defineEmits<{
  select: [id: number]
}>()

const overdue = computed(() => isOverdue(props.inquiry))
</script>

<template>
  <button
    type="button"
    class="w-full rounded-md border p-3 text-left shadow-sm"
    :class="overdue ? 'border-red-400 bg-red-50' : 'border-slate-200 bg-white'"
    @click="emit('select', inquiry.id)"
  >
    <p class="font-medium text-slate-900">{{ inquiry.name }}</p>
    <div class="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-sm text-slate-600">
      <span>{{ inquiry.category }}</span>
      <span>優先度: {{ inquiry.priority ?? '未設定' }}</span>
      <span>担当: {{ inquiry.staff?.name ?? '未割当' }}</span>
    </div>
  </button>
</template>
