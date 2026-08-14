<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { Chart, BarController, BarElement, CategoryScale, LinearScale, Tooltip } from 'chart.js'
import type { ChartOptions, Plugin } from 'chart.js'
import { useStats } from '@/composables/useStats'
import { STATUSES, CATEGORIES } from '@/types/inquiry'
import { CATEGORY_COLORS } from '@/utils/categoryColors'

// 棒の下に別途テキストで数字を書くと「結局そこだけ読んでグラフを見ない」状態になるため、
// 数値を棒に直接描画し、グラフを見るだけで正確な件数までわかるようにする
// (chartjs-plugin-datalabelsを追加導入せず、依存を増やさない方針を維持するために自前実装する)
const barValueLabelsPlugin: Plugin<'bar'> = {
  id: 'barValueLabels',
  afterDatasetsDraw(chart) {
    const { ctx } = chart
    const isHorizontal = chart.options.indexAxis === 'y'
    chart.data.datasets.forEach((dataset, datasetIndex) => {
      const meta = chart.getDatasetMeta(datasetIndex)
      meta.data.forEach((element, index) => {
        const value = dataset.data[index]
        if (typeof value !== 'number') return
        const pos = element.tooltipPosition(true)
        if (pos.x === null || pos.y === null) return
        ctx.save()
        ctx.fillStyle = '#334155'
        ctx.font = '12px sans-serif'
        if (isHorizontal) {
          ctx.textAlign = 'left'
          ctx.textBaseline = 'middle'
          ctx.fillText(String(value), pos.x + 6, pos.y)
        } else {
          ctx.textAlign = 'center'
          ctx.textBaseline = 'bottom'
          ctx.fillText(String(value), pos.x, pos.y - 4)
        }
        ctx.restore()
      })
    })
  },
}

Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip, barValueLabelsPlugin)

const STATUS_COLORS: Record<string, string> = { 未対応: '#d03b3b', 対応中: '#fab219', 完了: '#0ca30c' }
const STAFF_COLOR = '#2a78d6'
const UNASSIGNED_COLOR = '#94a3b8' // 実在の担当者と区別するため、未割当バケットだけ中立色にする

const BAR_OPTIONS: ChartOptions<'bar'> = {
  responsive: true,
  maintainAspectRatio: false,
  // 棒の上に数値ラベルを描画するため、上に少し余白を持たせてラベルが切れないようにする
  layout: { padding: { top: 16 } },
  scales: { y: { beginAtZero: true, ticks: { precision: 0 } } },
}

const { stats, isLoading, error, ensureLoaded } = useStats()

// 「未完了合計」という数値だけだと3ステータスの合計だと伝わりにくいため、
// 全体に占める割合を帯グラフ+具体的な分数のラベルで見せる
const totalCount = computed(() => {
  if (!stats.value) return 0
  return STATUSES.reduce((sum, s) => sum + stats.value!.status_counts[s], 0)
})
const incompleteTotal = computed(() => {
  if (!stats.value) return 0
  return stats.value.status_counts['未対応'] + stats.value.status_counts['対応中']
})
const completedPercent = computed(() => {
  if (totalCount.value === 0) return 0
  return Math.round((stats.value!.status_counts['完了'] / totalCount.value) * 100)
})

const staffChartHeightPx = computed(() => {
  const count = stats.value?.staff_incomplete_counts.length ?? 0
  return Math.max(160, count * 36)
})

const categoryCanvas = ref<HTMLCanvasElement | null>(null)
const staffCanvas = ref<HTMLCanvasElement | null>(null)
let categoryChart: Chart | null = null
let staffChart: Chart | null = null

function renderCharts() {
  if (!stats.value) return
  const categoryData = CATEGORIES.map((c) => stats.value!.category_counts[c])
  const staffLabels = stats.value.staff_incomplete_counts.map((s) => s.name)
  const staffData = stats.value.staff_incomplete_counts.map((s) => s.count)
  const staffColors = stats.value.staff_incomplete_counts.map((s) =>
    s.staff_id === null ? UNASSIGNED_COLOR : STAFF_COLOR,
  )

  if (categoryChart) {
    categoryChart.data.datasets[0]!.data = categoryData
    categoryChart.update()
  } else if (categoryCanvas.value) {
    categoryChart = new Chart(categoryCanvas.value, {
      type: 'bar',
      data: {
        labels: CATEGORIES,
        datasets: [
          { data: categoryData, backgroundColor: CATEGORIES.map((c) => CATEGORY_COLORS[c]), borderRadius: 4 },
        ],
      },
      options: BAR_OPTIONS,
    })
  }

  if (staffChart) {
    staffChart.data.labels = staffLabels
    staffChart.data.datasets[0]!.data = staffData
    staffChart.data.datasets[0]!.backgroundColor = staffColors
    staffChart.update()
  } else if (staffCanvas.value) {
    staffChart = new Chart(staffCanvas.value, {
      type: 'bar',
      data: { labels: staffLabels, datasets: [{ data: staffData, backgroundColor: staffColors, borderRadius: 4 }] },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        // 棒の右側に数値ラベルを描画するため、右に余白を持たせてラベルが切れないようにする
        layout: { padding: { right: 28 } },
        scales: { x: { beginAtZero: true, ticks: { precision: 0 } } },
      },
    })
  }
}

let resizeFrame: number | null = null
function resizeCharts() {
  // ドラッグでのウィンドウリサイズ中にresizeが高頻度発火しても、
  // 1フレームに1回だけresize()するよう間引く
  if (resizeFrame !== null) return
  resizeFrame = requestAnimationFrame(() => {
    categoryChart?.resize()
    staffChart?.resize()
    resizeFrame = null
  })
}

// pre-flush(デフォルト)だとDOM更新前に走ってしまい、初回ロード時はcanvasがまだ
// マウントされていないためグラフが作られない。post-flushにしてDOM更新後に実行する。
// これはBoardView側でのステータス変更等によるreload()後の再描画をカバーするためのもの。
watch(stats, renderCharts, { flush: 'post' })

onMounted(async () => {
  // lg:ブレークポイントをまたいでhidden→表示に変わる際、canvas生成時点では
  // 祖先がdisplay:noneだったため、Chart.js自身のResizeObserverだけに頼らず
  // window resizeで明示的にresize()する
  window.addEventListener('resize', resizeCharts)

  // statsが既に読み込み済みの場合、ensureLoaded()は再取得せずに即resolveするため
  // statsの値は変化せず、上のwatchは発火しない(ログイン後の再マウント等で起きる)。
  // マウント時点でのstatsの状態に関わらず必ず描画されるよう、ここで明示的に呼ぶ
  await ensureLoaded()
  renderCharts()
})
onUnmounted(() => {
  window.removeEventListener('resize', resizeCharts)
  if (resizeFrame !== null) cancelAnimationFrame(resizeFrame)
  categoryChart?.destroy()
  staffChart?.destroy()
})
</script>

<template>
  <div class="flex flex-col gap-3 rounded-lg border border-slate-200 bg-white p-3 lg:p-4">
    <p v-if="isLoading && !stats" class="text-sm text-slate-500">統計情報を読み込み中...</p>
    <p v-if="error" class="text-sm text-red-600">{{ error }}</p>

    <template v-if="stats">
      <!-- 今どのくらいタスクがあるかを一目で把握するためのKPI。下の帯グラフと同じ色を
           タイルの上部にも付け、どの数字がどのバー色に対応するか一目でわかるようにする -->
      <div class="grid grid-cols-3 gap-2 lg:w-fit lg:gap-4">
        <div
          v-for="s in STATUSES"
          :key="s"
          class="rounded-md border-t-4 bg-slate-50 px-3 py-2 text-center"
          :style="{ borderTopColor: STATUS_COLORS[s] }"
        >
          <p class="text-3xl font-semibold text-slate-900">
            {{ stats.status_counts[s] }}<span class="ml-0.5 text-sm font-normal text-slate-500">件</span>
          </p>
          <p class="text-xs text-slate-500">{{ s }}</p>
        </div>
      </div>

      <!-- 「未完了合計」を単独の数値で見せると意味が伝わりにくいため、
           全体に占める割合を帯グラフ+具体的な分数のラベルで見せる -->
      <div>
        <div class="flex h-3 w-full overflow-hidden rounded-full bg-slate-100">
          <div
            v-for="s in STATUSES"
            :key="s"
            class="h-full"
            :style="{ flexGrow: stats.status_counts[s], backgroundColor: STATUS_COLORS[s] }"
          ></div>
        </div>
        <p class="mt-1 text-sm text-slate-700">
          未完了 {{ incompleteTotal }}件 / 全{{ totalCount }}件({{ completedPercent }}%完了)
        </p>
      </div>

      <div class="hidden lg:grid lg:grid-cols-2 lg:gap-4">
        <div>
          <h2 class="mb-2 text-sm font-semibold text-slate-800">カテゴリ別件数</h2>
          <div class="relative h-48">
            <canvas ref="categoryCanvas" aria-label="カテゴリ別件数の棒グラフ(各バーに件数を表示)" role="img"></canvas>
          </div>
        </div>
        <div>
          <h2 class="mb-2 text-sm font-semibold text-slate-800">担当者別未完了件数</h2>
          <div class="relative" :style="{ height: `${staffChartHeightPx}px` }">
            <canvas ref="staffCanvas" aria-label="担当者別未完了件数の横棒グラフ(各バーに件数を表示)" role="img"></canvas>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
