import type { Comment } from '@/types/inquiry'
import { API_BASE_URL, request } from './http'
import { csrfHeader } from './csrfToken'

export function createComment(inquiryId: number, content: string): Promise<Comment> {
  return request<Comment>(new URL(`/inquiries/${inquiryId}/comments`, API_BASE_URL), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...csrfHeader() },
    body: JSON.stringify({ comment: { content } }),
  })
}
