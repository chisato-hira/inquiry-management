import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: () => import('@/views/StaffAreaView.vue'),
      children: [
        { path: '', name: 'staff-area', component: () => import('@/components/BoardView.vue') },
        { path: 'search', name: 'search', component: () => import('@/views/SearchResultView.vue') },
      ],
    },
    {
      path: '/contact',
      name: 'contact-form',
      component: () => import('@/views/ContactFormView.vue'),
    },
    {
      path: '/contact/complete',
      name: 'contact-complete',
      component: () => import('@/views/ContactCompleteView.vue'),
    },
  ],
})

export default router
