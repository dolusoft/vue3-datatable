<script lang="ts">
export default {
  name: 'Vue3Datatable'
}
</script>
<script setup lang="ts">
import { useElementSize, useDebounceFn, useThrottleFn } from '@vueuse/core'
import { Splitpanes, Pane } from 'splitpanes'
import {
  computed,
  onMounted,
  onUnmounted,
  type Ref,
  ref,
  useSlots,
  watch,
  nextTick
} from 'vue'

import ButtonExpand from './button-expand.vue'
import ButtonRightPanel from './button-rightpanel.vue'
import columnHeader from './column-header.vue'
import iconCheck from './icon-check.vue'
import type { ColumnDefinition } from '../model/column-model'
import 'splitpanes/dist/splitpanes.css'

const slots = useSlots()

// Check if filter-datetime slot is provided
const hasFilterDatetimeSlot = computed(() => !!slots['filter-datetime'])

interface Props {
  loading?: boolean
  isServerMode?: boolean
  skin?: string
  totalRows?: number
  rows?: Array<any>
  footerRows?: Array<any>
  columns?: Array<ColumnDefinition>
  hasCheckbox?: boolean
  hasSubtable?: boolean
  hasRightPanel?: boolean
  checkboxColumnWidth?: string
  rightPanelColumnWidth?: string
  subtableColumnWidth?: string
  subtableMaxHeight?: string
  subtableLazyLoading?: boolean
  expandall?: boolean
  search?: string
  columnChooser?: boolean
  page?: number // default: 1
  pageSize?: number // default: 10
  pageSizeOptions?: Array<number> // default: [10, 20, 30, 50, 100]
  showPageSize?: boolean
  rowClass?: [Array<string>, Function]
  cellClass?: [Array<string>, Function]
  sortable?: boolean
  sortColumn?: string
  sortDirection?: string
  columnFilter?: boolean
  columnFilterLang?: Record<string, string> | null
  useNewColumnFilter?: boolean // Enable new DataTables-style filter with MUI X labels
  showFloatingFilterLabel?: boolean // Show floating label on filter input border (requires useNewColumnFilter)
  pagination?: boolean
  showNumbers?: boolean
  showNumbersCount?: number
  showFirstPage?: boolean
  showLastPage?: boolean
  firstArrow?: string
  lastArrow?: string
  nextArrow?: string
  previousArrow?: string
  paginationInfo?: string // default: "Showing {0} to {1} of {2} entries"
  noDataContent?: string // default: "No data available",
  stickyHeader?: boolean
  stickyFooter?: boolean
  height?: string // default 450px - only working with sticky headers
  stickyFirstColumn?: boolean
  cloneHeaderInFooter?: boolean
  selectRowOnClick?: boolean
  showClearAllButton?: boolean
  enableleftmenu?: boolean
  enabletopmenu?: boolean
  enableHeaderArea?: boolean // Enables the tableHeaderArea slot
  headerAreaHeight?: string // Height for the tableHeaderArea, e.g., '100px'
  // Left menu props
  leftmenuMinWidth?: number
  leftmenuDefaultWidth?: number
  showResizeButton?: boolean // Show built-in resize button (hidden by default)
  topmenusize?: number
  topmenumax?: number
  topmenumin?: number
  skeletonloader?: boolean
  enableloadinganimation?: boolean
  enablefooterpagination?: boolean
  alwaysShowPagination?: boolean
  footerOffset?: number
  tableRightOffset?: number
  tableLeftOffset?: number
  initialLeftMenuState?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  isServerMode: false,
  skin: 'bh-table-striped bh-table-hover',
  totalRows: 0,
  rows: () => [],
  footerRows: () => [],
  columns: () => [],
  hasCheckbox: false,
  hasSubtable: false,
  hasRightPanel: false,
  checkboxColumnWidth: '40px',
  rightPanelColumnWidth: '40px',
  subtableColumnWidth: '40px',
  subtableMaxHeight: '400px',
  subtableLazyLoading: false,
  expandall: false,
  search: '',
  columnChooser: false,
  page: 1,
  pageSize: 10,
  pageSizeOptions: () => [10, 20, 30, 50, 100],
  showPageSize: true,
  rowClass: <never>[],
  cellClass: <never>[],
  cellRenderer: null,
  sortable: false,
  sortColumn: 'id',
  sortDirection: 'asc',
  columnFilter: false,
  columnFilterLang: null,
  useNewColumnFilter: false,
  showFloatingFilterLabel: false,
  pagination: true,
  showNumbers: true,
  showNumbersCount: 5,
  showFirstPage: true,
  showLastPage: true,
  firstArrow: '',
  lastArrow: '',
  nextArrow: '',
  previousArrow: '',
  paginationInfo: 'Showing {0} to {1} of {2} entries',
  noDataContent: 'There is no data that match your query.',
  stickyHeader: false,
  stickyFooter: false,
  height: '500px',
  stickyFirstColumn: false,
  cloneHeaderInFooter: false,
  selectRowOnClick: false,
  showClearAllButton: false,
  enableHeaderArea: false,
  headerAreaHeight: '80px',
  footerOffset: 0,
  tableRightOffset: 0,
  tableLeftOffset: 5,
  // Left menu prop defaults
  leftmenuMinWidth: 50,
  leftmenuDefaultWidth: 250,
  initialLeftMenuState: undefined,
  showResizeButton: false,
  alwaysShowPagination: false
})

// set default columns values
for (const item of props.columns || []) {
  const type = item.type?.toLowerCase() || 'string'
  item.type = type
  item.isUnique = item.isUnique !== undefined ? item.isUnique : false
  item.hide = item.hide !== undefined ? item.hide : false
  item.dataOnly = item.dataOnly !== undefined ? item.dataOnly : false
  item.filter = item.filter !== undefined ? item.filter : true
  item.search = item.search !== undefined ? item.search : true
  item.sort = item.sort !== undefined ? item.sort : true
  item.html = item.html !== undefined ? item.html : false
  // Only set condition if value exists, otherwise leave empty
  if (item.value !== undefined && item.value !== null && item.value !== '') {
    item.condition = item.condition || 'Equal'
  } else {
    item.condition = ''
  }
}

const filterItems: Ref<Array<any>> = ref([])
const currentPage = ref(props.page)
const currentPageSize = ref(
  props.pagination ? props.pageSize : props.rows?.length
)
const oldPageSize = props.pageSize
const currentSortColumn = ref(props.sortColumn)
const oldSortColumn = props.sortColumn
const currentSortDirection = ref(props.sortDirection)
const oldSortDirection = props.sortDirection
const filterRowCount = ref(props.totalRows)
const selected: Ref<Array<any>> = ref([])
const selectedAll: any = ref(null)
const currentLoader = ref(props.loading)
const currentSearch = ref(props.search)
const oldColumns = JSON.parse(JSON.stringify(props.columns))

const isOpenFilter: any = ref(null)

// Trigger for external filter updates (used by setColumnFilter)
const filterUpdateTrigger = ref(0)

// row click
const timer: any = ref(null)
let clickCount: Ref<number> = ref(0)
const delay: Ref<number> = ref(230)

// Left menu state
const currentLeftMenuWidth = ref(props.leftmenuDefaultWidth)
const isLeftMenuMinimized = ref(false)
const leftmenuel = ref(null)

// ============================================================================
// FAZ I OPTIMIZATION 1: cellValue memoization with Map cache
// ============================================================================
const cellValueCache = new Map<string, any>()

const cellValue = (item: any, field: string | undefined) => {
  if (!field) return undefined

  const cacheKey = `${item.id || JSON.stringify(item)}-${field}`

  if (cellValueCache.has(cacheKey)) {
    return cellValueCache.get(cacheKey)
  }

  const value = field.split('.').reduce((obj, key) => obj?.[key], item)
  cellValueCache.set(cacheKey, value)

  return value
}

// Clear cache when rows change
watch(
  () => props.rows,
  () => {
    cellValueCache.clear()
  },
  { deep: false }
)

// ============================================================================
// FAZ I OPTIMIZATION 2: uniqueKey computed (zaten computed ama pre-compute edelim)
// ============================================================================
const uniqueKey = computed(() => {
  const col = props.columns.find(d => d.isUnique)
  return col?.field || null
})

// Check if any column has active filter
const hasAnyActiveFilter = ref(false)

const updateHasAnyActiveFilter = () => {
  hasAnyActiveFilter.value = props.columns.some((col: any) => {
    return col.value !== undefined && col.value !== null && col.value !== ''
  })
}

// Optimization: Only compute when uniqueKey exists, otherwise use index directly
const rowKeys = computed(() => {
  if (!uniqueKey.value) return null
  return new Map(
    filterItems.value.map((item, index) => [
      index,
      item[uniqueKey.value as never]
    ])
  )
})

// Helper function for template to get row key
const getRowKey = (index: number) => {
  return uniqueKey.value ? rowKeys.value?.get(index) ?? index : index
}

// Helper function to check if row is expanded
const isRowExpanded = (item: any, index: number) => {
  const rowId = item._rowIndex !== undefined ? item._rowIndex : item.id || index
  return expandedrows.value.get(rowId) === true
}

// ============================================================================
// FAZ I OPTIMIZATION 3: typeof checks → computed boolean flags
// ============================================================================
const isRowClassFunction = computed(() => typeof props.rowClass === 'function')
const isCellClassFunction = computed(
  () => typeof props.cellClass === 'function'
)

// ============================================================================
// FAZ III OPTIMIZATION: Intl.Collator instance cache
// ============================================================================
const collatorCache = new Map<string, Intl.Collator>()

const getCollator = (isNumeric: boolean) => {
  const key = isNumeric ? 'numeric' : 'string'

  if (!collatorCache.has(key)) {
    collatorCache.set(
      key,
      new Intl.Collator(undefined, {
        numeric: isNumeric,
        sensitivity: 'base'
      })
    )
  }

  return collatorCache.get(key)!
}

// ============================================================================
// FAZ I OPTIMIZATION 4: filteredRows() → computed (EN KRİTİK!)
// ============================================================================
const filteredRows = computed(() => {
  let rows = props.rows || []

  if (!props.isServerMode) {
    props.columns?.forEach(d => {
      if (
        d.filter &&
        ((d.value !== undefined && d.value !== null && d.value !== '') ||
          d.condition === 'IsNull' ||
          d.condition == 'IsNotNull')
      ) {
        // string filters
        if (d.type === 'string') {
          if (d.value && !d.condition) {
            d.condition = 'Contains'
          }

          if (d.condition === 'Contains') {
            rows = rows.filter(item => {
              return cellValue(item, d.field)
                ?.toString()
                .toLowerCase()
                .includes(d.value.toLowerCase())
            })
          } else if (d.condition === 'NotContains') {
            rows = rows.filter(item => {
              return !cellValue(item, d.field)
                ?.toString()
                .toLowerCase()
                .includes(d.value.toLowerCase())
            })
          } else if (d.condition === 'Equal') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field)?.toString().toLowerCase() ===
                d.value.toLowerCase()
              )
            })
          } else if (d.condition === 'NotEqual') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field)?.toString().toLowerCase() !==
                d.value.toLowerCase()
              )
            })
          } else if (d.condition == 'StartsWith') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field)
                  ?.toString()
                  .toLowerCase()
                  .indexOf(d.value.toLowerCase()) === 0
              )
            })
          } else if (d.condition == 'EndsWith') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field)
                  ?.toString()
                  .toLowerCase()
                  .substr(d.value.length * -1) === d.value.toLowerCase()
              )
            })
          }
        }
        // number filters
        else if (d.type === 'number') {
          if (d.value && !d.condition) {
            d.condition = 'Equal'
          }

          if (d.condition === 'Equal') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                parseFloat(cellValue(item, d.field)) === parseFloat(d.value)
              )
            })
          } else if (d.condition === 'NotEqual') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                parseFloat(cellValue(item, d.field)) !== parseFloat(d.value)
              )
            })
          } else if (d.condition === 'GreaterThan') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                parseFloat(cellValue(item, d.field)) > parseFloat(d.value)
              )
            })
          } else if (d.condition === 'GreaterThanOrEqual') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                parseFloat(cellValue(item, d.field)) >= parseFloat(d.value)
              )
            })
          } else if (d.condition === 'LessThan') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                parseFloat(cellValue(item, d.field)) < parseFloat(d.value)
              )
            })
          } else if (d.condition === 'LessThanOrEqual') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                parseFloat(cellValue(item, d.field)) <= parseFloat(d.value)
              )
            })
          }
        }
        // date filters
        else if (d.type === 'date') {
          if (d.value && !d.condition) {
            d.condition = 'Equal'
          }

          if (d.condition === 'Equal') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                dateFormat(cellValue(item, d.field)) === d.value
              )
            })
          } else if (d.condition === 'NotEqual') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                dateFormat(cellValue(item, d.field)) !== d.value
              )
            })
          } else if (d.condition === 'GreaterThan') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                dateFormat(cellValue(item, d.field)) > d.value
              )
            })
          } else if (d.condition === 'LessThan') {
            rows = rows.filter(item => {
              return (
                cellValue(item, d.field) &&
                dateFormat(cellValue(item, d.field)) < d.value
              )
            })
          }
        }
        // boolean filters
        else if (d.type === 'bool') {
          rows = rows.filter(item => {
            return cellValue(item, d.field) === d.value
          })
        }

        if (d.condition === 'IsNull') {
          rows = rows.filter(item => {
            return (
              cellValue(item, d.field) == null || cellValue(item, d.field) == ''
            )
          })
          d.value = ''
        } else if (d.condition === 'IsNotNull') {
          d.value = ''
          rows = rows.filter(item => {
            return cellValue(item, d.field)
          })
        }
      }
    })

    if (currentSearch.value && rows?.length) {
      let final: Array<any> = []

      const keys = (props.columns || [])
        .filter(d => d.search && !d.hide)
        .map(d => {
          return d.field
        })

      for (var j = 0; j < rows?.length; j++) {
        for (var i = 0; i < keys.length; i++) {
          if (
            cellValue(rows[j], keys[i])
              ?.toString()
              .toLowerCase()
              .includes(currentSearch.value.toLowerCase())
          ) {
            final.push(rows[j])
            break
          }
        }
      }

      rows = final
    }

    // sort rows - Use cached collator
    const isNumeric =
      props.columns.find(col => col.field == currentSortColumn.value)?.type ===
      'number'
    const collator = getCollator(isNumeric || false)
    const sortOrder = currentSortDirection.value === 'desc' ? -1 : 1

    rows.sort((a: any, b: any): number => {
      const valA = currentSortColumn.value
        ?.split('.')
        .reduce((obj: any, key: string) => obj?.[key], a)
      const valB = currentSortColumn.value
        ?.split('.')
        .reduce((obj: any, key: string) => obj?.[key], b)

      return collator.compare(valA, valB) * sortOrder
    })
  }

  return rows
})

// Optimization: Use Map for O(1) lookup instead of array find O(n)
const expandedrows = ref<Map<any, boolean>>(new Map())

// Update filterRows to use computed filteredRows
const filterRows = () => {
  let result = []
  let rows = filteredRows.value // Use .value to access computed

  if (props.isServerMode) {
    filterRowCount.value = props.totalRows || 0
    result = rows
  } else {
    filterRowCount.value = rows?.length || 0
    result = rows.slice(offset.value - 1, <number>limit.value)
  }

  if (props.hasSubtable) {
    result.forEach(function (value, index) {
      if (value.isExpanded !== undefined) {
        const rowId =
          value._rowIndex !== undefined ? value._rowIndex : value.id || index
        expandedrows.value.set(rowId, value.isExpanded)
      }
    })
  }

  filterItems.value = result || []
}

// Sol menü stilini güncelleme fonksiyonu
const updateLeftMenuStyle = () => {
  if (leftmenuel.value) {
    const minMaxWidth = isLeftMenuMinimized.value
      ? props.leftmenuMinWidth
      : props.leftmenuDefaultWidth
    leftmenuel.value.style.cssText = `
      width: ${currentLeftMenuWidth.value}px !important;
      min-width: ${minMaxWidth}px !important;
      max-width: ${minMaxWidth}px !important;
    `
  }
}

// Resize olayını ele alan fonksiyon
const handleResize = () => {
  if (!isLeftMenuMinimized.value) {
    currentLeftMenuWidth.value = props.leftmenuDefaultWidth
  } else {
    currentLeftMenuWidth.value = props.leftmenuMinWidth
  }
  updateLeftMenuStyle()
}

// Toggle left menu between minimized and default width
const toggleLeftMenu = () => {
  isLeftMenuMinimized.value = !isLeftMenuMinimized.value
  currentLeftMenuWidth.value = isLeftMenuMinimized.value
    ? props.leftmenuMinWidth
    : props.leftmenuDefaultWidth

  updateLeftMenuStyle()
  emit('currentLeftMenuSize', currentLeftMenuWidth.value)
}

onMounted(() => {
  filterRows()

  nextTick(() => {
    if (topmenusize.value <= 0) topmenusize.value = 10
    emit('currentTopMenuSize', props.topmenumin || 20)

    if (props.initialLeftMenuState !== undefined) {
      isLeftMenuMinimized.value = props.initialLeftMenuState
      currentLeftMenuWidth.value = isLeftMenuMinimized.value
        ? props.leftmenuMinWidth
        : props.leftmenuDefaultWidth
    } else {
      currentLeftMenuWidth.value = props.leftmenuDefaultWidth
    }

    updateLeftMenuStyle()
    window.addEventListener('resize', handleResize)
  })
})

const emit = defineEmits([
  'change',
  'sortChange',
  'searchChange',
  'pageChange',
  'pageSizeChange',
  'rowSelect',
  'filterChange',
  'rowClick',
  'rowDBClick',
  'currentTopMenuSize',
  'currentLeftMenuSize',
  'rowRightPanelClick',
  'clearAllFilters',
  'cellContextMenu'
])

// Cell context menu handler
const handleCellContextMenu = (
  event: MouseEvent,
  row: any,
  column: ColumnDefinition,
  value: any,
  rowIndex: number,
  columnIndex: number
) => {
  event.preventDefault()
  emit('cellContextMenu', {
    event,
    row,
    column,
    value,
    rowIndex,
    columnIndex
  })
}

defineExpose({
  reset() {
    reset()
  },
  getSelectedRows() {
    return getSelectedRows()
  },
  getColumnFilters() {
    return getColumnFilters()
  },
  clearSelectedRows() {
    return clearSelectedRows()
  },
  selectRow(index: number) {
    selectRow(index)
  },
  unselectRow(index: number) {
    unselectRow(index)
  },
  isRowSelected(index: number) {
    return isRowSelected(index)
  },
  getFilteredRows() {
    return filteredRows.value
  },
  collapseAll() {
    collapseAll()
  },
  setLeftMenuState(minimized: boolean) {
    isLeftMenuMinimized.value = minimized
    currentLeftMenuWidth.value = minimized
      ? props.leftmenuMinWidth
      : props.leftmenuDefaultWidth
    updateLeftMenuStyle()
  },
  clearAllFilters() {
    clearAllFilters()
  },
  /**
   * Set column filter value and optionally trigger filter
   * @param field - Column field name
   * @param value - Filter value
   * @param condition - Filter condition (default: Equal)
   * @param triggerFilter - Whether to trigger filterChange event (default: false)
   */
  setColumnFilter(
    field: string,
    value: string,
    condition?: string,
    triggerFilter: boolean = false
  ) {
    const column = props.columns.find(col => col.field === field)
    if (column) {
      column.value = value
      // Set condition: use provided or default to Equal
      column.condition = condition || 'Equal'
      // Trigger UI update in column-header
      filterUpdateTrigger.value++
      updateHasAnyActiveFilter()
      if (triggerFilter) {
        filterChange()
      }
    }
    return !!column
  }
})

watch(
  () => props.initialLeftMenuState,
  newValue => {
    if (newValue !== undefined) {
      isLeftMenuMinimized.value = newValue
      currentLeftMenuWidth.value = isLeftMenuMinimized.value
        ? props.leftmenuMinWidth
        : props.leftmenuDefaultWidth
      updateLeftMenuStyle()
    }
  },
  { immediate: true }
)

const stringFormat = (template: string, ...args: any[]) => {
  return template.replace(/{(\d+)}/g, (match, number) => {
    return typeof args[number] !== 'undefined' ? args[number] : match
  })
}

// Maximum number of pages
const maxPage = computed(() => {
  const totalPages =
    <number>currentPageSize.value < 1
      ? 1
      : Math.ceil(<number>filterRowCount.value / <number>currentPageSize.value)
  return Math.max(totalPages || 0, 1)
})

// The starting value of the page number
const offset = computed(() => {
  return (currentPage.value - 1) * <number>currentPageSize.value + 1
})

// Maximum number of pages
const limit = computed(() => {
  const limit = currentPage.value * <number>currentPageSize.value
  return <number>filterRowCount.value >= limit ? limit : filterRowCount.value
})

// Paging array
const paging = computed(() => {
  let startPage: number, endPage: number
  let isMaxSized =
    typeof props.showNumbersCount !== 'undefined' &&
    <number>props.showNumbersCount < maxPage.value
  if (isMaxSized) {
    startPage = Math.max(
      currentPage.value - Math.floor(<number>props.showNumbersCount / 2),
      1
    )
    endPage = startPage + <number>props.showNumbersCount - 1

    if (endPage > maxPage.value) {
      endPage = maxPage.value
      startPage = endPage - <number>props.showNumbersCount + 1
    }
  } else {
    startPage = 1
    endPage = maxPage.value
  }

  const pages = Array.from(Array(endPage + 1 - startPage).keys()).map(
    i => startPage + i
  )

  return pages
})

watch(
  () => props.loading,
  () => {
    currentLoader.value = props.loading
  }
)

const toggleFilterMenu = (col: ColumnDefinition) => {
  if (col) {
    if (isOpenFilter.value === col.field) {
      isOpenFilter.value = null
    } else {
      isOpenFilter.value = col.field
    }
  } else {
    isOpenFilter.value = null
  }
}

const previousPage = () => {
  if (currentPage.value == 1) {
    return false
  }
  currentPage.value--
}

const movePage = (page: number) => {
  currentPage.value = page
}

const nextPage = () => {
  if (currentPage.value >= maxPage.value) {
    return false
  }
  currentPage.value++
}

const changePage = () => {
  selectAll(false)

  if (props.isServerMode) {
    changeForServer('page')
  } else {
    filterRows()
    emit('pageChange', currentPage.value)
  }
}
watch(() => currentPage.value, changePage)

const changeRows = () => {
  if (!props.isServerMode) {
    currentPage.value = 1
  }
  selectAll(false)
  filterRows()
  updateHasAnyActiveFilter()
}
watch(() => props.rows, changeRows)

const setPageSize = (pagesize: number) => {
  currentPageSize.value = pagesize
}

const changePageSize = () => {
  selectAll(false)

  if (props.isServerMode) {
    if (currentPage.value === 1) {
      changeForServer('pagesize', true)
    } else {
      currentPage.value = 1
    }
  } else {
    currentPage.value = 1
    filterRows()
    emit('pageSizeChange', currentPageSize.value)
  }
}
watch(() => currentPageSize.value, changePageSize)

const sortChange = (field: string, specifiedDirection?: string) => {
  // Use specified direction or auto-toggle
  let direction = specifiedDirection || 'asc'

  if (!specifiedDirection) {
    // Auto-toggle only when direction not explicitly provided (header click)
    if (field == currentSortColumn.value) {
      if (currentSortDirection.value === 'asc') {
        direction = 'desc'
      }
    }
  }

  let offset = (currentPage.value - 1) * <number>currentPageSize.value
  let limit = currentPageSize.value
  currentSortColumn.value = field
  currentSortDirection.value = direction

  selectAll(false)
  filterRows()

  if (props.isServerMode) {
    changeForServer('sort')
  } else {
    emit('sortChange', { offset, limit, field, direction })
  }
}

const checkboxChange = (value: any) => {
  selectedAll.value =
    value.length &&
    filterItems.value.length &&
    value.length === filterItems.value.length

  const rows = filterItems.value.filter((d, i) => {
    const key = uniqueKey.value ? rowKeys.value?.get(i) ?? i : i
    return selected.value.includes(key)
  })

  emit('rowSelect', rows)
}
watch(() => selected.value, checkboxChange)

const selectAll = (checked: any) => {
  if (checked) {
    selected.value = filterItems.value.map((d, i) =>
      uniqueKey.value ? rowKeys.value?.get(i) ?? i : i
    )
  } else {
    selected.value = []
  }
}

const filterChange = () => {
  selectAll(false)
  updateHasAnyActiveFilter()
  if (props.isServerMode) {
    if (currentPage.value === 1) {
      changeForServer('filter', true)
    } else {
      currentPage.value = 1
    }
  } else {
    currentPage.value = 1
    filterRows()
    emit('filterChange', props.columns)
  }
}

// Clear single column filter
const clearColumnFilter = (col: ColumnDefinition) => {
  // Column value and condition already reset by column-filter-new
  // Just trigger filter update
  filterChange()
}

const changeSearch = () => {
  selectAll(false)

  if (props.isServerMode) {
    if (currentPage.value === 1) {
      changeForServer('search', true)
    } else {
      currentPage.value = 1
    }
  } else {
    currentPage.value = 1
    filterRows()
    emit('searchChange', currentSearch.value)
  }
}

watch(
  () => props.search,
  () => {
    currentSearch.value = props.search
    changeSearch()
  }
)

const dateFormat = (date: any) => {
  try {
    if (!date) {
      return ''
    }
    const dt = new Date(date)
    const day = dt.getDate()
    const month = dt.getMonth() + 1
    const year = dt.getFullYear()

    return (
      year +
      '-' +
      (month > 9 ? month : '0' + month) +
      '-' +
      (day > 9 ? day : '0' + day)
    )
  } catch {}
  return ''
}

const rowClick = (item: any, index: number) => {
  clickCount.value++

  if (clickCount.value === 1) {
    timer.value = setTimeout(() => {
      clickCount.value = 0

      if (props.selectRowOnClick) {
        if (isRowSelected(index)) {
          unselectRow(index)
        } else {
          selectRow(index)
        }

        checkboxChange(selected.value)
      }
      emit('rowClick', item)
    }, delay.value)
  } else if (clickCount.value === 2) {
    clearTimeout(timer.value)
    clickCount.value = 0
    emit('rowDBClick', item)
  }
}

const changeForServer = (changeType: string, isResetPage = false) => {
  if (props.isServerMode) {
    setDefaultCondition()

    // DEBUG: Log columns with filters
    const activeFilters = props.columns.filter(c => c.value || c.condition)

    const res = {
      current_page: isResetPage ? 1 : currentPage.value,
      pagesize: currentPageSize.value,
      offset: (currentPage.value - 1) * <number>currentPageSize.value,
      sort_column: currentSortColumn.value,
      sort_direction: currentSortDirection.value,
      search: currentSearch.value,
      column_filters: props.columns,
      change_type: changeType
    }

    emit('change', res)
  }
}

const setDefaultCondition = () => {
  for (let i = 0; i < props.columns.length; i++) {
    let d = props.columns[i]

    if (
      d.filter &&
      ((d.value !== undefined && d.value !== null && d.value !== '') ||
        d.condition === 'IsNull' ||
        d.condition === 'IsNotNull')
    ) {
      if (d.type === 'string' && d.value && !d.condition) {
        d.condition = 'Contains'
      }
      if (d.type === 'number' && d.value && !d.condition) {
        d.condition = 'Equal'
      }
      if (d.type === 'date' && d.value && !d.condition) {
        d.condition = 'Equal'
      }
    }
  }
}

const reset = () => {
  selectAll(false)
  for (let i = 0; i < props.columns.length; i++) {
    props.columns[i].value = ''
  }
  currentSearch.value = ''
  currentPageSize.value = oldPageSize
  currentSortColumn.value = oldSortColumn
  currentSortDirection.value = oldSortDirection

  if (props.isServerMode) {
    if (currentPage.value === 1) {
      changeForServer('reset', true)
    } else {
      currentPage.value = 1
    }
  } else {
    currentPage.value = 1
    filterRows()
  }
}

const getSelectedRows = () => {
  const rows = filterItems.value.filter((d, i) => {
    const key = uniqueKey.value ? rowKeys.value?.get(i) ?? i : i
    return selected.value.includes(key)
  })
  return rows
}

const getColumnFilters = () => {
  return props.columns
}

const clearSelectedRows = () => {
  selected.value = []
}

const selectRow = (index: number) => {
  if (!isRowSelected(index)) {
    const key = uniqueKey.value ? rowKeys.value?.get(index) ?? index : index
    selected.value.push(key)
  }
}

const unselectRow = (index: number) => {
  if (isRowSelected(index)) {
    const key = uniqueKey.value ? rowKeys.value?.get(index) ?? index : index
    selected.value = selected.value.filter(d => d !== key)
  }
}

const isRowSelected = (index: number) => {
  if (index >= filterItems.value.length) return false

  const key = uniqueKey.value ? rowKeys.value?.get(index) ?? index : index
  return selected.value.includes(key)
}

const collapseAll = () => {
  expandedrows.value.forEach((value, key) => {
    expandedrows.value.set(key, false)
  })
}

const clearAllFilters = () => {
  // Clear all column values and conditions
  for (const col of props.columns) {
    if (col.filter) {
      col.value = ''
      col.condition = ''
    }
  }
  updateHasAnyActiveFilter()
  // Trigger filter change
  filterChange()

  // Emit for parent notification
  emit('clearAllFilters')
}

let extracolumnlength = 0
if (props.hasCheckbox) {
  extracolumnlength++
}
if (props.hasSubtable) {
  extracolumnlength++
}
if (props.hasRightPanel) {
  extracolumnlength++
}

// ============================================================================
// FAZ I OPTIMIZATION 5: setInterval kaldırıldı - Gereksiz reactive update
// ============================================================================
// REMOVED: const dtableloadingkey = ref(0)
// REMOVED: const dtableloadingkeyInterval = setInterval(function () {
//     dtableloadingkey.value++
// }, 2200)

const topmenusize = ref(props.topmenusize)
const topmenuel = ref(null)
// Throttle useElementSize to reduce reactive updates during resize
const { height: topmenuheight } = useElementSize(
  topmenuel,
  { box: 'border-box' },
  { throttle: 100 }
)

// Handler for top menu resize events
const emitTopMenuSize = () => {
  nextTick(() => {
    let element = topmenuel.value
    if (element && typeof element === 'object') {
      element = element.$el || element
    }

    if (element instanceof HTMLElement) {
      const pixelHeight = element.offsetHeight || 0
      emit('currentTopMenuSize', pixelHeight)
    }
  })
}

const debouncedEmitTopMenuSize = useDebounceFn(emitTopMenuSize, 50)

const handleTopMenuResize = useThrottleFn(event => {
  if (!event || !event.panes || !event.panes.length) return

  const newSizePercent = event.panes[0].size
  topmenusize.value = newSizePercent
  debouncedEmitTopMenuSize()
}, 16)

// ============================================================================
// FAZ I OPTIMIZATION 6: topmenusize watch - debounced to prevent excessive emits
// ============================================================================
const watchEmitTopMenuSize = useDebounceFn(() => {
  let element = topmenuel.value
  if (element && typeof element === 'object') {
    element = element.$el || element
  }

  if (element instanceof HTMLElement) {
    emit('currentTopMenuSize', element.offsetHeight || 0)
  }
}, 50)

watch(() => topmenusize.value, watchEmitTopMenuSize)

onUnmounted(() => {
  // REMOVED: clearInterval(dtableloadingkeyInterval)
  window.removeEventListener('resize', handleResize)
  cellValueCache.clear()
  // VueUse composables auto-cleanup, no manual clearTimeout needed
})
</script>
<template>
  <div
    class="bh-datatable bh-antialiased bh-relative bh-text-black bh-text-sm bh-font-normal"
  >
    <splitpanes class="default-theme" :style="{ height: props.height }">
      <pane>
        <div class="bh-flex bh-h-full">
          <div
            ref="leftmenuel"
            v-if="enableleftmenu"
            class="left-menu-container bh-relative"
            :style="{
              width: currentLeftMenuWidth + 'px',
              transition: 'width 0.3s ease',
              overflow: 'hidden',
              minWidth:
                (isLeftMenuMinimized
                  ? props.leftmenuMinWidth
                  : props.leftmenuDefaultWidth) + 'px',
              maxWidth:
                (isLeftMenuMinimized
                  ? props.leftmenuMinWidth
                  : props.leftmenuDefaultWidth) + 'px'
            }"
          >
            <slot name="tableleftmenu">
              <span>##Left Menu Slot##</span>
            </slot>

            <div
              v-if="props.showResizeButton"
              class="menu-resize-controls bh-absolute bh-right-0 bh-top-1/2 bh-transform -bh-translate-y-1/2 bh-z-10 bh-bg-gray-100 bh-rounded-l bh-shadow-md bh-select-none"
            >
              <button
                @click="toggleLeftMenu"
                class="bh-w-4 bh-h-10 bh-flex bh-justify-center bh-items-center bh-border-none bh-bg-transparent bh-cursor-pointer bh-outline-none"
              >
                <svg
                  width="8"
                  height="12"
                  viewBox="0 0 8 12"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                  :style="{
                    transform: isLeftMenuMinimized ? 'rotate(180deg)' : 'none'
                  }"
                >
                  <path
                    d="M7 1L1 6L7 11"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                </svg>
              </button>
            </div>
          </div>

          <div
            class="bh-flex-1"
            style="overflow: auto; min-width: 0; width: 100%"
          >
            <splitpanes
              class="default-theme"
              horizontal="horizontal"
              @resize="handleTopMenuResize"
              push-other-panes
              v-if="enabletopmenu"
            >
              <pane
                ref="topmenuel"
                v-if="enabletopmenu"
                :size="topmenusize || 10"
                :max-size="topmenumax || 100"
                :style="{ 'min-height': topmenumin + 'px' }"
              >
                <slot name="tabletopmenu">
                  <span>##Top Menu Slot##</span>
                </slot>
              </pane>
              <pane
                :style="{
                  'padding-right': tableRightOffset + 'px',
                  'padding-left': tableLeftOffset + 'px'
                }"
              >
                <div
                  v-if="enableHeaderArea"
                  class="bh-w-full bh-overflow-auto"
                  :style="{ height: headerAreaHeight, 'margin-bottom': '10px' }"
                >
                  <slot name="tableHeaderArea">
                    <span>##Table Header Area Slot##</span>
                  </slot>
                </div>
                <slot name="tableactionheader">
                  <span>##Table Action Header Slot##</span>
                </slot>

                <div
                  class="bh-table-responsive"
                  :class="{ 'bh-min-h-[100px]': currentLoader }"
                  :style="{
                    overflow: 'auto',
                    height: props.stickyHeader
                      ? Number(props.height.replace('px', '')) -
                        (props.footerOffset + (topmenuheight || 0)) +
                        'px'
                      : 'auto'
                  }"
                >
                  <table :class="[props.skin]">
                    <thead
                      :class="{
                        'bh-sticky bh-top-0 bh-z-10': props.stickyHeader
                      }"
                    >
                      <column-header
                        :all="props"
                        :expandedrows="expandedrows"
                        :currentSortColumn="currentSortColumn"
                        :currentSortDirection="currentSortDirection"
                        :isOpenFilter="isOpenFilter"
                        :checkAll="selectedAll"
                        :columnFilterLang="props.columnFilterLang"
                        :hasFilterDatetimeSlot="hasFilterDatetimeSlot"
                        :showClearAllButton="props.showClearAllButton"
                        :hasAnyActiveFilter="hasAnyActiveFilter"
                        :filterUpdateTrigger="filterUpdateTrigger"
                        @selectAll="selectAll"
                        @sortChange="sortChange"
                        @filterChange="filterChange"
                        @toggleFilterMenu="toggleFilterMenu"
                        @clearColumnFilter="clearColumnFilter"
                        @clearAllFilters="clearAllFilters"
                      >
                        <template
                          v-if="hasFilterDatetimeSlot"
                          #filter-datetime="slotProps"
                        >
                          <slot name="filter-datetime" v-bind="slotProps" />
                        </template>
                      </column-header>
                    </thead>
                    <tbody>
                      <template
                        v-for="(item, i) in filterItems"
                        :key="getRowKey(i)"
                      >
                        <tr
                          v-if="filterRowCount"
                          :class="[
                            isRowClassFunction
                              ? rowClass(item)
                              : props.rowClass,
                            props.selectRowOnClick ? 'bh-cursor-pointer' : ''
                          ]"
                          @click.prevent="rowClick(item, i)"
                        >
                          <td
                            v-if="props.hasCheckbox"
                            :style="{
                              width: props.checkboxColumnWidth + ' !important',
                              minWidth:
                                props.checkboxColumnWidth + ' !important'
                            }"
                            :class="{
                              'bh-sticky bh-left-0 bh-bg-blue-light':
                                props.stickyFirstColumn
                            }"
                          >
                            <div class="bh-checkbox">
                              <input
                                v-model="selected"
                                type="checkbox"
                                :value="getRowKey(i)"
                                @click.stop
                              />
                              <div>
                                <icon-check class="check" />
                              </div>
                            </div>
                          </td>
                          <td
                            v-if="props.hasRightPanel"
                            :style="{
                              width:
                                props.rightPanelColumnWidth + ' !important',
                              minWidth:
                                props.rightPanelColumnWidth + ' !important',
                              padding: '0px !important'
                            }"
                            :class="{
                              'bh-sticky bh-left-0 bh-bg-blue-light':
                                props.stickyFirstColumn
                            }"
                          >
                            <ButtonRightPanel
                              :item="item"
                              @rightPanelClick="
                                rowData => emit('rowRightPanelClick', rowData)
                              "
                            >
                            </ButtonRightPanel>
                          </td>
                          <td
                            v-if="props.hasSubtable"
                            :style="{
                              width: props.subtableColumnWidth + ' !important',
                              minWidth:
                                props.subtableColumnWidth + ' !important'
                            }"
                            :class="{
                              'bh-sticky bh-left-0 bh-bg-blue-light':
                                props.stickyFirstColumn
                            }"
                          >
                            <button-expand
                              :item="{ ...item, _rowIndex: i }"
                              :expandedrows="expandedrows"
                            >
                            </button-expand>
                          </td>
                          <template v-for="(col, j) in props.columns">
                            <td
                              v-if="!col.hide && !col.dataOnly"
                              :key="col.field"
                              :class="[
                                isCellClassFunction
                                  ? cellClass(item)
                                  : props.cellClass,
                                j === 0 && props.stickyFirstColumn
                                  ? 'bh-sticky bh-left-0 bh-bg-blue-light'
                                  : '',
                                props.hasCheckbox &&
                                j === 0 &&
                                props.stickyFirstColumn
                                  ? 'bh-left-[52px]'
                                  : '',
                                col.cellClass ? col.cellClass : ''
                              ]"
                              @contextmenu="handleCellContextMenu($event, item, col, cellValue(item, col.field), i, j)"
                            >
                              <template v-if="slots[col.field]">
                                <slot :name="col.field" :value="item"></slot>
                              </template>
                              <div
                                v-else-if="col.cellRenderer"
                                v-html="col.cellRenderer(item)"
                              ></div>
                              <template v-else>
                                {{ cellValue(item, col.field) }}
                              </template>
                            </td>
                          </template>
                        </tr>
                        <template
                          v-if="isRowExpanded(item, i) && props.hasSubtable"
                        >
                          <tr
                            :class="[
                              isRowClassFunction
                                ? rowClass(item)
                                : props.rowClass,
                              props.selectRowOnClick ? 'bh-cursor-pointer' : ''
                            ]"
                            @click.prevent="rowClick(item, i)"
                          >
                            <td
                              :colspan="
                                props.columns.length + extracolumnlength
                              "
                            >
                              <slot
                                name="tsub"
                                :rowData="item"
                                :rowIndex="i"
                                :filterItems="filterItems"
                              ></slot>
                            </td>
                          </tr>
                        </template>
                      </template>

                      <template
                        v-if="
                          !filterRowCount && currentLoader && skeletonloader
                        "
                      >
                        <tr
                          v-for="i in props.pageSize"
                          :key="i"
                          class="!bh-bg-white bh-h-11 !bh-border-transparent"
                        >
                          <td
                            :colspan="props.columns.length + extracolumnlength"
                            class="!bh-p-0 !bh-border-transparent"
                          >
                            <div class="bh-skeleton-box bh-h-8"></div>
                          </td>
                        </tr>
                      </template>

                      <template v-if="filterRowCount">
                        <tr
                          v-for="(item, i) in props.footerRows"
                          :key="item[uniqueKey] ? item[uniqueKey] : i"
                          class="sticky-table-footer"
                        >
                          <td
                            v-if="extracolumnlength > 0"
                            :colspan="extracolumnlength"
                          ></td>
                          <template v-for="(col, j) in props.columns">
                            <td
                              v-if="!col.hide && !col.dataOnly"
                              :key="col.field"
                              :class="[
                                isCellClassFunction
                                  ? cellClass(item)
                                  : props.cellClass,
                                j === 0 && props.stickyFirstColumn
                                  ? 'bh-sticky bh-left-0 bh-bg-blue-light'
                                  : '',
                                props.hasCheckbox &&
                                j === 0 &&
                                props.stickyFirstColumn
                                  ? 'bh-left-[52px]'
                                  : '',
                                col.cellClass ? col.cellClass : ''
                              ]"
                            >
                              <template
                                v-if="
                                  item.cells.find(x => x.field == col.field)
                                "
                              >
                                {{
                                  item.cells.find(x => x.field == col.field)
                                    .text
                                }}
                              </template>
                            </td>
                          </template>
                        </tr>
                      </template>
                    </tbody>

                    <tfoot
                      v-if="props.cloneHeaderInFooter"
                      :class="{
                        'bh-sticky bh-bottom-0': props.stickyHeader
                      }"
                    >
                      <column-header
                        :all="props"
                        :currentSortColumn="currentSortColumn"
                        :currentSortDirection="currentSortDirection"
                        :isOpenFilter="isOpenFilter"
                        :isFooter="true"
                        :checkAll="selectedAll"
                        :hasFilterDatetimeSlot="hasFilterDatetimeSlot"
                        :showClearAllButton="props.showClearAllButton"
                        :hasAnyActiveFilter="hasAnyActiveFilter"
                        @selectAll="selectAll"
                        @sortChange="sortChange"
                        @filterChange="filterChange"
                        @toggleFilterMenu="toggleFilterMenu"
                        @clearAllFilters="clearAllFilters"
                      >
                        <template
                          v-if="hasFilterDatetimeSlot"
                          #filter-datetime="slotProps"
                        >
                          <slot name="filter-datetime" v-bind="slotProps" />
                        </template>
                      </column-header>
                    </tfoot>
                  </table>

                  <div
                    v-if="currentLoader && enableloadinganimation"
                    class="bh-absolute bh-inset-0 bh-bg-blue-light/50 bh-grid bh-place-content-center dt-center-loading"
                    :style="{
                      height:
                        Number(props.height.replace('px', '')) - 175 + 'px'
                    }"
                  >
                    <slot name="loadercontent"></slot>
                  </div>

                  <div
                    v-if="!filterRowCount && !currentLoader"
                    class="nodatacontent"
                    :style="{
                      height:
                        Number(props.height.replace('px', '')) - 175 + 'px'
                    }"
                  >
                    <slot name="nodatacontent">
                      <span>{{ props.noDataContent }}</span>
                    </slot>
                  </div>
                </div>
              </pane>
            </splitpanes>

            <div
              v-if="!enabletopmenu"
              class="bh-w-full bh-h-full"
              :style="{
                'padding-right': tableRightOffset + 'px',
                'padding-left': tableLeftOffset + 'px'
              }"
            >
              <div
                v-if="enableHeaderArea"
                class="bh-w-full bh-overflow-auto"
                :style="{ height: headerAreaHeight, 'margin-bottom': '10px' }"
              >
                <slot name="tableHeaderArea">
                  <span>##Table Header Area Slot##</span>
                </slot>
              </div>
              <slot name="tableactionheader"></slot>
              <div
                class="bh-table-responsive"
                :class="{ 'bh-min-h-[100px]': currentLoader }"
                :style="{
                  overflow: 'auto',
                  height: props.stickyHeader
                    ? Number(props.height.replace('px', '')) -
                      props.footerOffset +
                      'px'
                    : 'auto'
                }"
              >
                <table :class="[props.skin]">
                  <thead
                    :class="{
                      'bh-sticky bh-top-0 bh-z-10': props.stickyHeader
                    }"
                  >
                    <column-header
                      :all="props"
                      :expandedrows="expandedrows"
                      :currentSortColumn="currentSortColumn"
                      :currentSortDirection="currentSortDirection"
                      :isOpenFilter="isOpenFilter"
                      :checkAll="selectedAll"
                      :columnFilterLang="props.columnFilterLang"
                      :hasFilterDatetimeSlot="hasFilterDatetimeSlot"
                      :showClearAllButton="props.showClearAllButton"
                      :hasAnyActiveFilter="hasAnyActiveFilter"
                      :filterUpdateTrigger="filterUpdateTrigger"
                      @selectAll="selectAll"
                      @sortChange="sortChange"
                      @filterChange="filterChange"
                      @toggleFilterMenu="toggleFilterMenu"
                      @clearColumnFilter="clearColumnFilter"
                      @clearAllFilters="clearAllFilters"
                    >
                      <template
                        v-if="hasFilterDatetimeSlot"
                        #filter-datetime="slotProps"
                      >
                        <slot name="filter-datetime" v-bind="slotProps" />
                      </template>
                    </column-header>
                  </thead>
                  <tbody>
                    <template
                      v-for="(item, i) in filterItems"
                      :key="getRowKey(i)"
                    >
                      <tr
                        v-if="filterRowCount"
                        :class="[
                          isRowClassFunction ? rowClass(item) : props.rowClass,
                          props.selectRowOnClick ? 'bh-cursor-pointer' : ''
                        ]"
                        @click.prevent="rowClick(item, i)"
                      >
                        <td
                          v-if="props.hasCheckbox"
                          :style="{
                            width: props.checkboxColumnWidth + ' !important',
                            minWidth: props.checkboxColumnWidth + ' !important'
                          }"
                          :class="{
                            'bh-sticky bh-left-0 bh-bg-blue-light':
                              props.stickyFirstColumn
                          }"
                        >
                          <div class="bh-checkbox">
                            <input
                              v-model="selected"
                              type="checkbox"
                              :value="getRowKey(i)"
                              @click.stop
                            />
                            <div>
                              <icon-check class="check" />
                            </div>
                          </div>
                        </td>
                        <td
                          v-if="props.hasRightPanel"
                          :style="{
                            width: props.rightPanelColumnWidth + ' !important',
                            minWidth:
                              props.rightPanelColumnWidth + ' !important',
                            padding: '0px !important'
                          }"
                          :class="{
                            'bh-sticky bh-left-0 bh-bg-blue-light':
                              props.stickyFirstColumn
                          }"
                        >
                          <ButtonRightPanel
                            :item="item"
                            @rightPanelClick="
                              rowData => emit('rowRightPanelClick', rowData)
                            "
                          >
                          </ButtonRightPanel>
                        </td>
                        <td
                          v-if="props.hasSubtable"
                          :style="{
                            width: props.subtableColumnWidth + ' !important',
                            minWidth: props.subtableColumnWidth + ' !important'
                          }"
                          :class="{
                            'bh-sticky bh-left-0 bh-bg-blue-light':
                              props.stickyFirstColumn
                          }"
                        >
                          <button-expand
                            :item="{ ...item, _rowIndex: i }"
                            :expandedrows="expandedrows"
                          >
                          </button-expand>
                        </td>
                        <template v-for="(col, j) in props.columns">
                          <td
                            v-if="!col.hide && !col.dataOnly"
                            :key="col.field"
                            :class="[
                              isCellClassFunction
                                ? cellClass(item)
                                : props.cellClass,
                              j === 0 && props.stickyFirstColumn
                                ? 'bh-sticky bh-left-0 bh-bg-blue-light'
                                : '',
                              props.hasCheckbox &&
                              j === 0 &&
                              props.stickyFirstColumn
                                ? 'bh-left-[52px]'
                                : '',
                              col.cellClass ? col.cellClass : ''
                            ]"
                            @contextmenu="handleCellContextMenu($event, item, col, cellValue(item, col.field), i, j)"
                          >
                            <template v-if="slots[col.field]">
                              <slot :name="col.field" :value="item"></slot>
                            </template>
                            <div
                              v-else-if="col.cellRenderer"
                              v-html="col.cellRenderer(item)"
                            ></div>
                            <template v-else>
                              {{ cellValue(item, col.field) }}
                            </template>
                          </td>
                        </template>
                      </tr>
                      <template
                        v-if="isRowExpanded(item, i) && props.hasSubtable"
                      >
                        <tr
                          :class="[
                            isRowClassFunction
                              ? rowClass(item)
                              : props.rowClass,
                            props.selectRowOnClick ? 'bh-cursor-pointer' : ''
                          ]"
                          @click.prevent="rowClick(item, i)"
                        >
                          <td
                            :colspan="props.columns.length + extracolumnlength"
                          >
                            <div
                              class="subtable-container"
                              :style="{
                                maxHeight: props.subtableMaxHeight,
                                overflow: 'auto',
                                padding: '10px',
                                background: 'var(--white)',
                                border: '1px solid var(--fade-grey)'
                              }"
                            >
                              <slot
                                name="tsub"
                                :rowData="item"
                                :rowIndex="i"
                                :filterItems="filterItems"
                              ></slot>
                            </div>
                          </td>
                        </tr>
                      </template>
                    </template>

                    <template
                      v-if="!filterRowCount && currentLoader && skeletonloader"
                    >
                      <tr
                        v-for="i in props.pageSize"
                        :key="i"
                        class="!bh-bg-white bh-h-11 !bh-border-transparent"
                      >
                        <td
                          :colspan="props.columns.length + extracolumnlength"
                          class="!bh-p-0 !bh-border-transparent"
                        >
                          <div class="bh-skeleton-box bh-h-8"></div>
                        </td>
                      </tr>
                    </template>

                    <template v-if="filterRowCount">
                      <tr
                        v-for="(item, i) in props.footerRows"
                        :key="item[uniqueKey] ? item[uniqueKey] : i"
                        class="sticky-table-footer"
                      >
                        <td
                          v-if="extracolumnlength > 0"
                          :colspan="extracolumnlength"
                        ></td>
                        <template v-for="(col, j) in props.columns">
                          <td
                            v-if="!col.hide && !col.dataOnly"
                            :key="col.field"
                            :class="[
                              isCellClassFunction
                                ? cellClass(item)
                                : props.cellClass,
                              j === 0 && props.stickyFirstColumn
                                ? 'bh-sticky bh-left-0 bh-bg-blue-light'
                                : '',
                              props.hasCheckbox &&
                              j === 0 &&
                              props.stickyFirstColumn
                                ? 'bh-left-[52px]'
                                : '',
                              col.cellClass ? col.cellClass : ''
                            ]"
                          >
                            <template
                              v-if="item.cells.find(x => x.field == col.field)"
                            >
                              {{
                                item.cells.find(x => x.field == col.field).text
                              }}
                            </template>
                          </td>
                        </template>
                      </tr>
                    </template>
                  </tbody>

                  <tfoot
                    v-if="props.cloneHeaderInFooter"
                    :class="{ 'bh-sticky bh-bottom-0': props.stickyHeader }"
                  >
                    <column-header
                      :all="props"
                      :currentSortColumn="currentSortColumn"
                      :currentSortDirection="currentSortDirection"
                      :isOpenFilter="isOpenFilter"
                      :isFooter="true"
                      :checkAll="selectedAll"
                      :hasFilterDatetimeSlot="hasFilterDatetimeSlot"
                      :showClearAllButton="props.showClearAllButton"
                      :hasAnyActiveFilter="hasAnyActiveFilter"
                      @selectAll="selectAll"
                      @sortChange="sortChange"
                      @filterChange="filterChange"
                      @toggleFilterMenu="toggleFilterMenu"
                      @clearAllFilters="clearAllFilters"
                    >
                      <template
                        v-if="hasFilterDatetimeSlot"
                        #filter-datetime="slotProps"
                      >
                        <slot name="filter-datetime" v-bind="slotProps" />
                      </template>
                    </column-header>
                  </tfoot>
                </table>

                <div
                  v-if="currentLoader && enableloadinganimation"
                  class="bh-absolute bh-inset-0 bh-bg-blue-light/50 bh-grid bh-place-content-center dt-center-loading"
                  :style="{
                    height: Number(props.height.replace('px', '')) - 175 + 'px'
                  }"
                >
                  <slot name="loadercontent"></slot>
                </div>

                <div
                  v-if="!filterRowCount && !currentLoader"
                  class="nodatacontent"
                  :style="{
                    height: Number(props.height.replace('px', '')) - 175 + 'px'
                  }"
                >
                  <slot name="nodatacontent">
                    <span>{{ props.noDataContent }}</span>
                  </slot>
                </div>
              </div>
            </div>
          </div>
        </div>
      </pane>
    </splitpanes>

    <div
      v-if="props.pagination && (filterRowCount || props.alwaysShowPagination)"
      class="bh-pagination"
      :class="{
        'bh-pointer-events-none': currentLoader,
        'sticky-footer': props.stickyFooter
      }"
    >
      <div
        class="bh-flex bh-items-center bh-flex-wrap bh-flex-col sm:bh-flex-row bh-gap-4"
      >
        <slot
          name="footerpageinfo"
          v-if="enablefooterpagination"
          :paginationInfo="paginationInfo"
          :filterRowCount="filterRowCount"
          :offset="offset"
          :limit="limit"
          :showPageSize="showPageSize"
          :pageSizeOptions="pageSizeOptions"
          :currentPageSize="currentPageSize"
          :stringFormat="stringFormat"
          :setPageSize="setPageSize"
        >
          <div class="bh-pagination-info bh-flex bh-items-center">
            <span class="bh-mr-2">
              {{
                stringFormat(
                  props.paginationInfo,
                  filterRowCount ? offset : 0,
                  limit,
                  filterRowCount
                )
              }}
            </span>
            <select
              v-if="props.showPageSize"
              v-model="currentPageSize"
              class="bh-pagesize"
            >
              <option
                v-for="option in props.pageSizeOptions"
                :value="option"
                :key="option"
              >
                {{ option }}
              </option>
            </select>
          </div>
        </slot>
        <slot
          name="footerpagination"
          v-if="enablefooterpagination"
          :currentPage="currentPage"
          :maxPage="maxPage"
          :paging="paging"
          :movePage="movePage"
          :nextPage="nextPage"
          :previousPage="previousPage"
        >
          <div
            class="bh-pagination-number sm:bh-ml-auto bh-inline-flex bh-items-center bh-space-x-1"
          >
            <button
              v-if="props.showFirstPage"
              type="button"
              class="bh-page-item first-page"
              :class="{ disabled: currentPage <= 1 }"
              @click="currentPage = 1"
            >
              <span v-if="props.firstArrow" v-html="props.firstArrow"></span>
              <svg
                v-else
                aria-hidden="true"
                width="14"
                height="14"
                viewBox="0 0 16 16"
              >
                <g fill="currentColor" fill-rule="evenodd">
                  <path
                    d="M8.354 1.646a.5.5 0 0 1 0 .708L2.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"
                  />
                  <path
                    d="M12.354 1.646a.5.5 0 0 1 0 .708L6.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"
                  />
                </g>
              </svg>
            </button>
            <button
              type="button"
              class="bh-page-item previous-page"
              :class="{ disabled: currentPage <= 1 }"
              @click="previousPage"
            >
              <span
                v-if="props.previousArrow"
                v-html="props.previousArrow"
              ></span>
              <svg
                v-else
                aria-hidden="true"
                width="14"
                height="14"
                viewBox="0 0 16 16"
              >
                <path
                  fill="currentColor"
                  fill-rule="evenodd"
                  d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"
                />
              </svg>
            </button>

            <template v-if="props.showNumbers">
              <button
                v-for="page in paging"
                :key="page"
                type="button"
                class="bh-page-item"
                :class="{
                  disabled: currentPage === page,
                  'bh-active': page === currentPage
                }"
                @click="movePage(page)"
              >
                {{ page }}
              </button>
            </template>

            <button
              type="button"
              class="bh-page-item next-page"
              :class="{ disabled: currentPage >= maxPage }"
              @click="nextPage"
            >
              <span v-if="props.nextArrow" v-html="props.nextArrow"></span>
              <svg
                v-else
                aria-hidden="true"
                width="14"
                height="14"
                viewBox="0 0 16 16"
              >
                <path
                  fill="currentColor"
                  fill-rule="evenodd"
                  d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8L4.646 2.354a.5.5 0 0 1 0-.708z"
                />
              </svg>
            </button>

            <button
              v-if="props.showLastPage"
              type="button"
              class="bh-page-item last-page"
              :class="{ disabled: currentPage >= maxPage }"
              @click="currentPage = maxPage"
            >
              <span v-if="props.lastArrow" v-html="props.lastArrow"></span>
              <svg
                v-else
                aria-hidden="true"
                width="14"
                height="14"
                viewBox="0 0 16 16"
              >
                <g fill="currentColor" fill-rule="evenodd">
                  <path
                    d="M3.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L9.293 8L3.646 2.354a.5.5 0 0 1 0-.708z"
                  />
                  <path
                    d="M7.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L13.293 8L7.646 2.354a.5.5 0 0 1 0-.708z"
                  />
                </g>
              </svg>
            </button>
          </div>
        </slot>
      </div>
    </div>
  </div>
</template>

<style>
.left-menu-container {
  position: relative;
  flex-shrink: 0 !important;
}

.menu-resize-controls {
  position: absolute;
  right: 0;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
  background: #f0f0f0;
  border-radius: 3px 0 0 3px;
  box-shadow: -2px 0 5px rgba(0, 0, 0, 0.1);
}

.menu-resize-controls button {
  width: 16px;
  height: 40px;
  display: flex;
  justify-content: center;
  align-items: center;
  border: none;
  background: transparent;
  cursor: pointer;
  user-select: none;
}

.bh-datatable thead {
  z-index: 15 !important;
}

.bh-datatable tbody tr {
  position: relative;
  z-index: 1;
}

.bh-datatable tbody tr:has(td[colspan]) {
  z-index: 0;
}
/* Clear All Filters Button */
.bh-clear-all-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  padding: 0;
  border: 1px solid #e0e6ed;
  border-radius: 4px;
  background: #e0e6ed;
  color: rgba(0, 0, 0, 0.4);
  cursor: not-allowed;
  transition: all 0.2s ease;
}

.bh-clear-all-button:disabled {
  opacity: 0.5;
}

.bh-clear-all-button--active {
  background: rgba(var(--primary-rgb, 59, 130, 246), 0.1);
  border-color: var(--primary, #3b82f6);
  color: var(--primary, #3b82f6);
  cursor: pointer;
}

.bh-clear-all-button--active:hover {
  background: rgba(var(--primary-rgb, 59, 130, 246), 0.2);
}

/* Dark mode */
.dark .bh-clear-all-button {
  background: #374151;
  border-color: #4b5563;
  color: rgba(255, 255, 255, 0.4);
}

.dark .bh-clear-all-button--active {
  background: rgba(var(--primary-rgb, 59, 130, 246), 0.2);
  border-color: var(--primary, #3b82f6);
  color: var(--primary, #3b82f6);
}

/* Tooltip styles */
.has-tooltip {
  position: relative;
}

.has-tooltip::before,
.has-tooltip::after {
  visibility: hidden;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s ease, visibility 0.2s ease;
  z-index: 9999;
}

.has-tooltip::before {
  content: attr(data-tooltip);
  position: absolute;
  bottom: calc(100% + 6px);
  left: 50%;
  transform: translateX(-50%);
  padding: 4px 8px;
  background: #1f2937;
  color: #fff;
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.has-tooltip::after {
  content: '';
  position: absolute;
  bottom: calc(100% + 2px);
  left: 50%;
  transform: translateX(-50%);
  border: 4px solid transparent;
  border-top-color: #1f2937;
}

.has-tooltip:hover::before,
.has-tooltip:hover::after {
  visibility: visible;
  opacity: 1;
}
</style>
