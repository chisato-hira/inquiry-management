import type { Category } from '@/types/inquiry'

// 統計パネル(カテゴリ別グラフ)とボードのカードタグで同じ色を使うための共通定義
export const CATEGORY_COLORS: Record<Category, string> = {
  料金プラン: '#2a78d6',
  使い方: '#eb6834',
  解約: '#1baf7a',
  不具合: '#eda100',
  その他: '#e87ba4',
}
