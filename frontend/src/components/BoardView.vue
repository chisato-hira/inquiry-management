<script setup lang="ts">
import BoardColumn from './BoardColumn.vue'
</script>

<template>
  <div class="flex gap-4 overflow-x-auto p-6">
    <BoardColumn status="未対応" title="未対応" />
    <BoardColumn status="対応中" title="対応中" />
    <BoardColumn status="完了" title="完了" />
  </div>
</template>
