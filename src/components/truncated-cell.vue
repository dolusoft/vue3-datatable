<script setup lang="ts">
import { ref, onMounted, onUpdated, computed } from 'vue'

const props = defineProps<{
  value: any
  truncate: boolean
  maxWidth?: string
  truncateLines: number
  showTooltip: boolean
  html?: boolean
}>()

const cellRef = ref<HTMLElement | null>(null)
const isOverflowing = ref(false)

// Check if content overflows
const checkOverflow = () => {
  if (cellRef.value && props.truncate) {
    const el = cellRef.value
    // For single line: scrollWidth > clientWidth
    // For multi-line: scrollHeight > clientHeight
    if (props.truncateLines === 1) {
      isOverflowing.value = el.scrollWidth > el.clientWidth
    } else {
      isOverflowing.value = el.scrollHeight > el.clientHeight
    }
  } else {
    isOverflowing.value = false
  }
}

onMounted(checkOverflow)
onUpdated(checkOverflow)

// Tooltip content - display the full value
const tooltipContent = computed(() => {
  return String(props.value ?? '')
})

// Should show tooltip?
const shouldShowTooltip = computed(() => {
  return props.truncate && props.showTooltip && isOverflowing.value
})

// Cell style
const cellStyle = computed(() => {
  if (!props.truncate) return {}

  const style: Record<string, any> = {}
  if (props.maxWidth) {
    style.maxWidth = props.maxWidth
  }
  if (props.truncateLines > 1) {
    style['-webkit-line-clamp'] = props.truncateLines
  }
  return style
})
</script>

<template>
  <div
    ref="cellRef"
    class="bh-truncate-cell"
    :class="{
      'bh-truncate-single': truncate && truncateLines === 1,
      'bh-truncate-multi': truncate && truncateLines > 1
    }"
    :style="cellStyle"
    :title="shouldShowTooltip ? tooltipContent : ''"
  >
    <template v-if="html">
      <span v-html="value"></span>
    </template>
    <template v-else>
      {{ value }}
    </template>
  </div>
</template>
