<script setup>
import { ref, computed } from 'vue'

import Default from './developer/Default.vue'
import Expandrow from './developer/Expandrow.vue'
import NotFound from './NotFound.vue'

const routes = {
  '/': Default,
  '/Default': Default,
  '/Expandrow': Expandrow
}

const currentPath = ref(window.location.pathname)

window.addEventListener('hashchange', () => {
  currentPath.value = window.location.pathname
})

const currentView = computed(() => {
  return routes[currentPath.value] || NotFound
})
</script>

<template>
  <a href="/Default">Default</a> | <a href="/Expandrow">Expandrow</a>
  <component :is="currentView" />
</template>

<style>
body {
  -webkit-text-size-adjust: 100%;
  font-feature-settings: normal;
  font-family:
    ui-sans-serif,
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    Segoe UI,
    Roboto,
    Helvetica Neue,
    Arial,
    Noto Sans,
    sans-serif,
    Apple Color Emoji,
    Segoe UI Emoji,
    Segoe UI Symbol,
    Noto Color Emoji;
  line-height: 1.5;
  -moz-tab-size: 4;
  -o-tab-size: 4;
  tab-size: 4;
}
</style>
