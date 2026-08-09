<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch, nextTick } from 'vue'
import type { Priority, Status } from '@/types/inquiry'
import { PRIORITIES, STATUSES } from '@/types/inquiry'
import { useInquiryDetail } from '@/composables/useInquiryDetail'
import { useStaffs } from '@/composables/useStaffs'
import { useBoardDrag } from '@/composables/useBoardDrag'

const props = defineProps<{
  inquiryId: number
  pendingStatus?: Status | null
}>()

const emit = defineEmits<{
  close: []
  updated: []
}>()

const { inquiry, isLoading, isSaving, error, saveError, load, updateField, addComment } =
  useInquiryDetail(props.inquiryId)
const {
  staffs,
  isLoading: isStaffsLoading,
  error: staffsError,
  ensureLoaded: ensureStaffsLoaded,
} = useStaffs()
const { clearMoveError } = useBoardDrag()

const newComment = ref('')
const savedMessage = ref<string | null>(null)
let savedMessageTimer: ReturnType<typeof window.setTimeout> | null = null

// 担当者未設定のまま完了しようとしてこのモーダルが開かれた場合、担当者を設定した
// 瞬間に自動でこのステータスも一緒に保存する。一度適用したらnullに戻す(一度きりの導線のため)
const localPendingStatus = ref<Status | null>(props.pendingStatus ?? null)
const staffSelect = ref<HTMLSelectElement | null>(null)

// 担当者設定と同時に完了した瞬間だけ、案内バナーの位置に緑の完了確認を出す
const justCompleted = ref(false)
let justCompletedTimer: ReturnType<typeof window.setTimeout> | null = null

onMounted(() => {
  load()
  ensureStaffsLoaded()
  window.addEventListener('keydown', onKeydown)
})

// 担当者未設定エラーからこのモーダルを開いた場合、データ読み込み完了(=担当者欄が
// DOMに現れるタイミング)を待ってから担当者欄へフォーカスする
watch(
  inquiry,
  async (value) => {
    if (!value || !localPendingStatus.value) return
    await nextTick()
    staffSelect.value?.focus()
  },
  { once: true },
)

onUnmounted(() => {
  window.removeEventListener('keydown', onKeydown)
  if (savedMessageTimer) clearTimeout(savedMessageTimer)
  if (justCompletedTimer) clearTimeout(justCompletedTimer)
})

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') requestClose()
}

function requestClose() {
  if (!isSaving.value) emit('close')
}

function showSaved(label: string) {
  savedMessage.value = `${label}を更新しました`
  if (savedMessageTimer) clearTimeout(savedMessageTimer)
  savedMessageTimer = window.setTimeout(() => {
    savedMessage.value = null
  }, 2000)
}

async function onStatusChange(event: Event) {
  const value = (event.target as HTMLSelectElement).value as Status
  if (await updateField({ status: value })) {
    emit('updated')
    showSaved('ステータス')
    clearMoveError(props.inquiryId)
  }
}

async function onPriorityChange(event: Event) {
  const value = (event.target as HTMLSelectElement).value as Priority
  if (await updateField({ priority: value })) {
    emit('updated')
    showSaved('優先度')
    clearMoveError(props.inquiryId)
  }
}

async function onStaffChange(event: Event) {
  const value = (event.target as HTMLSelectElement).value
  const staffId = value === '' ? '' : Number(value)
  const completeAtOnce = localPendingStatus.value === '完了' && staffId !== ''

  const patch: { staff_id: number | ''; status?: Status } = { staff_id: staffId }
  if (completeAtOnce) patch.status = localPendingStatus.value!

  if (await updateField(patch)) {
    emit('updated')
    showSaved(completeAtOnce ? '担当者・ステータス' : '担当者')
    clearMoveError(props.inquiryId)
    if (completeAtOnce) {
      localPendingStatus.value = null
      justCompleted.value = true
      if (justCompletedTimer) clearTimeout(justCompletedTimer)
      justCompletedTimer = window.setTimeout(() => {
        justCompleted.value = false
      }, 3000)
    }
  }
}

async function onAddComment() {
  const content = newComment.value.trim()
  if (!content) return
  if (await addComment(content)) newComment.value = ''
}

function formatDateTime(iso: string): string {
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}
</script>

<template>
  <Teleport to="body">
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" @click.self="requestClose">
      <div class="max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-lg bg-white p-6 shadow-lg">
        <h2 class="text-lg font-semibold text-slate-900">問い合わせ詳細</h2>

        <p v-if="isLoading && !inquiry" class="mt-4 text-sm text-slate-500">取得中...</p>
        <p v-else-if="error && !inquiry" class="mt-4 text-sm text-red-600">取得に失敗しました: {{ error }}</p>

        <div v-if="inquiry" class="mt-4 flex flex-col gap-4">
          <p v-if="error" class="text-sm text-amber-600">
            最新の情報を取得できませんでした。表示内容が古い可能性があります
          </p>

          <p
            v-if="localPendingStatus === '完了'"
            class="rounded-md border border-blue-200 bg-blue-50 px-3 py-2 text-sm text-blue-800"
          >
            担当者を設定すると「完了」になります
          </p>
          <p
            v-else-if="justCompleted"
            class="rounded-md border border-green-300 bg-green-50 px-3 py-2 text-sm font-medium text-green-800"
          >
            ✓「完了」にしました
          </p>

          <dl class="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-sm text-slate-700">
            <dt class="text-slate-500">氏名</dt>
            <dd>{{ inquiry.name }}</dd>
            <dt class="text-slate-500">メール</dt>
            <dd>{{ inquiry.email }}</dd>
            <dt class="text-slate-500">電話番号</dt>
            <dd>{{ inquiry.phone ?? '-' }}</dd>
            <dt class="text-slate-500">カテゴリ</dt>
            <dd>{{ inquiry.category }}</dd>
          </dl>

          <div>
            <p class="text-sm text-slate-500">内容</p>
            <p class="mt-1 whitespace-pre-wrap rounded border border-slate-200 bg-slate-50 p-2 text-sm text-slate-800">
              {{ inquiry.content }}
            </p>
          </div>

          <div class="flex flex-wrap gap-4">
            <label class="flex flex-col gap-1 text-sm text-slate-700">
              ステータス
              <select
                :value="inquiry.status"
                :disabled="isSaving"
                class="rounded border px-3 py-2 text-sm disabled:opacity-50"
                :class="inquiry.status === '完了' ? 'border-green-400 ring-2 ring-green-100' : 'border-slate-300'"
                @change="onStatusChange"
              >
                <option v-for="s in STATUSES" :key="s" :value="s">{{ s }}</option>
              </select>
            </label>

            <label class="flex flex-col gap-1 text-sm text-slate-700">
              優先度
              <select
                :value="inquiry.priority ?? '未設定'"
                :disabled="isSaving"
                class="rounded border border-slate-300 px-3 py-2 text-sm disabled:opacity-50"
                @change="onPriorityChange"
              >
                <option v-for="p in PRIORITIES" :key="p" :value="p">{{ p }}</option>
              </select>
            </label>

            <label class="flex flex-col gap-1 text-sm text-slate-700">
              担当者
              <select
                ref="staffSelect"
                :value="inquiry.staff?.id ?? ''"
                :disabled="isSaving || isStaffsLoading"
                class="rounded border px-3 py-2 text-sm disabled:opacity-50"
                :class="localPendingStatus === '完了' ? 'border-blue-400 ring-2 ring-blue-100' : 'border-slate-300'"
                @change="onStaffChange"
              >
                <option value="">未割当</option>
                <option v-for="s in staffs" :key="s.id" :value="s.id">{{ s.name }}</option>
              </select>
              <p v-if="staffsError" class="text-xs text-amber-600">担当者一覧の取得に失敗しました</p>
            </label>
          </div>

          <p v-if="saveError" class="text-sm text-red-600">{{ saveError }}</p>
          <p v-else-if="savedMessage" class="text-sm text-emerald-600">{{ savedMessage }}</p>

          <div>
            <p class="text-sm font-medium text-slate-700">対応履歴・コメント</p>
            <ul class="mt-2 flex flex-col gap-3">
              <li v-for="c in inquiry.comments" :key="c.id" class="text-sm text-slate-700">
                <p class="text-xs text-slate-500">
                  {{ formatDateTime(c.created_at) }}<span v-if="c.staff">&nbsp;{{ c.staff.name }}</span>
                </p>
                <p class="whitespace-pre-wrap">{{ c.content }}</p>
              </li>
            </ul>
          </div>

          <div class="flex flex-col gap-2">
            <textarea
              v-model="newComment"
              :disabled="isSaving"
              rows="3"
              placeholder="新しいコメントを入力..."
              class="rounded border border-slate-300 px-3 py-2 text-sm disabled:opacity-50"
            ></textarea>
            <button
              type="button"
              :disabled="isSaving || !newComment.trim()"
              class="self-end rounded bg-slate-800 px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
              @click="onAddComment"
            >
              追加する
            </button>
          </div>
        </div>

        <div class="mt-6 flex justify-end">
          <button
            type="button"
            :disabled="isSaving"
            class="rounded border border-slate-300 px-4 py-2 text-sm text-slate-700 disabled:opacity-50"
            @click="requestClose"
          >
            閉じる
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
