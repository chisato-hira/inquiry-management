<script setup lang="ts">
import { ref } from 'vue'
import type { Inquiry, Status } from '@/types/inquiry'
import BoardColumn from './BoardColumn.vue'
import InquiryDetailModal from './InquiryDetailModal.vue'
import { useBoardDrag } from '@/composables/useBoardDrag'

const selectedInquiryId = ref<number | null>(null)

const pendingColumn = ref<InstanceType<typeof BoardColumn> | null>(null)
const inProgressColumn = ref<InstanceType<typeof BoardColumn> | null>(null)
const doneColumn = ref<InstanceType<typeof BoardColumn> | null>(null)

const { draggedInquiry, moveError, endDrag, moveStatus } = useBoardDrag()

function reloadAllColumns() {
  return Promise.all([
    pendingColumn.value?.reload(),
    inProgressColumn.value?.reload(),
    doneColumn.value?.reload(),
  ])
}

function onDrop(status: Status) {
  const inquiry: Inquiry | null = draggedInquiry.value
  endDrag()
  if (!inquiry) return
  moveStatus(inquiry, status, reloadAllColumns)
}

function onMoveStatus({ inquiry, status }: { inquiry: Inquiry; status: Status }) {
  moveStatus(inquiry, status, reloadAllColumns)
}
</script>

<template>
  <div class="flex flex-col gap-3 p-6">
    <p v-if="moveError" class="text-sm text-red-600">{{ moveError }}</p>

    <div class="flex gap-4 overflow-x-auto">
      <BoardColumn
        ref="pendingColumn"
        status="未対応"
        title="未対応"
        @select="selectedInquiryId = $event"
        @drop="onDrop"
        @move-status="onMoveStatus"
      />
      <BoardColumn
        ref="inProgressColumn"
        status="対応中"
        title="対応中"
        @select="selectedInquiryId = $event"
        @drop="onDrop"
        @move-status="onMoveStatus"
      />
      <BoardColumn
        ref="doneColumn"
        status="完了"
        title="完了"
        @select="selectedInquiryId = $event"
        @drop="onDrop"
        @move-status="onMoveStatus"
      />

      <InquiryDetailModal
        v-if="selectedInquiryId"
        :key="selectedInquiryId"
        :inquiry-id="selectedInquiryId"
        @close="selectedInquiryId = null"
        @updated="reloadAllColumns"
      />
    </div>
  </div>
</template>
