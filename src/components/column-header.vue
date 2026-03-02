<script lang="ts">
export default {
  name: 'columnHeader'
}
</script>
<script setup lang="ts">
import { watch, ref, onMounted, computed } from 'vue'
import { Tooltip as VTooltip } from 'floating-vue'

import ButtonExpand from './button-expand.vue'
import columnFilter from './column-filter.vue'
import columnFilterNew from './column-filter-new.vue'
import iconCheck from './icon-check.vue'
import iconDash from './icon-dash.vue'
import iconFilter from './icon-filter.vue'
import { FILTER_CONDITIONS } from '../model/filter-conditions'
import { parseFilterInput } from '../model/filter-input-parser'

const selectedAll: any = ref(null)

const props = defineProps([
  'all',
  'expandedrows',
  'currentSortColumn',
  'currentSortDirection',
  'isOpenFilter',
  'isFooter',
  'checkAll',
  'columnFilterLang',
  'hasFilterDatetimeSlot',
  'showClearAllButton',
  'hasAnyActiveFilter',
  'filterUpdateTrigger'
])

const emit = defineEmits([
  'selectAll',
  'sortChange',
  'filterChange',
  'toggleFilterMenu',
  'clearColumnFilter',
  'filterDatetimeUpdate',
  'clearAllFilters'
])

// Determine where to show clear button (first available column)
const clearButtonLocation = computed(() => {
  if (props.all.hasCheckbox) return 'checkbox'
  if (props.all.hasRightPanel) return 'rightpanel'
  if (props.all.hasSubtable) return 'subtable'
  return 'none'
})

// ============================================================================
// FAZ III OPTIMIZATION: Field-specific watches instead of deep watch
// ============================================================================

// Local state for filter inputs to avoid props mutation
const filterInputs = ref<Record<string, any>>({})

// Local state for column conditions (for reactivity)
const columnConditions = ref<Record<string, string>>({})

// Track which fields have watches set up
const watchedFields = ref<Set<string>>(new Set())

// Store debounce timers by field for flush capability
const debounceTimers = new Map<string, ReturnType<typeof setTimeout> | null>()

// Store processChange functions by field for flush capability
const processChangeFunctions = new Map<string, () => void>()

// Create column Map for O(1) lookup
const columnsMap = computed(() => {
  const map = new Map()
  if (props.all?.columns) {
    props.all.columns.forEach((col: any) => {
      if (col.field) {
        map.set(col.field, col)
      }
    })
  }
  return map
})

// Setup watches for columns - can be called multiple times safely
const setupColumnWatches = () => {
  if (!props.all?.columns) return

  props.all.columns.forEach((col: any) => {
    if (col.filter && col.field && !watchedFields.value.has(col.field)) {
      // Initialize filterInputs value
      if (filterInputs.value[col.field] === undefined) {
        filterInputs.value[col.field] = col.value || ''
      }

      // Mark as watched
      watchedFields.value.add(col.field)

      // Initialize debounce timer for this field
      debounceTimers.set(col.field, null)

      watch(
        () => filterInputs.value[col.field],
        newValue => {
          const column = columnsMap.value.get(col.field)
          if (!column) return

          const isEmpty =
            newValue === '' || newValue === null || newValue === undefined

          // Clear any pending debounce
          const existingTimer = debounceTimers.get(col.field)
          if (existingTimer) {
            clearTimeout(existingTimer)
            debounceTimers.set(col.field, null)
          }

          // ── IMMEDIATE: Detect operator and update condition/label instantly ──
          if (!isEmpty && (column.type === 'string' || column.type === 'String') && typeof newValue === 'string') {
            const v = newValue.trim()

            if (v === '*' || v === '!*') {
              // Typing in progress — show likely condition hint
              const hint = v.startsWith('!') ? 'NotContains' : 'Contains'
              column.condition = hint
              columnConditions.value[col.field] = hint
            } else if (v === '!') {
              column.condition = 'NotEqual'
              columnConditions.value[col.field] = 'NotEqual'
            } else {
              // Full parse for accurate detection
              const parsed = parseFilterInput(v)
              if (parsed.isOperatorDetected && parsed.rules.length > 0) {
                column.condition = parsed.rules[0].condition
                columnConditions.value[col.field] = parsed.rules[0].condition
              }
            }
          }

          const processChange = () => {
            // Clear timer reference after execution
            debounceTimers.set(col.field, null)

            if (isEmpty) {
              // Input cleared → clear value and parsed rules, PRESERVE condition
              column.value = ''
              column.parsedFilterRules = undefined
              emit('filterChange')
              return
            }

            // Parse operator shortcuts for string columns
            if ((column.type === 'string' || column.type === 'String') && typeof newValue === 'string') {
              const parsed = parseFilterInput(newValue)

              if (parsed.isOperatorDetected && parsed.rules.length > 0) {
                // Keep RAW input in column.value (operators stay visible in input)
                column.value = newValue.trim()
                // Store ALL parsed rules with cleaned values (for backend use)
                column.parsedFilterRules = parsed.rules
                // Condition already set in immediate block above
                emit('filterChange')
                return
              }

              // No operator detected → existing behavior
              column.value = newValue.trim()
              column.parsedFilterRules = undefined
            } else {
              // Non-string type → existing behavior
              column.value = newValue
              column.parsedFilterRules = undefined
            }

            if (!columnConditions.value[col.field]) {
              // No condition selected yet → default to Equal
              column.condition = 'Equal'
              columnConditions.value[col.field] = 'Equal'
            } else {
              // Apply stored condition from local state (user selected via dropdown)
              column.condition = columnConditions.value[col.field]
            }

            emit('filterChange')
          }

          // Store processChange function for flush capability
          processChangeFunctions.set(col.field, processChange)

          if (isEmpty) {
            // Immediate execution when cleared
            processChange()
          } else {
            // Debounced execution when typing (configurable, default 100ms)
            const debounceTime = props.all?.filterDebounce ?? 100
            debounceTimers.set(col.field, setTimeout(processChange, debounceTime))
          }
        }
      )
    }
  })
}

/**
 * Flush pending debounce for a specific field
 * Called when Enter is pressed to immediately process the filter
 */
const flushFilterDebounce = (field: string) => {
  const timer = debounceTimers.get(field)
  if (timer) {
    clearTimeout(timer)
    debounceTimers.set(field, null)

    const processChange = processChangeFunctions.get(field)
    if (processChange) {
      processChange()
    }
  }
}

/**
 * Flush all pending debounces
 * Useful when search is triggered externally
 */
const flushAllFilterDebounces = () => {
  debounceTimers.forEach((timer, field) => {
    if (timer) {
      clearTimeout(timer)
      debounceTimers.set(field, null)

      const processChange = processChangeFunctions.get(field)
      if (processChange) {
        processChange()
      }
    }
  })
}

/**
 * Handle Enter key on filter input - flush debounce immediately
 */
const handleFilterEnter = (field: string) => {
  flushFilterDebounce(field)
}

// Handle clear all filters
const handleClearAllFilters = () => {
  // Clear local state
  Object.keys(filterInputs.value).forEach(key => {
    filterInputs.value[key] = ''
  })
  Object.keys(columnConditions.value).forEach(key => {
    columnConditions.value[key] = ''
  })

  // Clear column conditions in props.all.columns
  if (props.all?.columns) {
    props.all.columns.forEach((col: any) => {
      if (col.filter) {
        col.value = ''
        col.condition = ''
        col.parsedFilterRules = undefined
      }
    })
  }

  emit('clearAllFilters')
}

// Local computed for active filter detection
const hasAnyActiveFilterLocal = computed(() => {
  // Check filterInputs
  const hasInputValue = Object.values(filterInputs.value).some(
    val => val !== '' && val !== null && val !== undefined
  )

  // Check columnConditions (user-selected conditions)
  const hasConditionValue = Object.values(columnConditions.value).some(
    val => val !== '' && val !== null && val !== undefined
  )

  return hasInputValue || hasConditionValue
})

// Initialize filter inputs from columns
const initializeColumns = () => {
  // No default condition assignment - label will only show when user selects a condition
}

// Watch for columns changes and setup watches
watch(
  () => props.all?.columns,
  newColumns => {
    if (newColumns && newColumns.length > 0) {
      setupColumnWatches()
    }
  },
  { immediate: true, deep: true }
)

// Watch for external column value changes (e.g., from setColumnFilter)
watch(
  () => props.all?.columns?.map((col: any) => ({ field: col.field, value: col.value, condition: col.condition })),
  (newValues) => {
    if (!newValues) return
    newValues.forEach((colState: any) => {
      if (colState.field) {
        const currentInputValue = filterInputs.value[colState.field] ?? ''
        const newInputValue = colState.value ?? ''
        const hasValue = newInputValue !== '' && newInputValue !== null && newInputValue !== undefined
        
        // Sync filterInputs if value changed externally
        if (String(currentInputValue) !== String(newInputValue)) {
          filterInputs.value[colState.field] = newInputValue
        }
        
        // Only sync condition if there's a value AND condition exists
        if (hasValue && colState.condition) {
          const currentCondition = columnConditions.value[colState.field] ?? ''
          if (currentCondition !== colState.condition) {
            columnConditions.value[colState.field] = colState.condition
          }
        }
      }
    })
  },
  { deep: true, immediate: true }
)

// Watch filterUpdateTrigger for external updates (setColumnFilter)
watch(
  () => props.filterUpdateTrigger,
  () => {
    if (!props.all?.columns) return
    // Force sync all columns from props
    props.all.columns.forEach((col: any) => {
      if (col.field) {
        const colValue = col.value ?? ''
        const hasValue = colValue !== '' && colValue !== null && colValue !== undefined
        
        // Always sync value
        filterInputs.value[col.field] = colValue
        
        // Sync condition only if has value
        if (hasValue && col.condition) {
          columnConditions.value[col.field] = col.condition
        }
      }
    })
  }
)

onMounted(() => {
  // Setup watches on mount as well (in case columns are already available)
  setupColumnWatches()
})

const checkboxChange = () => {
  if (selectedAll.value) {
    selectedAll.value.indeterminate =
      props.checkAll !== 0 ? !props.checkAll : false
    selectedAll.value.checked = props.checkAll
  }
}
watch(() => props.checkAll, checkboxChange)

// Check if column has active filter
const hasActiveFilter = (col: any) => {
  if (!col.field) return false
  const inputValue = filterInputs.value[col.field]
  return inputValue !== '' && inputValue !== null && inputValue !== undefined
}

// Check if column has a condition set (not empty/No Filter)
const hasConditionSet = (col: any) => {
  const condition = columnConditions.value[col.field] ?? col.condition
  return condition && condition !== ''
}

// Get condition for column (from local state or column)
const getColumnCondition = (col: any) => {
  return columnConditions.value[col.field] ?? col.condition ?? ''
}

// Get condition label (MUI X style)
const getConditionLabel = (col: any) => {
  const condition = getColumnCondition(col)
  if (!condition || condition === '') return ''

  const type = col.type?.toLowerCase() || 'string'
  const conditions = FILTER_CONDITIONS[type] || FILTER_CONDITIONS.string
  const found = conditions.find((c: any) => c.value === condition)

  let label = ''
  if (found) {
    // Check for translation
    if (props.columnFilterLang && props.columnFilterLang[condition]) {
      label = props.columnFilterLang[condition]
    } else {
      label = found.label
    }
  } else {
    label = condition
  }

  // Show count for multi-value filters (comma-separated operator shortcuts)
  if (col.parsedFilterRules && col.parsedFilterRules.length > 1) {
    label += ` (${col.parsedFilterRules.length})`
  }

  return label
}

// Get input placeholder based on condition
const getInputPlaceholder = (col: any) => {
  if (col.type === 'string' || col.type === 'String') {
    return '*..* | ..* | *.. | !..'
  }
  return ''
}

// Handle condition change from dropdown
const handleConditionChange = (field: string, condition: string) => {
  const column = columnsMap.value.get(field)
  if (column) {
    // Update both local state AND column.condition immediately
    columnConditions.value[field] = condition
    column.condition = condition

    emit('filterChange')
  }
}

// Handle clear filter from dropdown
const handleClearFilter = (col: any) => {
  filterInputs.value[col.field] = ''
  col.value = ''
  col.condition = ''
  col.parsedFilterRules = undefined
  columnConditions.value[col.field] = ''
  // Reset sort if this column is currently sorted
  if (props.currentSortColumn === col.field) {
    emit('sortChange', props.all.sortColumn || col.field, 'asc')
  }
  emit('filterChange')
}

// Expose methods to parent component
defineExpose({
  flushFilterDebounce,
  flushAllFilterDebounces
})
</script>
<template>
  <tr key="hdrrow">
    <th
      v-if="props.all.hasCheckbox"
      :key="'chkall'"
      :style="{
        width: props.all.checkboxColumnWidth + ' !important',
        minWidth: props.all.checkboxColumnWidth + ' !important'
      }"
      :class="{
        'bh-sticky bh-bg-blue-light bh-z-[1]':
          props.all.stickyHeader || props.all.stickyFirstColumn,
        'bh-top-0': props.all.stickyHeader,
        'bh-left-0': props.all.stickyFirstColumn
      }"
    >
      <div class="bh-checkbox">
        <input
          ref="selectedAll"
          type="checkbox"
          @click.stop="emit('selectAll', $event?.target?.checked)"
        />
        <div>
          <icon-check class="check" />
          <icon-dash class="intermediate" />
        </div>
      </div>
      <!-- Clear All Filters Button -->
      <template
        v-if="
          props.all.columnFilter &&
          !props.isFooter &&
          clearButtonLocation === 'checkbox'
        "
      >
        <div class="bh-filter bh-flex bh-justify-center">
          <VTooltip placement="top" :distance="6">
            <button
              v-if="props.showClearAllButton"
              type="button"
              class="bh-clear-all-button"
              :class="{
                'bh-clear-all-button--active': hasAnyActiveFilterLocal
              }"
              :disabled="!hasAnyActiveFilterLocal"
              @click.stop="handleClearAllFilters"
            >
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
              </svg>
            </button>
            <template #popper>Clear all filters</template>
          </VTooltip>
        </div>
      </template>
    </th>
    <th
      v-if="props.all.hasRightPanel"
      :style="{
        width: props.all.rightPanelColumnWidth + ' !important',
        minWidth: props.all.rightPanelColumnWidth + ' !important'
      }"
      :class="{
        'bh-sticky bh-bg-blue-light bh-z-[1]':
          props.all.stickyHeader || props.all.stickyFirstColumn,
        'bh-top-0': props.all.stickyHeader,
        'bh-left-0': props.all.stickyFirstColumn
      }"
    >
      <!-- Right Panel Button Column -->
      <!-- Clear All Filters Button -->
      <template
        v-if="
          props.all.columnFilter &&
          !props.isFooter &&
          clearButtonLocation === 'rightpanel'
        "
      >
        <div class="bh-filter bh-flex bh-justify-center">
          <VTooltip placement="top" :distance="6">
              <button
                v-if="props.showClearAllButton"
                type="button"
                class="bh-clear-all-button"
                :class="{
                  'bh-clear-all-button--active': hasAnyActiveFilterLocal
                }"
                :disabled="!hasAnyActiveFilterLocal"
                @click.stop="handleClearAllFilters"
              >
                <svg
                  width="14"
                  height="14"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </button>
              <template #popper>Clear all filters</template>
          </VTooltip>
        </div>
      </template>
    </th>
    <template v-if="props.all.hasSubtable">
      <th
        :style="{
          width: props.all.subtableColumnWidth + ' !important',
          minWidth: props.all.subtableColumnWidth + ' !important'
        }"
      >
        <template v-if="props.all.expandall">
          <button-expand
            :expandedrows="props.expandedrows"
            :expandall="props.all.expandall"
          >
          </button-expand>
        </template>
        <!-- Clear All Filters Button -->
        <template
          v-if="
            props.all.columnFilter &&
            !props.isFooter &&
            clearButtonLocation === 'subtable'
          "
        >
          <div class="bh-filter bh-flex bh-justify-center">
            <VTooltip placement="top" :distance="6">
              <button
                v-if="props.showClearAllButton"
                type="button"
                class="bh-clear-all-button"
                :class="{
                  'bh-clear-all-button--active': hasAnyActiveFilterLocal
                }"
                :disabled="!hasAnyActiveFilterLocal"
                @click.stop="handleClearAllFilters"
              >
                <svg
                  width="14"
                  height="14"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </button>
              <template #popper>Clear all filters</template>
            </VTooltip>
          </div>
        </template>
      </th>
    </template>
    <template v-for="(col, j) in props.all.columns">
      <th
        v-if="!col.hide && !col.dataOnly"
        :key="col.field"
        class="bh-select-none bh-z-[1]"
        :class="[
          props.all.sortable && col.sort ? 'bh-cursor-pointer' : '',
          j === 0 && props.all.stickyFirstColumn
            ? 'bh-sticky bh-left-0 bh-bg-blue-light'
            : '',
          props.all.hasCheckbox && j === 0 && props.all.stickyFirstColumn
            ? 'bh-left-[52px]'
            : ''
        ]"
        :style="{
          width: col.width,
          'min-width': col.minWidth,
          'max-width': col.maxWidth
        }"
      >
        <div
          class="bh-flex bh-items-center"
          :class="[col.headerClass ? col.headerClass : '']"
          @click="
            props.all.sortable && col.sort && emit('sortChange', col.field)
          "
        >
          {{ col.title }}
          <span
            v-if="props.all.sortable && col.sort"
            class="bh-ml-1.5 bh-sort bh-inline-flex bh-items-center bh-shrink-0"
          >
            <!-- Active sort: single direction arrow -->
            <svg
              v-if="currentSortColumn === col.field"
              width="14"
              height="14"
              viewBox="0 0 16 16"
              fill="none"
              class="bh-text-primary bh-transition-transform bh-duration-150"
              :class="[currentSortDirection === 'desc' ? 'bh-rotate-180' : '']"
            >
              <path
                d="M8 3.5L12.5 9.5H3.5L8 3.5Z"
                fill="currentColor"
              />
            </svg>
            <!-- Inactive sort: subtle dual arrows hint -->
            <svg
              v-else
              width="14"
              height="14"
              viewBox="0 0 16 16"
              fill="none"
              class="bh-text-black/15 dark:bh-text-white/15 bh-transition-colors hover:bh-text-black/40 dark:hover:bh-text-white/40"
            >
              <path d="M8 3L11.5 7H4.5L8 3Z" fill="currentColor" />
              <path d="M8 13L4.5 9H11.5L8 13Z" fill="currentColor" />
            </svg>
          </span>
        </div>

        <template v-if="props.all.columnFilter && !props.isFooter">
          <div v-if="col.filter" class="bh-filter bh-relative">
            <!-- OLD STYLE: No wrapper, direct inputs (when showFloatingFilterLabel is false) -->
            <template v-if="!props.all.showFloatingFilterLabel">
              <input
                v-if="col.type === 'string' || col.type === 'String'"
                v-model="filterInputs[col.field]"
                type="text"
                class="bh-form-control"
                @keydown.enter="handleFilterEnter(col.field)"
              />
              <input
                v-if="
                  col.type === 'number' ||
                  col.type === 'integer' ||
                  col.type === 'Integer'
                "
                v-model.number="filterInputs[col.field]"
                type="number"
                class="bh-form-control"
                @keydown.enter="handleFilterEnter(col.field)"
              />
              <template
                v-else-if="col.type === 'date' || col.type === 'DateTime'"
              >
                <slot
                  v-if="props.hasFilterDatetimeSlot"
                  name="filter-datetime"
                  :column="col"
                  :value="filterInputs[col.field]"
                  :updateValue="(val: any) => {
                    filterInputs[col.field] = val
                    emit('filterDatetimeUpdate', col.field, val)
                  }"
                  :onEnter="() => handleFilterEnter(col.field)"
                />
                <input
                  v-else
                  v-model="filterInputs[col.field]"
                  type="date"
                  class="bh-form-control"
                  @keydown.enter="handleFilterEnter(col.field)"
                />
              </template>
              <select
                v-else-if="col.type === 'bool'"
                v-model="filterInputs[col.field]"
                class="bh-form-control"
                @click="props.isOpenFilter"
                @keydown.enter="handleFilterEnter(col.field)"
              >
                <option :value="undefined">All</option>
                <option :value="true">True</option>
                <option :value="false">False</option>
              </select>
            </template>

            <!-- NEW STYLE: Wrapper with floating label (when showFloatingFilterLabel is true) -->
            <div
              v-if="props.all.showFloatingFilterLabel"
              class="bh-filter-input-wrapper"
            >
              <!-- MUI X Style: Floating Label on Border -->
              <label
                v-if="hasConditionSet(col) && props.all.useNewColumnFilter"
                class="bh-floating-label"
                :class="{
                  'bh-floating-label--active': hasActiveFilter(col)
                }"
              >
                {{ getConditionLabel(col) }}
              </label>

              <input
                v-if="col.type === 'string' || col.type === 'String'"
                v-model="filterInputs[col.field]"
                type="text"
                class="bh-form-control"
                :class="{
                  'bh-form-control--with-label':
                    hasConditionSet(col) && props.all.useNewColumnFilter
                }"
                @keydown.enter="handleFilterEnter(col.field)"
              />
              <input
                v-if="
                  col.type === 'number' ||
                  col.type === 'integer' ||
                  col.type === 'Integer'
                "
                v-model.number="filterInputs[col.field]"
                type="number"
                class="bh-form-control"
                :class="{
                  'bh-form-control--with-label':
                    hasConditionSet(col) && props.all.useNewColumnFilter
                }"
                @keydown.enter="handleFilterEnter(col.field)"
              />
              <template
                v-else-if="col.type === 'date' || col.type === 'DateTime'"
              >
                <slot
                  v-if="props.hasFilterDatetimeSlot"
                  name="filter-datetime"
                  :column="col"
                  :value="filterInputs[col.field]"
                  :updateValue="(val: any) => {
                    filterInputs[col.field] = val
                    emit('filterDatetimeUpdate', col.field, val)
                  }"
                  :hasLabel="
                    hasConditionSet(col) && props.all.useNewColumnFilter
                  "
                  :onEnter="() => handleFilterEnter(col.field)"
                />
                <input
                  v-else
                  v-model="filterInputs[col.field]"
                  type="date"
                  class="bh-form-control"
                  :class="{
                    'bh-form-control--with-label':
                      hasConditionSet(col) && props.all.useNewColumnFilter
                  }"
                  @keydown.enter="handleFilterEnter(col.field)"
                />
              </template>
              <select
                v-else-if="col.type === 'bool'"
                v-model="filterInputs[col.field]"
                class="bh-form-control"
                @click="props.isOpenFilter"
                @keydown.enter="handleFilterEnter(col.field)"
              >
                <option :value="undefined">All</option>
                <option :value="true">True</option>
                <option :value="false">False</option>
              </select>
            </div>

            <button
              v-if="col.type !== 'bool' && !props.all.useNewColumnFilter"
              type="button"
              class="bh-filter-button"
              @click.stop="emit('toggleFilterMenu', col)"
              :class="{
                '!bh-bg-primary/10 !bh-border-primary': hasConditionSet(col),
                'bh-bg-[#e0e6ed] dark:bh-bg-gray-700': !hasConditionSet(col),
                'bh-filter-button--with-label':
                  props.all.showFloatingFilterLabel
              }"
            >
              <icon-filter
                class="bh-w-4"
                :class="{
                  'bh-text-primary': hasConditionSet(col),
                  'bh-text-black/70 dark:bh-text-gray-300':
                    !hasConditionSet(col)
                }"
              />
            </button>

            <!-- OLD: Original column filter (default) -->
            <column-filter
              v-if="!props.all.useNewColumnFilter"
              v-show="props.isOpenFilter === col.field"
              :column="col"
              :type="col.type"
              :columnFilterLang="props.columnFilterLang"
              @close="emit('toggleFilterMenu', null)"
              @filterChange="emit('filterChange')"
            />
            <!-- NEW: DataTables-style column filter -->
            <!-- <column-filter-new
              v-if="props.all.useNewColumnFilter"
              v-show="props.isOpenFilter === col.field"
              :column="col"
              :columnFilterLang="props.columnFilterLang"
              :currentSortColumn="props.currentSortColumn"
              :currentSortDirection="props.currentSortDirection"
              @close="emit('toggleFilterMenu', null)"
              @filterChange="emit('filterChange')"
              @sortChange="
                (field, direction) => emit('sortChange', field, direction)
              "
              @conditionChange="handleConditionChange"
              @clearFilter="handleClearFilter"
            /> -->

            <VDropdown
              v-if="props.all.useNewColumnFilter"
              :shown="props.isOpenFilter === col.field"
              :triggers="[]"
              :auto-hide="true"
              placement="bottom-start"
              :distance="4"
              @apply-hide="emit('toggleFilterMenu', null)"
            >
              <!-- Reference (trigger) -->
              <button
                v-if="col.type !== 'bool'"
                type="button"
                class="bh-filter-button"
                @click.stop="emit('toggleFilterMenu', col)"
                :class="{
                  '!bh-bg-primary/10 !bh-border-primary': hasConditionSet(col),
                  'bh-bg-[#e0e6ed] dark:bh-bg-gray-700': !hasConditionSet(col),
                  'bh-filter-button--with-label':
                    props.all.showFloatingFilterLabel
                }"
              >
                <icon-filter
                  class="bh-w-4"
                  :class="{
                    'bh-text-primary': hasConditionSet(col),
                    'bh-text-black/70 dark:bh-text-gray-300':
                      !hasConditionSet(col)
                  }"
                />
              </button>

              <!-- Popper content -->
              <template #popper>
                <column-filter-new
                  :column="col"
                  :columnFilterLang="props.columnFilterLang"
                  :currentSortColumn="props.currentSortColumn"
                  :currentSortDirection="props.currentSortDirection"
                  @close="emit('toggleFilterMenu', null)"
                  @filterChange="emit('filterChange')"
                  @sortChange="
                    (field, direction) => emit('sortChange', field, direction)
                  "
                  @conditionChange="handleConditionChange"
                  @clearFilter="handleClearFilter"
                />
              </template>
            </VDropdown>
          </div>
        </template>
      </th>
    </template>
  </tr>
</template>
