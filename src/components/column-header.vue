<script lang="ts">
export default {
  name: 'columnHeader'
}
</script>
<script setup lang="ts">
import { watch, ref, onMounted } from 'vue'
import { watchDebounced } from '@vueuse/core'

import ButtonExpand from './button-expand.vue'
import columnFilter from './column-filter.vue'
import iconCheck from './icon-check.vue'
import iconDash from './icon-dash.vue'
import iconFilter from './icon-filter.vue'

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
  'toggleFilterMenu'
])

// Local state for filter inputs to avoid props mutation
const filterInputs = ref<Record<string, any>>({})

// Initialize filter inputs from columns
onMounted(() => {
  if (props.all?.columns) {
    props.all.columns.forEach((col: any) => {
      if (col.filter && col.field) {
        filterInputs.value[col.field] = col.value || ''
      }
    })
  }
})

// Watch filter inputs with debounce and update columns
watchDebounced(
  filterInputs,
  (newValues) => {
    if (props.all?.columns) {
      Object.keys(newValues).forEach((field) => {
        const col = props.all.columns.find((c: any) => c.field === field)
        if (col) {
          // Trim string values
          if (col.type === 'string' || col.type === 'String') {
            col.value = typeof newValues[field] === 'string' ? newValues[field].trim() : newValues[field]
          } else {
            col.value = newValues[field]
          }
        }
      })
      emit('filterChange')
    }
  },
  { debounce: 300, deep: true }
)

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
</script>
<template>
  <tr key="hdrrow">
    <th
      v-if="props.all.hasCheckbox"
      :key="'chkall'"
      :style="{ width: props.all.checkboxColumnWidth + ' !important', minWidth: props.all.checkboxColumnWidth + ' !important' }"
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
    :style="{ width: props.all.rightPanelColumnWidth + ' !important', minWidth: props.all.rightPanelColumnWidth + ' !important' }"
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
      <th :style="{ width: props.all.subtableColumnWidth + ' !important', minWidth: props.all.subtableColumnWidth + ' !important' }">
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
            <input
              v-if="col.type === 'string' || col.type==='String'"
              v-model="filterInputs[col.field]"
              type="text"
              class="bh-form-control"
            />
            <input
              v-if="col.type === 'number' || col.type === 'integer' || col.type=== 'Integer'"
              v-model.number="filterInputs[col.field]"
              type="number"
              class="bh-form-control"
            />
            <input
              v-else-if="col.type === 'date' || col.type=== 'DateTime'"
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

            <button
              v-if="col.type !== 'bool'"
              type="button"
              @click.stop="emit('toggleFilterMenu', col)"
              :class="{
                '!bh-bg-primary/10 !bh-border-primary': hasActiveFilter(col),
                'bh-bg-[#e0e6ed] dark:bh-bg-gray-700': !hasActiveFilter(col)
              }"
            >
              <icon-filter 
                class="bh-w-4" 
                :class="{
                  'bh-text-primary': hasActiveFilter(col),
                  'bh-text-black/70 dark:bh-text-gray-300': !hasActiveFilter(col)
                }"
              />
            </button>

            <column-filter
              v-show="props.isOpenFilter === col.field"
              :column="col"
              :type="col.type"
              :columnFilterLang="props.columnFilterLang"
              @close="emit('toggleFilterMenu', null)"
              @filterChange="emit('filterChange')"
            />
          </div>
        </template>
      </th>
    </template>
  </tr>
</template>
