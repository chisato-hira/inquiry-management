import { describe, it, expect, beforeEach } from 'vitest'
import { getCsrfToken, setCsrfToken, clearCsrfToken, csrfHeader } from './csrfToken'

describe('csrfToken', () => {
  beforeEach(() => {
    clearCsrfToken()
  })

  it('初期状態はnullを返す', () => {
    expect(getCsrfToken()).toBeNull()
  })

  it('setCsrfTokenで設定した値をgetCsrfTokenで取得できる', () => {
    setCsrfToken('token-abc')
    expect(getCsrfToken()).toBe('token-abc')
  })

  it('clearCsrfTokenを呼ぶとnullに戻る', () => {
    setCsrfToken('token-abc')
    clearCsrfToken()
    expect(getCsrfToken()).toBeNull()
  })

  it('csrfHeaderはX-CSRF-Tokenヘッダを返す', () => {
    setCsrfToken('token-abc')
    expect(csrfHeader()).toEqual({ 'X-CSRF-Token': 'token-abc' })
  })

  it('トークン未設定時のcsrfHeaderは空文字を返す', () => {
    expect(csrfHeader()).toEqual({ 'X-CSRF-Token': '' })
  })
})
