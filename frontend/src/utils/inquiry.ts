import type { Inquiry } from '@/types/inquiry'

const OVERDUE_THRESHOLD_MS = 24 * 60 * 60 * 1000

export function isOverdue(inquiry: Pick<Inquiry, 'status' | 'created_at'>): boolean {
  if (inquiry.status !== '未対応') return false
  const elapsedMs = Date.now() - new Date(inquiry.created_at).getTime()
  return elapsedMs >= OVERDUE_THRESHOLD_MS
}
