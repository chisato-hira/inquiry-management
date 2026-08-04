import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { isOverdue } from './inquiry'

describe('isOverdue', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('未対応・ちょうど24時間00分00秒経過している場合はtrueを返す', () => {
    const now = new Date('2026-01-01T00:00:00Z')
    vi.setSystemTime(now)
    const created_at = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString()

    expect(isOverdue({ status: '未対応', created_at })).toBe(true)
  })

  it('未対応・24時間に1秒足りない(23時間59分59秒)場合はfalseを返す', () => {
    const now = new Date('2026-01-01T00:00:00Z')
    vi.setSystemTime(now)
    const created_at = new Date(now.getTime() - (24 * 60 * 60 * 1000 - 1000)).toISOString()

    expect(isOverdue({ status: '未対応', created_at })).toBe(false)
  })

  it('対応中・10日経過していても常にfalseを返す', () => {
    const created_at = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString()

    expect(isOverdue({ status: '対応中', created_at })).toBe(false)
  })

  it('完了・10日経過していても常にfalseを返す', () => {
    const created_at = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString()

    expect(isOverdue({ status: '完了', created_at })).toBe(false)
  })
})
