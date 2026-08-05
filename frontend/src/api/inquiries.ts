import type { InquiriesResponse, Status } from '@/types/inquiry'
import { API_BASE_URL, request } from './http'

export type SortMode = 'received_at' | 'priority'

export async function fetchInquiries(params: {
  status: Status
  page: number
  sort: SortMode
  signal?: AbortSignal
}): Promise<InquiriesResponse> {
  const url = new URL('/inquiries', API_BASE_URL)
  url.searchParams.set('status', params.status)
  url.searchParams.set('page', String(params.page))
  if (params.sort === 'priority') url.searchParams.set('sort', 'priority')

  return request<InquiriesResponse>(url, { signal: params.signal })
}
