import type { Staff } from '@/types/inquiry'
import { API_BASE_URL, request } from './http'
import { clearCsrfToken, setCsrfToken } from './csrfToken'

type SessionResponse = Staff & { csrf_token: string }

export async function login(email: string, password: string): Promise<Staff> {
  const data = await request<SessionResponse>(new URL('/session', API_BASE_URL), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  })
  setCsrfToken(data.csrf_token)
  return { id: data.id, name: data.name }
}

export async function logout(): Promise<void> {
  try {
    await request<void>(new URL('/session', API_BASE_URL), { method: 'DELETE' })
  } finally {
    clearCsrfToken()
  }
}

export async function fetchCurrentStaff(): Promise<Staff> {
  const data = await request<SessionResponse>(new URL('/session', API_BASE_URL))
  setCsrfToken(data.csrf_token)
  return { id: data.id, name: data.name }
}
