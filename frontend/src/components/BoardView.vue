<script setup lang="ts">
import { ref } from 'vue'
import type { Inquiry, Status } from '@/types/inquiry'
import BoardColumn from './BoardColumn.vue'
import InquiryDetailModal from './InquiryDetailModal.vue'
import StatsPanel from './StatsPanel.vue'
import { useBoardDrag } from '@/composables/useBoardDrag'
import { useStats } from '@/composables/useStats'

const selectedInquiryId = ref<number | null>(null)
// 担当者未設定のまま「完了」にしようとした場合はエラーにせず、詳細モーダルを開いて
// 担当者設定と同時に完了させる導線に切り替える。そのモーダルにだけ渡す目印
const pendingCompletionStatus = ref<Status | null>(null)

const pendingColumn = ref<InstanceType<typeof BoardColumn> | null>(null)
const inProgressColumn = ref<InstanceType<typeof BoardColumn> | null>(null)
const doneColumn = ref<InstanceType<typeof BoardColumn> | null>(null)

const { draggedInquiry, endDrag, moveStatus } = useBoardDrag()
const { reload: reloadStats } = useStats()

function reloadAllColumns() {
  return Promise.all([
    pendingColumn.value?.reload(),
    inProgressColumn.value?.reload(),
    doneColumn.value?.reload(),
    reloadStats(),
  ])
}

function openForCompletion(inquiry: Inquiry) {
  selectedInquiryId.value = inquiry.id
  pendingCompletionStatus.value = '完了'
}

function selectCard(id: number) {
  selectedInquiryId.value = id
  pendingCompletionStatus.value = null
}

function closeModal() {
  selectedInquiryId.value = null
  pendingCompletionStatus.value = null
}

function moveOrOpenModal(inquiry: Inquiry, status: Status) {
  if (status === '完了' && !inquiry.staff) {
    openForCompletion(inquiry)
    return
  }
  moveStatus(inquiry, status, reloadAllColumns)
}

function onDrop(status: Status) {
  const inquiry: Inquiry | null = draggedInquiry.value
  endDrag()
  if (!inquiry) return
  moveOrOpenModal(inquiry, status)
}

function onMoveStatus({ inquiry, status }: { inquiry: Inquiry; status: Status }) {
  moveOrOpenModal(inquiry, status)
}
</script>

<template>
  <main class="flex flex-col gap-3 p-4 lg:p-6">
    <StatsPanel />

    <div class="flex flex-col gap-4 lg:flex-row lg:justify-center lg:overflow-x-auto">
      <BoardColumn
        ref="pendingColumn"
        status="未対応"
        title="未対応"
        @select="selectCard"
        @drop="onDrop"
        @move-status="onMoveStatus"
      />
      <BoardColumn
        ref="inProgressColumn"
        status="対応中"
        title="対応中"
        @select="selectCard"
        @drop="onDrop"
        @move-status="onMoveStatus"
      />
      <BoardColumn
        ref="doneColumn"
        status="完了"
        title="完了"
        @select="selectCard"
        @drop="onDrop"
        @move-status="onMoveStatus"
      />

      <InquiryDetailModal
        v-if="selectedInquiryId"
        :key="selectedInquiryId"
        :inquiry-id="selectedInquiryId"
        :pending-status="pendingCompletionStatus"
        @close="closeModal"
        @updated="reloadAllColumns"
      />
    </div>
  </main>
</template>
