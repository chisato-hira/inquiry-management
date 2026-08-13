<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { createInquiry } from '@/api/inquiries'
import { CATEGORIES, type Category } from '@/types/inquiry'
import { ApiError } from '@/api/ApiError'
import { CATEGORY_COLORS } from '@/utils/categoryColors'

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
  <div class="flex min-h-screen flex-col bg-slate-50">
    <header class="border-b border-slate-200 bg-white px-4 py-3 lg:px-6">
      <h1 class="text-lg font-semibold text-slate-900">お問い合わせ窓口</h1>
    </header>

    <div class="flex flex-1 items-center justify-center p-6">
      <form
        class="flex w-full max-w-md flex-col gap-4 rounded-lg border border-slate-200 bg-white p-6 shadow-sm"
        @submit.prevent="handleSubmit"
      >
        <div>
          <h2 class="text-lg font-semibold text-slate-900">お問い合わせフォーム</h2>
          <p class="mt-1 text-sm text-slate-600">
            下記フォームに必要事項をご記入のうえ送信してください。
          </p>
        </div>

        <p v-if="errorMessage" class="rounded-md border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700">
          {{ errorMessage }}
        </p>

        <label class="flex flex-col gap-1 text-sm text-slate-700">
          氏名(必須)
          <input
            v-model="name"
            type="text"
            required
            maxlength="255"
            class="rounded border border-slate-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none focus:ring-2 focus:ring-slate-200"
          />
        </label>

        <label class="flex flex-col gap-1 text-sm text-slate-700">
          メールアドレス(必須)
          <input
            v-model="email"
            type="email"
            required
            maxlength="255"
            class="rounded border border-slate-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none focus:ring-2 focus:ring-slate-200"
          />
        </label>

        <label class="flex flex-col gap-1 text-sm text-slate-700">
          電話番号(任意)
          <input
            v-model="phone"
            type="tel"
            maxlength="20"
            class="rounded border border-slate-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none focus:ring-2 focus:ring-slate-200"
          />
        </label>

        <label class="flex flex-col gap-1 text-sm text-slate-700">
          カテゴリ(必須)
          <div class="flex items-center gap-2">
            <span
              v-if="category"
              class="inline-block h-2 w-2 shrink-0 rounded-full"
              :style="{ backgroundColor: CATEGORY_COLORS[category] }"
            ></span>
            <select
              v-model="category"
              required
              class="w-full rounded border border-slate-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none focus:ring-2 focus:ring-slate-200"
            >
              <option value="" disabled selected>選択してください</option>
              <option v-for="c in CATEGORIES" :key="c" :value="c">{{ c }}</option>
            </select>
          </div>
        </label>

        <label class="flex flex-col gap-1 text-sm text-slate-700">
          お問い合わせ内容(必須)
          <textarea
            v-model="content"
            required
            rows="6"
            class="rounded border border-slate-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none focus:ring-2 focus:ring-slate-200"
          ></textarea>
        </label>

        <button
          type="submit"
          class="rounded bg-slate-800 py-2 text-sm font-medium text-white hover:bg-slate-700 disabled:opacity-50"
          :disabled="isSubmitting"
        >
          {{ isSubmitting ? '送信中...' : '送信する' }}
        </button>
      </form>
    </div>
  </div>
</template>
