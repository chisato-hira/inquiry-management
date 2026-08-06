import type { Category, Inquiry, InquiriesResponse, Status } from '@/types/inquiry'
import { API_BASE_URL, request } from './http'

export type SortMode = 'received_at' | 'priority'

export interface CreateInquiryPayload {
  name: string
  email: string
  phone: string
  category: Category
  content: string
}

export function createInquiry(payload: CreateInquiryPayload): Promise<Inquiry> {
  return request<Inquiry>(new URL('/inquiries', API_BASE_URL), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ inquiry: payload }),
  })
}

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
