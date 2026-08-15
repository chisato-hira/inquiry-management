// @vitest-environment happy-dom
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'

const pushMock = vi.fn()

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: pushMock }),
}))

import { useInquirySearch } from '@/composables/useInquirySearch'
import SearchBox from './SearchBox.vue'

// useInquirySearchはモジュールレベルのsingleton状態を持つため、テスト間でrefを直接リセットする
const { query } = useInquirySearch()

describe('SearchBox', () => {
  beforeEach(() => {
    pushMock.mockReset()
    query.value = ''
  })

  it('入力中はcomposableの共有queryが変化しない(下書きとして分離されている)', async () => {
    const wrapper = mount(SearchBox)
    const input = wrapper.find('input')

    await input.setValue('山田')

    expect(query.value).toBe('')
  })

  it('送信するとtrimされた値でrouter.pushが呼ばれる', async () => {
    const wrapper = mount(SearchBox)
    const input = wrapper.find('input')

    await input.setValue('  山田  ')
    await wrapper.find('form').trigger('submit')

    expect(pushMock).toHaveBeenCalledWith({ name: 'search', query: { q: '山田' } })
  })

  it('空文字で送信するとqパラメータ無しでrouter.pushが呼ばれる', async () => {
    const wrapper = mount(SearchBox)
    const input = wrapper.find('input')

    await input.setValue('   ')
    await wrapper.find('form').trigger('submit')

    expect(pushMock).toHaveBeenCalledWith({ name: 'search', query: {} })
  })
})
