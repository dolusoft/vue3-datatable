<script lang="ts">
export default {
  name: 'columnHeader'
}
</script>
<script setup lang="ts">
import { watch, ref, onMounted, computed } from 'vue'
import { watchDebounced } from '@vueuse/core'

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
  'columnFilterLang'
])

const emit = defineEmits([
  'selectAll',
  'sortChange',
  'filterChange',
  'toggleFilterMenu',
  'clearColumnFilter'
])

// ============================================================================
// FAZ III OPTIMIZATION: Field-specific watches instead of deep watch
// ============================================================================

// Local state for filter inputs to avoid props mutation
const filterInputs = ref<Record<string, any>>({})

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

// Initialize filter inputs from columns
const initializeColumns = () => {
  if (props.all?.columns) {
    props.all.columns.forEach((col: any) => {
      if (col.filter && col.field) {
        // Set default condition if not already set (for useNewColumnFilter)
        if (props.all.useNewColumnFilter && props.all.showFloatingFilterLabel && (!col.condition || col.condition === '')) {
          const type = col.type?.toLowerCase() || 'string'
          const conditions = FILTER_CONDITIONS[type] || FILTER_CONDITIONS.string
          // Get first non-empty condition (skip "No Filter" which has value '')
          const defaultCondition = conditions.find((c: any) => c.value !== '')
          if (defaultCondition) {
            col.condition = defaultCondition.value
          }
        }
      }
    })
  }
}

// Watch for columns changes and initialize
watch(
  () => props.all?.columns,
  () => {
    initializeColumns()
  },
  { immediate: true, deep: true }
)

onMounted(() => {
  initializeColumns()
  
  if (props.all?.columns) {
    props.all.columns.forEach((col: any) => {
      if (col.filter && col.field) {
        filterInputs.value[col.field] = col.value || ''

        // Create individual watch for each field
        watchDebounced(
          () => filterInputs.value[col.field],
          newValue => {
            const column = columnsMap.value.get(col.field)
            if (column) {
              // Trim only string values
              if (column.type === 'string' || column.type === 'String') {
                column.value =
                  typeof newValue === 'string' ? newValue.trim() : newValue
              } else {
                column.value = newValue
              }
              emit('filterChange')
            }
          },
          { debounce: 300 }
        )
      }
    })
  }
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

// Get condition label (MUI X style)
const getConditionLabel = (col: any) => {
  if (!col.condition || col.condition === '') return ''

  const type = col.type?.toLowerCase() || 'string'
  const conditions = FILTER_CONDITIONS[type] || FILTER_CONDITIONS.string
  const found = conditions.find((c: any) => c.value === col.condition)

  if (found) {
    // Check for translation
    if (props.columnFilterLang && props.columnFilterLang[col.condition]) {
      return props.columnFilterLang[col.condition]
    }
    return found.label
  }

  return col.condition
}

// Get input placeholder based on condition
const getInputPlaceholder = (col: any) => {
  return ''
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
      </th>
    </template>
    <template v-for="(col, j) in props.all.columns">
      <th
        v-if="!col.hide"
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
              <input
                v-else-if="col.type === 'date' || col.type === 'DateTime'"
                v-model="filterInputs[col.field]"
                type="date"
                class="bh-form-control"
              />
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
                v-if="
                  col.condition &&
                  col.condition !== '' &&
                  props.all.useNewColumnFilter
                "
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
                    col.condition &&
                    col.condition !== '' &&
                    props.all.useNewColumnFilter
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
                    col.condition &&
                    col.condition !== '' &&
                    props.all.useNewColumnFilter
                }"
              />
              <input
                v-else-if="col.type === 'date' || col.type === 'DateTime'"
                v-model="filterInputs[col.field]"
                type="date"
                class="bh-form-control"
                :class="{
                  'bh-form-control--with-label':
                    col.condition &&
                    col.condition !== '' &&
                    props.all.useNewColumnFilter
                }"
              />
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
              v-if="col.type !== 'bool'"
              type="button"
              class="bh-filter-button"
              @click.stop="emit('toggleFilterMenu', col)"
              :class="{
                '!bh-bg-primary/10 !bh-border-primary': hasActiveFilter(col),
                'bh-bg-[#e0e6ed] dark:bh-bg-gray-700': !hasActiveFilter(col),
                'bh-filter-button--with-label':
                  col.condition &&
                  col.condition !== '' &&
                  props.all.useNewColumnFilter &&
                  props.all.showFloatingFilterLabel
              }"
            >
              <icon-filter
                class="bh-w-4"
                :class="{
                  'bh-text-primary': hasActiveFilter(col),
                  'bh-text-black/70 dark:bh-text-gray-300':
                    !hasActiveFilter(col)
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
            <column-filter-new
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
              @clearFilter="
                col => {
                  filterInputs[col.field] = ''
                  col.value = ''
                  // Reset sort if this column is currently sorted
                  if (props.currentSortColumn === col.field) {
                    emit('sortChange', props.all.sortColumn || col.field, 'asc')
                  }
                  emit('filterChange')
                }
              "
            />
          </div>
        </template>
      </th>
    </template>
  </tr>
</template>


