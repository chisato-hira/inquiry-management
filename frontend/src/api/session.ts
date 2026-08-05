import type { Staff } from '@/types/inquiry'
import { API_BASE_URL, request } from './http'

export function login(email: string, password: string): Promise<Staff> {
  return request<Staff>(new URL('/session', API_BASE_URL), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  })
}

export function logout(): Promise<void> {
  return request<void>(new URL('/session', API_BASE_URL), { method: 'DELETE' })
}

export function fetchCurrentStaff(): Promise<Staff> {
  return request<Staff>(new URL('/session', API_BASE_URL))
}
