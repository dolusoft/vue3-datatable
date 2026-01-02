<script lang="ts">
export default {
  name: 'columnHeader'
}
</script>
<script setup lang="ts">
import { watch, ref, onMounted, computed } from 'vue'

import ButtonExpand from './button-expand.vue'
import columnFilter from './column-filter.vue'
import columnFilterNew from './column-filter-new.vue'
import iconCheck from './icon-check.vue'
import iconDash from './icon-dash.vue'
import iconFilter from './icon-filter.vue'
import { FILTER_CONDITIONS } from '../model/filter-conditions'

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

      // Create individual watch for each field with conditional debounce
      // Immediate when cleared, debounced when typing
      let debounceTimer: ReturnType<typeof setTimeout> | null = null

      watch(
        () => filterInputs.value[col.field],
        newValue => {
          const column = columnsMap.value.get(col.field)
          if (!column) return

          const isEmpty =
            newValue === '' || newValue === null || newValue === undefined

          // Clear any pending debounce
          if (debounceTimer) {
            clearTimeout(debounceTimer)
            debounceTimer = null
          }

          const processChange = () => {
            // Set value (trim strings)
            if (column.type === 'string' || column.type === 'String') {
              column.value = isEmpty
                ? ''
                : typeof newValue === 'string'
                ? newValue.trim()
                : newValue
            } else {
              column.value = isEmpty ? '' : newValue
            }

            if (isEmpty) {
              // Input cleared → clear filter completely
              column.condition = ''
              columnConditions.value[col.field] = ''
            } else if (!columnConditions.value[col.field]) {
              // No condition selected yet → default to Equal
              column.condition = 'Equal'
              columnConditions.value[col.field] = 'Equal'
            } else {
              // Apply stored condition from local state (user selected via dropdown)
              column.condition = columnConditions.value[col.field]
            }

            emit('filterChange')
          }

          if (isEmpty) {
            // Immediate execution when cleared
            processChange()
          } else {
            // Debounced execution when typing
            debounceTimer = setTimeout(processChange, 300)
          }
        }
      )
    }
  })
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
        } else if (!hasValue) {
          // Clear condition when value is empty
          columnConditions.value[colState.field] = ''
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

  if (found) {
    // Check for translation
    if (props.columnFilterLang && props.columnFilterLang[condition]) {
      return props.columnFilterLang[condition]
    }
    return found.label
  }

  return condition
}

// Get input placeholder based on condition
const getInputPlaceholder = (col: any) => {
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
  columnConditions.value[col.field] = ''
  // Reset sort if this column is currently sorted
  if (props.currentSortColumn === col.field) {
    emit('sortChange', props.all.sortColumn || col.field, 'asc')
  }
  emit('filterChange')
}
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
          <button
            v-if="props.showClearAllButton"
            type="button"
            class="bh-clear-all-button"
            :class="{
              'bh-clear-all-button--active': hasAnyActiveFilterLocal
            }"
            :disabled="!hasAnyActiveFilterLocal"
            @click.stop="handleClearAllFilters"
            title="Clear all filters"
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
          <button
            v-if="props.showClearAllButton"
            type="button"
            class="bh-clear-all-button"
            :class="{
              'bh-clear-all-button--active': hasAnyActiveFilterLocal
            }"
            :disabled="!hasAnyActiveFilterLocal"
            @click.stop="handleClearAllFilters"
            title="Clear all filters"
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
            <button
              v-if="props.showClearAllButton"
              type="button"
              class="bh-clear-all-button"
              :class="{
                'bh-clear-all-button--active': hasAnyActiveFilterLocal
              }"
              :disabled="!hasAnyActiveFilterLocal"
              @click.stop="handleClearAllFilters"
              title="Clear all filters"
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
            class="bh-ml-3 bh-sort bh-flex bh-items-center"
            :class="[props.currentSortColumn, props.currentSortDirection]"
          >
            <svg width="16" height="16" viewBox="0 0 14 14" fill="none">
              <polygon
                points="3.11,6.25 10.89,6.25 7,1.75 "
                fill="currentColor"
                class="bh-text-black/20"
                :class="[
                  currentSortColumn === col.field &&
                  currentSortDirection === 'asc'
                    ? '!bh-text-primary'
                    : ''
                ]"
              ></polygon>
              <polygon
                points="7,12.25 10.89,7.75 3.11,7.75 "
                fill="currentColor"
                class="bh-text-black/20"
                :class="[
                  currentSortColumn === col.field &&
                  currentSortDirection === 'desc'
                    ? '!bh-text-primary'
                    : ''
                ]"
              ></polygon>
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
                />
                <input
                  v-else
                  v-model="filterInputs[col.field]"
                  type="date"
                  class="bh-form-control"
                />
              </template>
              <select
                v-else-if="col.type === 'bool'"
                v-model="filterInputs[col.field]"
                class="bh-form-control"
                @click="props.isOpenFilter"
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
                />
              </template>
              <select
                v-else-if="col.type === 'bool'"
                v-model="filterInputs[col.field]"
                class="bh-form-control"
                @click="props.isOpenFilter"
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
