<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { createInquiry } from '@/api/inquiries'
import { CATEGORIES, type Category } from '@/types/inquiry'
import { ApiError } from '@/api/ApiError'

const router = useRouter()

const name = ref('')
const email = ref('')
const phone = ref('')
const category = ref<Category | ''>('')
const content = ref('')
const errorMessage = ref<string | null>(null)
const isSubmitting = ref(false)

async function handleSubmit() {
  isSubmitting.value = true
  errorMessage.value = null

  try {
    await createInquiry({
      name: name.value,
      email: email.value,
      phone: phone.value,
      category: category.value as Category,
      content: content.value,
    })
    router.push({ name: 'contact-complete' })
  } catch (e) {
    errorMessage.value = e instanceof ApiError ? e.message : '送信に失敗しました'
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
      <h1 class="text-lg font-semibold text-slate-900">お問い合わせフォーム</h1>

      <p v-if="errorMessage" class="text-sm text-red-600">{{ errorMessage }}</p>

      <label class="flex flex-col gap-1 text-sm text-slate-700">
        氏名(必須)
        <input
          v-model="name"
          type="text"
          required
          maxlength="255"
          class="rounded border border-slate-300 px-3 py-2 text-sm"
        />
      </label>

      <label class="flex flex-col gap-1 text-sm text-slate-700">
        メールアドレス(必須)
        <input
          v-model="email"
          type="email"
          required
          maxlength="255"
          class="rounded border border-slate-300 px-3 py-2 text-sm"
        />
      </label>

      <label class="flex flex-col gap-1 text-sm text-slate-700">
        電話番号(任意)
        <input
          v-model="phone"
          type="tel"
          maxlength="20"
          class="rounded border border-slate-300 px-3 py-2 text-sm"
        />
      </label>

      <label class="flex flex-col gap-1 text-sm text-slate-700">
        カテゴリ(必須)
        <select
          v-model="category"
          required
          class="rounded border border-slate-300 px-3 py-2 text-sm"
        >
          <option value="" disabled selected>選択してください</option>
          <option v-for="c in CATEGORIES" :key="c" :value="c">{{ c }}</option>
        </select>
      </label>

      <label class="flex flex-col gap-1 text-sm text-slate-700">
        お問い合わせ内容(必須)
        <textarea
          v-model="content"
          required
          rows="6"
          class="rounded border border-slate-300 px-3 py-2 text-sm"
        ></textarea>
      </label>

      <button
        type="submit"
        class="rounded bg-slate-800 py-2 text-sm font-medium text-white disabled:opacity-50"
        :disabled="isSubmitting"
      >
        {{ isSubmitting ? '送信中...' : '送信する' }}
      </button>
    </form>
  </div>
</template>
