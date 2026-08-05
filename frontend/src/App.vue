<script setup lang="ts">
import { onMounted } from 'vue'
import BoardView from './components/BoardView.vue'
import BoardHeader from './components/BoardHeader.vue'
import LoginView from './views/LoginView.vue'
import { useAuth } from '@/composables/useAuth'

const { currentStaff, isCheckingSession, checkSession } = useAuth()

onMounted(() => {
  checkSession()
})
</script>

<template>
  <p v-if="isCheckingSession" class="p-6 text-sm text-slate-500">読み込み中...</p>
  <template v-else-if="currentStaff">
    <BoardHeader />
    <BoardView />
  </template>
  <LoginView v-else />
</template>
