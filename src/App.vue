<script setup>
import { ref, computed } from 'vue';
import Default from './developer/Default.vue';
import Expandrow from './developer/Expandrow.vue';
import NotFound from './NotFound.vue';

const routes = {
    '/': Default,
    '/Default': Default,
    '/Expandrow': Expandrow,
};

const currentPath = ref(window.location.pathname);

window.addEventListener('hashchange', () => {
    currentPath.value = window.location.pathname;
});

const currentView = computed(() => {
    return routes[currentPath.value] || NotFound;
});
</script>

<template>
    <a href="/Default">Default</a> | <a href="/Expandrow">Expandrow</a>
    <component :is="currentView" />
</template>
