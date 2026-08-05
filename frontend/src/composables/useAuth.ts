import { ref } from 'vue'
import type { Staff } from '@/types/inquiry'
import { login as loginApi, logout as logoutApi, fetchCurrentStaff } from '@/api/session'

const currentStaff = ref<Staff | null>(null)
const isCheckingSession = ref(true)

export function useAuth() {
  async function checkSession() {
    try {
      currentStaff.value = await fetchCurrentStaff()
    } catch {
      // 未ログイン、またはセッション確認自体に失敗した場合も未ログイン扱いにする
      currentStaff.value = null
    } finally {
      isCheckingSession.value = false
    }
  }

  async function login(email: string, password: string) {
    currentStaff.value = await loginApi(email, password)
  }

  async function logout() {
    try {
      await logoutApi()
    } catch {
      // ネットワークエラーでも、ローカルはログアウト済み扱いにする
    } finally {
      currentStaff.value = null
    }
  }

  function handleUnauthorized() {
    currentStaff.value = null
  }

  return { currentStaff, isCheckingSession, checkSession, login, logout, handleUnauthorized }
}
