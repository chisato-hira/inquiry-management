export type Category = '料金プラン' | '使い方' | '解約' | '不具合' | 'その他'
export type Status = '未対応' | '対応中' | '完了'
export type Priority = '未設定' | '高' | '中' | '低'

export interface Staff {
  id: number
  name: string
}

export interface Inquiry {
  id: number
  name: string
  email: string
  phone: string | null
  category: Category
  content: string
  status: Status
  priority: Priority | null
  lock_version: number
  created_at: string
  updated_at: string
  staff: Staff | null
}

export type CommentType = 'manual' | 'system'

export interface Comment {
  id: number
  content: string
  comment_type: CommentType
  created_at: string
  staff: Staff | null
}

export interface InquiryDetail extends Inquiry {
  comments: Comment[]
}

export interface InquiriesMeta {
  page: number
  per_page: number
  total_count: number
  has_more: boolean
}

export interface InquiriesResponse {
  inquiries: Inquiry[]
  meta: InquiriesMeta
}

export const STATUSES: Status[] = ['未対応', '対応中', '完了']

export const PRIORITIES: Priority[] = ['未設定', '高', '中', '低']

export const CATEGORIES: Category[] = ['料金プラン', '使い方', '解約', '不具合', 'その他']
