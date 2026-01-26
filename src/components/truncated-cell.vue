<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    value: any
    truncate: boolean
    maxWidth?: string
    truncateLines: number
    showTooltip: boolean
    html?: boolean
    maxLength?: number
  }>(),
  {
    maxLength: 150
  }
)

// Full text for tooltip
const fullText = computed(() => String(props.value ?? ''))

// Truncated text for display
const displayText = computed(() => {
  if (!props.truncate) return fullText.value

  const text = fullText.value
  if (text.length <= props.maxLength) {
    return text
  }

  return text.substring(0, props.maxLength) + '...'
})

// Should show tooltip?
const shouldShowTooltip = computed(() => {
  return props.truncate && props.showTooltip && fullText.value.length > props.maxLength
})
</script>

<template>
  <span :title="shouldShowTooltip ? fullText : ''">
    <template v-if="html">
      <span v-html="displayText"></span>
    </template>
    <template v-else>
      {{ displayText }}
    </template>
  </span>
</template>
