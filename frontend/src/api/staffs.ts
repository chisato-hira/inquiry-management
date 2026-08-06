import type { Staff } from '@/types/inquiry'
import { API_BASE_URL, request } from './http'

export function fetchStaffs(): Promise<Staff[]> {
  return request<Staff[]>(new URL('/staffs', API_BASE_URL))
}
