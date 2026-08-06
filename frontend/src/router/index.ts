import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'staff-area',
      component: () => import('@/views/StaffAreaView.vue'),
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
