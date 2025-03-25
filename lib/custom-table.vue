<script setup lang="ts">
import MyTable from "../src/components/custom-table.vue";

const props = defineProps({
  loading: Boolean,
  isServerMode: Boolean,
  skin: String,
  totalRows: Number,
  rows: Array,
  footerRows: Array,
  columns: Array,
  hasCheckbox: Boolean,
  hasSubtable: Boolean,
  hasRightPanel: Boolean,
  expandall: Boolean,
  search: String,
  columnChooser: Boolean,
  page: Number,
  pageSize: Number,
  pageSizeOptions: Array,
  showPageSize: Boolean,
  rowClass: [Array, Function],
  cellClass: [Array, Function],
  sortable: Boolean,
  sortColumn: String,
  sortDirection: String,
  columnFilter: Boolean,
  columnFilterLang: Object,
  pagination: Boolean,
  showNumbers: Boolean,
  showNumbersCount: Number,
  showFirstPage: Boolean,
  showLastPage: Boolean,
  firstArrow: String,
  lastArrow: String,
  nextArrow: String,
  previousArrow: String,
  paginationInfo: String,
  noDataContent: String,
  stickyHeader: Boolean,
  stickyFooter: Boolean,
  height: String,
  stickyFirstColumn: Boolean,
  cloneHeaderInFooter: Boolean,
  selectRowOnClick: Boolean,
  scrollbarstyle: [Array, Object, String],
  scrollbarautohide: Boolean,
  scrollbarfixedthumb: Boolean,
  scrollbarautoexpand: Boolean,
  scrollbardirection: String,
  enableleftmenu: Boolean,
  enabletopmenu: Boolean,
  leftmenusize: Number,
  leftmenumax: Number,
  leftmenumin: Number,
  leftmenumaxpx: Number,
  topmenusize: Number,
  topmenumax: Number,
  topmenumin: Number,
  skeletonloader: Boolean,
  enableloadinganimation: Boolean,
  enablefooterpagination: Boolean,
  footerOffset: Number,
  tableRightOffset: Number
});

const emits = defineEmits([
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
  'rowRightPanelClick'
]);
</script>

<template>
  <MyTable
    v-bind="props"
    @change="(e) => emits('change', e)"
    @sortChange="(e) => emits('sortChange', e)"
    @searchChange="(e) => emits('searchChange', e)"
    @pageChange="(e) => emits('pageChange', e)"
    @pageSizeChange="(e) => emits('pageSizeChange', e)"
    @rowSelect="(e) => emits('rowSelect', e)"
    @filterChange="(e) => emits('filterChange', e)"
    @rowClick="(e) => emits('rowClick', e)"
    @rowDBClick="(e) => emits('rowDBClick', e)"
    @currentTopMenuSize="(e) => emits('currentTopMenuSize', e)"
    @currentLeftMenuSize="(e) => emits('currentLeftMenuSize', e)"
    @rowRightPanelClick="(e) => emits('rowRightPanelClick', e)"
  >
    <template v-for="(_, name) in $slots" :key="name" #[name]="slotData">
      <slot :name="name" v-bind="slotData || {}" />
    </template>
  </MyTable>
</template>
