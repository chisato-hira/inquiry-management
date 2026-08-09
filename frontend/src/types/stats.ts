import type { Status, Category } from './inquiry'

export interface StaffIncompleteCount {
  staff_id: number | null // 末尾の「未割当」エントリはnull
  name: string
  count: number
}

export interface Stats {
  status_counts: Record<Status, number>
  category_counts: Record<Category, number>
  staff_incomplete_counts: StaffIncompleteCount[]
}
