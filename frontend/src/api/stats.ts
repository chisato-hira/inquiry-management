import type { Stats } from '@/types/stats'
import { API_BASE_URL, request } from './http'

export function fetchStats(): Promise<Stats> {
  return request<Stats>(new URL('/stats', API_BASE_URL))
}
