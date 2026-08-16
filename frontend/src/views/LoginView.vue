<script setup lang="ts">
import { ref } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { ApiError } from '@/api/ApiError'

const { login } = useAuth()

const email = ref('')
const password = ref('')
const errorMessage = ref<string | null>(null)
const isSubmitting = ref(false)

async function handleSubmit() {
  isSubmitting.value = true
  errorMessage.value = null

  try {
    await login(email.value, password.value)
  } catch (e) {
    errorMessage.value = e instanceof ApiError ? e.message : 'ログインに失敗しました'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="flex min-h-screen items-center justify-center bg-slate-50 p-6">
    <form
      class="flex w-full max-w-md flex-col gap-4 rounded-lg border border-slate-200 bg-white p-6 shadow-sm"
      @submit.prevent="handleSubmit"
    >
      <div class="text-center">
        <h1 class="text-xl font-bold text-slate-900 sm:text-2xl">問い合わせ管理システム</h1>
        <p class="mt-1 text-sm text-slate-500">スタッフ専用ログイン</p>
      </div>

      <p v-if="errorMessage" class="text-sm text-red-600">{{ errorMessage }}</p>

      <label class="flex flex-col gap-1 text-sm text-slate-700">
        メールアドレス
        <input
          v-model="email"
          type="email"
          required
          class="rounded border border-slate-300 px-3 py-2 text-sm"
        />
      </label>

      <label class="flex flex-col gap-1 text-sm text-slate-700">
        パスワード
        <input
          v-model="password"
          type="password"
          required
          class="rounded border border-slate-300 px-3 py-2 text-sm"
        />
      </label>

      <button
        type="submit"
        class="rounded bg-slate-800 py-2 text-sm font-medium text-white disabled:opacity-50"
        :disabled="isSubmitting"
      >
        {{ isSubmitting ? 'ログイン中...' : 'ログイン' }}
      </button>
    </form>
  </div>
</template>
