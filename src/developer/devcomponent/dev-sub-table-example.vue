<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'

import '../../../dist/style.css'
import Vue3Datatable from '../../components/custom-table.vue'
import type { ColumnDefinition } from '../../model/column-model'

onMounted(() => {
  getUsers()
})

const props = defineProps<{
  rowdata?: any
}>()

console.log(props.rowdata)

const datatable: any = ref(null)
const loading: any = ref(true)
const total_rows = ref(0)
const rows: any = ref(null)
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
  pagesize: 5,
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
  }, 1)
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
</script>
<template>
  <vue3-datatable
    ref="datatable"
    :loading="loading"
    :rows="rows"
    :columns="cols"
    :totalRows="total_rows"
    :isServerMode="true"
    :page="params.current_page"
    :pageSize="params.pagesize"
    :pageSizeOptions="[1, 3, 5, 10]"
    :sortable="false"
    :sortColumn="params.sort_column"
    :sortDirection="params.sort_direction"
    :search="params.search"
    :hasCheckbox="false"
    :hasSubtable="false"
    :expandall="false"
    :columnFilter="false"
    @change="changeServer"
  >
  </vue3-datatable>
</template>
