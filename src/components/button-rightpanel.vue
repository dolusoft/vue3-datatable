<script lang="ts">
export default {
    name: 'ButtonRightPanel'
}
</script>
<script setup lang="ts">
import { Icon } from '@iconify/vue'

interface Props {
    item?: any
}

const props = withDefaults(defineProps<Props>(), {
    item: []
})

const emit = defineEmits(['rightPanelClick'])

function openRightPanel() {
    emit('rightPanelClick', props.item)
}
</script>
<template>
    <button class="rightpanelbtn" @click.stop="openRightPanel">
        <Icon icon="lucide:plus" />
    </button>
</template>
<style scoped>
.rightpanelbtn {
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 24px;
    height: 24px;
}
</style>
