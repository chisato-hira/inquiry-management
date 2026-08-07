<script setup lang="ts">
import { useAuth } from '@/composables/useAuth'

const { currentStaff, logout } = useAuth()
</script>

<template>
  <div
    class="flex flex-col gap-2 border-b border-slate-200 bg-white px-4 py-3 lg:flex-row lg:items-center lg:justify-between lg:px-6"
  >
    <h1 class="text-lg font-semibold text-slate-900">Inquiry Board</h1>
    <div class="flex items-center gap-3 text-sm text-slate-600">
      <span>ログイン中: {{ currentStaff?.name }}</span>
      <button
        type="button"
        class="rounded border border-slate-300 px-3 py-1 text-slate-700"
        @click="logout"
      >
        ログアウト
      </button>
    </div>
  </div>
</template>
