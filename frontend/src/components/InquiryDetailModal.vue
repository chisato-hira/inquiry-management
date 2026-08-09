<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch, nextTick } from 'vue'
import type { Priority, Status } from '@/types/inquiry'
import { PRIORITIES, STATUSES } from '@/types/inquiry'
import { useInquiryDetail } from '@/composables/useInquiryDetail'
import { useStaffs } from '@/composables/useStaffs'
import { useBoardDrag } from '@/composables/useBoardDrag'
import { isOverdue } from '@/utils/inquiry'
import { CATEGORY_COLORS } from '@/utils/categoryColors'

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

const overdue = computed(() => (inquiry.value ? isOverdue(inquiry.value) : false))

// 優先度は「注意が必要な値だけ色を付ける」方針(ステータス/担当者selectの強調ルールと統一)。
// 低・未設定は強調不要なので中立の枠線のみにする
const priorityRingClass = computed(() => {
  switch (inquiry.value?.priority) {
    case '高':
      return 'border-red-400 ring-2 ring-red-100'
    case '中':
      return 'border-amber-400 ring-2 ring-amber-100'
    default:
      return 'border-slate-300'
  }
})

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
      <div class="flex max-h-[90vh] w-full flex-col bg-white shadow-lg sm:max-w-xl lg:max-w-2xl">
        <div class="shrink-0 rounded-t-lg border-b border-slate-200 bg-white px-6 py-4">
          <div class="flex items-center justify-between gap-4">
            <div v-if="inquiry" class="min-w-0 flex-1">
              <p class="text-xs tracking-wide text-slate-500 uppercase">問い合わせ詳細</p>
              <h2 class="truncate text-lg font-semibold text-slate-900">{{ inquiry.name }}</h2>
            </div>
            <h2 v-else class="text-lg font-semibold text-slate-900">問い合わせ詳細</h2>
            <button
              type="button"
              aria-label="閉じる"
              :disabled="isSaving"
              class="rounded p-1 text-slate-500 hover:bg-slate-100 hover:text-slate-700 focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-slate-500 disabled:opacity-50"
              @click="requestClose"
            >
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" d="M5 5l10 10M15 5L5 15" />
              </svg>
            </button>
          </div>
          <p
            v-if="inquiry && overdue"
            class="mt-2 inline-flex items-center gap-1 rounded-full bg-red-100 px-2.5 py-1 text-xs font-semibold text-red-700"
          >
            24時間経過
          </p>
        </div>

        <div v-if="inquiry" class="shrink-0 border-b border-slate-200 bg-white px-6 py-4">
          <div class="rounded-lg border border-slate-100 bg-slate-50 p-4">
            <p class="mb-3 text-sm font-medium text-slate-700">対応状況</p>
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <label class="flex flex-col gap-1 text-sm text-slate-700">
                ステータス
                <select
                  :value="inquiry.status"
                  :disabled="isSaving"
                  class="rounded border bg-white px-3 py-2 text-sm disabled:opacity-50"
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
                  class="rounded border bg-white px-3 py-2 text-sm disabled:opacity-50"
                  :class="priorityRingClass"
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
                  class="rounded border bg-white px-3 py-2 text-sm disabled:opacity-50"
                  :class="localPendingStatus === '完了' ? 'border-blue-400 ring-2 ring-blue-100' : 'border-slate-300'"
                  @change="onStaffChange"
                >
                  <option value="">未割当</option>
                  <option v-for="s in staffs" :key="s.id" :value="s.id">{{ s.name }}</option>
                </select>
                <p v-if="staffsError" class="text-xs text-amber-600">担当者一覧の取得に失敗しました</p>
              </label>
            </div>
          </div>
        </div>

        <div class="min-h-0 flex-1 overflow-y-auto px-6 py-4">
          <p v-if="isLoading && !inquiry" class="text-sm text-slate-500">取得中...</p>
          <p v-else-if="error && !inquiry" class="text-sm text-red-600">取得に失敗しました: {{ error }}</p>

          <div v-if="inquiry" class="flex flex-col gap-4">
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

            <p v-if="saveError" class="text-sm text-red-600">{{ saveError }}</p>
            <p v-else-if="savedMessage" class="text-sm text-emerald-600">{{ savedMessage }}</p>

            <dl class="grid grid-cols-[auto_minmax(0,1fr)] gap-x-3 gap-y-1.5 text-sm text-slate-700">
              <dt class="text-xs tracking-wide text-slate-500 uppercase">氏名</dt>
              <dd class="min-w-0 break-words">{{ inquiry.name }}</dd>
              <dt class="text-xs tracking-wide text-slate-500 uppercase">メール</dt>
              <dd class="min-w-0 break-words">{{ inquiry.email }}</dd>
              <dt class="text-xs tracking-wide text-slate-500 uppercase">電話番号</dt>
              <dd class="min-w-0 break-words">{{ inquiry.phone ?? '-' }}</dd>
              <dt class="text-xs tracking-wide text-slate-500 uppercase">カテゴリ</dt>
              <dd class="inline-flex min-w-0 items-center gap-1.5 break-words">
                <span
                  class="inline-block h-2 w-2 shrink-0 rounded-full"
                  :style="{ backgroundColor: CATEGORY_COLORS[inquiry.category] }"
                ></span>
                {{ inquiry.category }}
              </dd>
            </dl>

            <div>
              <p class="text-sm text-slate-500">内容</p>
              <p class="mt-1 border-l-4 border-slate-300 py-1 pl-3 text-sm whitespace-pre-wrap text-slate-800">
                {{ inquiry.content }}
              </p>
            </div>

            <div>
              <p class="text-sm font-medium text-slate-700">対応履歴・コメント</p>
              <ul class="mt-2 flex flex-col gap-2">
                <li v-for="c in inquiry.comments" :key="c.id">
                  <div
                    v-if="c.comment_type === 'manual'"
                    class="rounded-lg border border-slate-200 bg-white p-3 text-sm text-slate-700 shadow-sm"
                  >
                    <p class="text-xs text-slate-500">
                      <span v-if="c.staff" class="font-semibold text-slate-700">{{ c.staff.name }}</span>
                      &nbsp;{{ formatDateTime(c.created_at) }}
                    </p>
                    <p class="mt-1 whitespace-pre-wrap">{{ c.content }}</p>
                  </div>
                  <div v-else class="border-l-2 border-slate-200 py-0.5 pl-3 text-xs text-slate-500">
                    <p>{{ formatDateTime(c.created_at) }}</p>
                    <p class="whitespace-pre-wrap">{{ c.content }}</p>
                  </div>
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
        </div>

        <div class="flex shrink-0 justify-end rounded-b-lg border-t border-slate-200 bg-white px-6 py-4">
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
