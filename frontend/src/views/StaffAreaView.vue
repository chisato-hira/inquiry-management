<script setup lang="ts">
import { onMounted } from 'vue'
import BoardHeader from '@/components/BoardHeader.vue'
import SearchBox from '@/components/SearchBox.vue'
import LoginView from '@/views/LoginView.vue'
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
    <SearchBox />
    <RouterView />
  </template>
  <LoginView v-else />
</template>
