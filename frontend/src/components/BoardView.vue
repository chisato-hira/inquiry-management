<script setup lang="ts">
import { ref } from 'vue'
import BoardColumn from './BoardColumn.vue'
import InquiryDetailModal from './InquiryDetailModal.vue'

const selectedInquiryId = ref<number | null>(null)

const pendingColumn = ref<InstanceType<typeof BoardColumn> | null>(null)
const inProgressColumn = ref<InstanceType<typeof BoardColumn> | null>(null)
const doneColumn = ref<InstanceType<typeof BoardColumn> | null>(null)

function reloadAllColumns() {
  pendingColumn.value?.reload()
  inProgressColumn.value?.reload()
  doneColumn.value?.reload()
}
</script>

<template>
  <div class="flex gap-4 overflow-x-auto p-6">
    <BoardColumn ref="pendingColumn" status="未対応" title="未対応" @select="selectedInquiryId = $event" />
    <BoardColumn ref="inProgressColumn" status="対応中" title="対応中" @select="selectedInquiryId = $event" />
    <BoardColumn ref="doneColumn" status="完了" title="完了" @select="selectedInquiryId = $event" />

    <InquiryDetailModal
      v-if="selectedInquiryId"
      :key="selectedInquiryId"
      :inquiry-id="selectedInquiryId"
      @close="selectedInquiryId = null"
      @updated="reloadAllColumns"
    />
  </div>
</template>
