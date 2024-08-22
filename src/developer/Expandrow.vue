<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'

import '../../dist/style.css'
import DevSubTableExample from './devcomponent/dev-sub-table-example.vue'
import Vue3Datatable from '../components/custom-table.vue'
import type { ColumnDefinition } from '../model/column-model'

onMounted(() => {
  getUsers()
})

const datatable: any = ref(null)
const loading: any = ref(true)
const total_rows = ref(0)
const rows: any = ref(null)
const footer_rows = ref<any>(null)
const cols =
  ref<ColumnDefinition[]>([
    { field: 'id', title: 'ID', isUnique: true, filter: false },
    { field: 'firstName', title: 'First Name' },
    { field: 'lastName', title: 'Last Name' },
    { field: 'email', title: 'Email' },
    { field: 'age', title: 'Age', type: 'number' },
    { field: 'dob', title: 'Birthdate', type: 'date' },
    { field: 'address.city', title: 'City' },
    { field: 'isActive', title: 'Active', type: 'bool' }
  ]) || []

const changeServer = (data: any) => {
  params.current_page = data.current_page
  params.pagesize = data.pagesize
  params.sort_column = data.sort_column
  params.sort_direction = data.sort_direction
  params.column_filters = data.column_filters
  params.search = data.search

  filterUsers()
}

const params = reactive({
  current_page: 1,
  pagesize: 10,
  sort_column: 'id',
  sort_direction: 'desc',
  column_filters: [],
  search: ''
})

let controller: any
let timer: any
const filterUsers = () => {
  clearTimeout(timer)
  timer = setTimeout(() => {
    getUsers()
  }, 150)
}
const getUsers = async () => {
  // cancel request if previous request still pending before next request fire
  if (controller) {
    controller.abort()
  }
  controller = new AbortController()
  const signal = controller.signal

  try {
    loading.value = true

    const response = await fetch(
      'https://172.16.40.25:5001/datatable/api/user',
      {
        method: 'POST',
        headers: new Headers({ 'content-type': 'application/json' }),
        body: JSON.stringify(params),
        signal: signal // Assign the signal to the fetch request
      }
    )

    const data = await response.json()

    rows.value = data?.data
    total_rows.value = data?.meta?.total
  } catch {}

  loading.value = false
}

footer_rows.value = [
  {
    id: 1244,
    cells: [
      { field: 'id', text: '1.232 Adet' },
      { field: 'age', text: '1.232 Adet' },
      { field: 'address.city', text: '1.232 Adet' }
    ]
  }
]
</script>
<template>
  <div class="bh-p-10">
    <div class="bh-mb-2">
      <input
        type="text"
        v-model="params.search"
        placeholder="Search..."
        class="bh-border bh-border-solid bh-bg-white bh-p-2 bh-outline-0 bh-border-gray-200 focus:bh-border-gray-200 bh-rounded"
      />
      <button type="button" class="btn mb-4 bh-p-2" @click="datatable.reset()">
        Reset
      </button>
      <br />
    </div>
    <vue3-datatable
      ref="datatable"
      :loading="false"
      :rows="rows"
      :footerRows="footer_rows"
      :columns="cols"
      :totalRows="total_rows"
      :isServerMode="true"
      :page="params.current_page"
      :pageSize="params.pagesize"
      :pageSizeOptions="[1, 3, 5, 10, 100]"
      :sortable="true"
      :sortColumn="params.sort_column"
      :sortDirection="params.sort_direction"
      :search="params.search"
      :hasCheckbox="true"
      :hasSubtable="true"
      :expandall="true"
      :columnFilter="true"
      :stickyHeader="true"
      :stickyFooter="true"
      :enableleftmenu="true"
      :leftmenusize="100"
      :leftmenumax="50"
      :leftmenumaxpx="250"
      :leftmenumin="100"
      :enabletopmenu="true"
      :topmenusize="1"
      :topmenumax="30"
      :topmenumin="20"
      :skeletonloader="false"
      :height="'800px'"
      :scrollbarstyle="$style.customCls"
      :enablefooterpagination="true"
      :footerOffset="20"
      :tableRightOffset="0"
      :enableloadinganimation="false"
      skin="bh-table-striped bh-table-hover bh-table-bordered"
      @change="changeServer"
    >
      <template #email="data">
        <a
          :href="`mailto:${data.value.email}`"
          class="text-primary hover:underline"
          >{{ data.value.email }}</a
        >
      </template>
      <template #tsub="rowdata">
        <DevSubTableExample :rowdata="rowdata"></DevSubTableExample>
      </template>
      <template
        #footerpageinfo="{
          paginationInfo,
          filterRowCount,
          offset,
          limit,
          showPageSize,
          pageSizeOptions,
          currentPageSize,
          stringFormat,
          setPageSize
        }"
      >
        <div class="bh-pagination-info bh-flex bh-items-center">
          <span class="bh-mr-2">
            {{
              stringFormat(
                paginationInfo,
                filterRowCount ? offset : 0,
                limit,
                filterRowCount
              )
            }}
          </span>
          <select
            v-if="showPageSize"
            @change="setPageSize($event.target.value)"
            class="bh-pagesize"
          >
            <option
              v-for="option in pageSizeOptions"
              :value="option"
              :selected="currentPageSize == option ? true : false"
              :key="option"
            >
              {{ option }}
            </option>
          </select>
        </div>
      </template>
      <template
        #footerpagination="{
          currentPage,
          maxPage,
          paging,
          movePage,
          nextPage,
          previousPage
        }"
      >
        <div
          class="bh-pagination-number sm:bh-ml-auto bh-inline-flex bh-items-center bh-space-x-1"
        >
          <button
            type="button"
            class="bh-page-item first-page"
            :class="{ disabled: currentPage <= 1 }"
            @click="movePage(1)"
          >
            <svg aria-hidden="true" width="14" height="14" viewBox="0 0 16 16">
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
            <svg aria-hidden="true" width="14" height="14" viewBox="0 0 16 16">
              <path
                fill="currentColor"
                fill-rule="evenodd"
                d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"
              />
            </svg>
          </button>

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

          <button
            type="button"
            class="bh-page-item next-page"
            :class="{ disabled: currentPage >= maxPage }"
            @click="nextPage"
          >
            <svg aria-hidden="true" width="14" height="14" viewBox="0 0 16 16">
              <path
                fill="currentColor"
                fill-rule="evenodd"
                d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8L4.646 2.354a.5.5 0 0 1 0-.708z"
              />
            </svg>
          </button>

          <button
            type="button"
            class="bh-page-item last-page"
            :class="{ disabled: currentPage >= maxPage }"
            @click="movePage(maxPage)"
          >
            <svg aria-hidden="true" width="14" height="14" viewBox="0 0 16 16">
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
      </template>
    </vue3-datatable>
  </div>
</template>
<style lang="scss" module>
.customCls {
  :global {
    .scrollbar__thumbPlaceholder--horizontal {
      height: 13px;
    }
    .scrollbar__thumbPlaceholder--autoExpand:hover > .scrollbar__thumb {
      border-radius: var(--radius);
    }
    .scrollbar__thumbPlaceholder--vertical {
      margin-right: 0px;
      z-index: 10;
      margin-top: -3px;
      width: 13px;
    }
    .scrollbar__thumbPlaceholder--horizontal {
      margin-bottom: -13px;
      margin-left: -3px;
      width: 13px;
    }
    .scrollbar__thumb.scrollbar__thumb--vertical {
      border-radius: var(--radius);
    }
    .scrollbar__thumb.scrollbar__thumb--horizontal {
      border-radius: var(--radius);
      margin-bottom: 4px;
    }
  }
}
</style>
