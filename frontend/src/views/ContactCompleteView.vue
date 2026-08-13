<template>
  <div class="flex min-h-screen flex-col bg-slate-50">
    <header class="border-b border-slate-200 bg-white px-4 py-3 lg:px-6">
      <h1 class="text-lg font-semibold text-slate-900">お問い合わせ窓口</h1>
    </header>

    <div class="flex flex-1 items-center justify-center p-6">
      <div
        class="flex w-full max-w-md flex-col items-center gap-2 rounded-lg border border-slate-200 bg-white p-8 text-center shadow-sm"
      >
        <span class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100 text-green-600">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="h-6 w-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        </span>
        <h2 class="mt-2 text-lg font-semibold text-slate-900">お問い合わせありがとうございました</h2>
        <p class="text-sm text-slate-600">確認のご連絡までしばらくお待ちください。</p>
        <p class="text-xs text-slate-400">ご入力いただいたメールアドレス宛に確認メールをお送りしています。</p>
      </div>
    </div>
  </div>
</template>
