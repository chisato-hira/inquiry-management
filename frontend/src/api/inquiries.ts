import type { InquiriesResponse, Status } from '@/types/inquiry'

const API_BASE_URL = 'http://localhost:3000'

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

  const response = await fetch(url, { signal: params.signal })
  if (!response.ok) {
    throw new Error(`問い合わせの取得に失敗しました (status: ${response.status})`)
  }
  return response.json() as Promise<InquiriesResponse>
}
