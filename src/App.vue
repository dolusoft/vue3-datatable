<script setup>
import { ref, computed } from 'vue';
import Default from './developer/Default.vue';
import Expandrow from './developer/Expandrow.vue';
import NotFound from './NotFound.vue';

const routes = {
    '/': Default,
    '/Expandrow': Expandrow,
};

const currentPath = ref(window.location.hash);

window.addEventListener('hashchange', () => {
    currentPath.value = window.location.hash;
});

const currentView = computed(() => {
    return routes[currentPath.value.slice(1) || '/'] || NotFound;
});
</script>

<template>
    <a href="/Default">Default</a> | <a href="/Expandrow">Expandrow</a>
    <component :is="currentView" />
</template>
