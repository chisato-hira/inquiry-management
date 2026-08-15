<script setup lang="ts">
import { useAuth } from '@/composables/useAuth'

const { currentStaff, logout } = useAuth()
</script>

<template>
  <header
    class="flex flex-col gap-2 border-b border-slate-200 bg-white px-4 py-3 lg:flex-row lg:items-center lg:justify-between lg:px-6"
  >
    <RouterLink to="/" class="text-lg font-semibold text-slate-900 hover:underline">問い合わせボード</RouterLink>
    <div class="flex items-center gap-3 self-end text-sm lg:self-auto">
      <span class="font-medium text-slate-700">{{ currentStaff?.name }} さん</span>
      <button
        type="button"
        class="rounded border border-slate-300 px-2.5 py-1 text-xs text-slate-600 hover:bg-slate-100"
        @click="logout"
      >
        ログアウト
      </button>
    </div>
  </header>
</template>
