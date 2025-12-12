<template>
  <div
    ref="dropdownRef"
    class="bh-filter-dropdown-container bh-fixed bh-z-[100] bh-bg-white dark:bh-bg-gray-800 bh-shadow-lg bh-rounded bh-border bh-border-solid bh-border-gray-300 dark:bh-border-gray-600"
    :style="dropdownStyle"
  >
    <div class="bh-p-2 bh-min-w-[200px]">
      <!-- Filter Condition -->
      <div class="bh-mb-2">
        <label
          class="bh-text-xs bh-font-medium bh-text-gray-600 dark:bh-text-gray-400 bh-block bh-mb-1"
        >
          Filter Condition
        </label>
        <select
          ref="selectRef"
          v-model="selectedCondition"
          class="bh-filter-select bh-w-full bh-px-2.5 bh-py-1.5 bh-text-sm bh-border bh-border-gray-300 dark:bh-border-gray-600 bh-rounded bh-bg-white dark:bh-bg-gray-700 hover:bh-border-primary focus:bh-border-primary focus:bh-ring-1 focus:bh-ring-primary bh-outline-none bh-cursor-pointer bh-transition-colors"
          @focus="isSelectOpen = true"
          @blur="isSelectOpen = false"
          @change="handleConditionChange"
        >
          <option
            v-for="cond in availableConditions"
            :key="cond.value"
            :value="cond.value"
          >
            {{ cond.icon ? cond.icon + ' ' : '' }}{{ getTranslatedLabel(cond) }}
          </option>
        </select>
      </div>

      <!-- Sort Options (DataTables style) -->
      <div
        v-if="props.column.sort !== false"
        class="bh-border-t bh-border-gray-200 dark:bh-border-gray-600 bh-pt-2 bh-mt-2"
      >
        <label
          class="bh-text-xs bh-font-medium bh-text-gray-600 dark:bh-text-gray-400 bh-block bh-mb-1"
        >
          Sort
        </label>
        <div class="bh-flex bh-flex-col bh-gap-1">
          <button
            type="button"
            class="bh-w-full bh-px-2.5 bh-py-1.5 bh-text-sm bh-text-left bh-rounded bh-transition-colors"
            :class="{
              'bh-bg-primary/10 bh-text-primary': isCurrentSort('asc'),
              'bh-bg-gray-50 dark:bh-bg-gray-700 hover:bh-bg-gray-100 dark:hover:bh-bg-gray-600':
                !isCurrentSort('asc')
            }"
            @click="handleSort('asc')"
          >
            ↑ Sort Ascending
          </button>
          <button
            type="button"
            class="bh-w-full bh-px-2.5 bh-py-1.5 bh-text-sm bh-text-left bh-rounded bh-transition-colors"
            :class="{
              'bh-bg-primary/10 bh-text-primary': isCurrentSort('desc'),
              'bh-bg-gray-50 dark:bh-bg-gray-700 hover:bh-bg-gray-100 dark:hover:bh-bg-gray-600':
                !isCurrentSort('desc')
            }"
            @click="handleSort('desc')"
          >
            ↓ Sort Descending
          </button>
        </div>
      </div>

      <!-- Clear Filter -->
      <div
        class="bh-border-t bh-border-gray-200 dark:bh-border-gray-600 bh-pt-2 bh-mt-2"
      >
        <button
          type="button"
          class="bh-w-full bh-px-2.5 bh-py-1.5 bh-text-sm bh-text-left bh-rounded bh-transition-colors bh-text-red-600 hover:bh-bg-red-50 dark:hover:bh-bg-red-900/20"
          @click="handleClearFilter"
        >
          ✕ Clear Filter
        </button>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
export default {
  name: 'columnFilterNew'
}
</script>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { FILTER_CONDITIONS } from '../model/filter-conditions'

const props = defineProps([
  'column',
  'columnFilterLang',
  'currentSortColumn',
  'currentSortDirection'
])
const emit = defineEmits(['close', 'filterChange', 'sortChange', 'clearFilter', 'conditionChange'])

const dropdownRef = ref<HTMLElement | null>(null)
const selectRef = ref<HTMLSelectElement | null>(null)
const selectedCondition = ref(props.column.condition || '')
const isSelectOpen = ref(false)

// Dynamic positioning with fixed position
const dropdownStyle = ref<Record<string, string>>({})

const calculatePosition = () => {
  const dropdown = dropdownRef.value
  if (!dropdown) return
  
  // Find the filter button (sibling of dropdown)
  const button = dropdown.parentElement?.querySelector('.bh-filter-button') as HTMLElement
  if (!button) return
  
  const buttonRect = button.getBoundingClientRect()
  const dropdownWidth = 200
  const dropdownHeight = dropdown.offsetHeight || 280
  const padding = 10
  
  // Calculate available space in viewport
  const spaceRight = window.innerWidth - buttonRect.right
  const spaceLeft = buttonRect.left
  const spaceBottom = window.innerHeight - buttonRect.bottom
  
  let left: number | null = null
  let right: number | null = null
  let top: number | null = null
  let bottom: number | null = null
  
  // Horizontal positioning
  if (spaceRight >= dropdownWidth + padding) {
    // Align dropdown's left edge with button's left edge
    left = buttonRect.left
  } else if (spaceLeft >= dropdownWidth + padding) {
    // Align dropdown's right edge with button's right edge
    right = window.innerWidth - buttonRect.right
  } else {
    // Center or clamp to viewport
    left = Math.max(padding, Math.min(buttonRect.left, window.innerWidth - dropdownWidth - padding))
  }
  
  // Vertical positioning
  if (spaceBottom >= dropdownHeight + padding) {
    top = buttonRect.bottom + 4
  } else {
    bottom = window.innerHeight - buttonRect.top + 4
  }
  
  // Build style object
  const style: Record<string, string> = {}
  if (left !== null) style.left = `${left}px`
  if (right !== null) style.right = `${right}px`
  if (top !== null) style.top = `${top}px`
  if (bottom !== null) style.bottom = `${bottom}px`
  
  dropdownStyle.value = style
}

// Get available conditions based on column type
const availableConditions = computed(() => {
  const type = props.column.type?.toLowerCase() || 'string'
  return FILTER_CONDITIONS[type] || FILTER_CONDITIONS.string
})

// Get translated label for condition
const getTranslatedLabel = (cond: any) => {
  if (!props.columnFilterLang) return cond.label

  const key = cond.value === '' ? 'NoFilter' : cond.value
  return props.columnFilterLang[key] || cond.label
}

// Handle condition change
const handleConditionChange = (event: Event) => {
  const target = event.target as HTMLSelectElement
  const newValue = target.value
  
  isSelectOpen.value = false
  selectedCondition.value = newValue
  
  // Emit condition change to parent for reactivity
  emit('conditionChange', props.column.field, newValue)

  if (newValue === '') {
    props.column.value = ''
  }

  emit('filterChange', props.column)
}

// Check if current column is sorted in given direction
const isCurrentSort = (direction: string) => {
  return (
    props.currentSortColumn === props.column.field &&
    props.currentSortDirection === direction
  )
}

// Handle sort
const handleSort = (direction: string) => {
  emit('sortChange', props.column.field, direction)
  emit('close')
}

// Handle clear filter (reset this column's filter and sort)
const handleClearFilter = () => {
  // Reset condition to default
  const type = props.column.type?.toLowerCase() || 'string'
  props.column.condition = type === 'string' ? 'Contains' : 'Equal'
  props.column.value = ''
  selectedCondition.value = props.column.condition
  
  emit('clearFilter', props.column)
  emit('close')
}

// Global click handler
const handleGlobalClick = (event: MouseEvent) => {
  const target = event.target as HTMLElement

  // Don't close if select is open (native select options are outside dropdown)
  if (isSelectOpen.value) {
    return
  }

  // Don't close if clicking on SELECT or OPTION elements
  if (target.tagName === 'SELECT' || target.tagName === 'OPTION') {
    return
  }

  // Don't close if clicking inside dropdown
  if (
    dropdownRef.value &&
    (dropdownRef.value as HTMLElement).contains(target)
  ) {
    return
  }

  // Don't close if clicking filter button (let toggle handle it)
  if (target.closest('.bh-filter-button')) {
    return
  }

  // Close dropdown
  emit('close')
}

// Handle escape key
const handleEscape = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    emit('close')
  }
}

// Setup and cleanup
onMounted(() => {
  nextTick(() => {
    calculatePosition()
    selectRef.value?.focus()
    document.addEventListener('click', handleGlobalClick, true)
    document.addEventListener('keydown', handleEscape)
  })
})

onUnmounted(() => {
  document.removeEventListener('click', handleGlobalClick, true)
  document.removeEventListener('keydown', handleEscape)
})
</script>
