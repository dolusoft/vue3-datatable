<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'

import '../../dist/style.css'
import Vue3Datatable from '../components/custom-table.vue'
import type { ColumnDefinition } from '../model/column-model'

onMounted(() => {
  getUsers()
})

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
      'http://localhost:8080/datatable/api/user',
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

function resetFunc() {
  datatable.value.reset()
}

// Header alanı için örnek veri
const headerStats = ref({
  totalUsers: 1250,
  activeUsers: 984,
  inactiveUsers: 266,
  averageAge: 32.5,
  lastUpdated: new Date().toLocaleString()
})

// Header yüksekliği
const headerHeight = ref('120px')
</script>
<template>
  <div class="bh-p-10">
    <h2 class="bh-text-2xl bh-font-bold bh-mb-4">Table Header Area Test</h2>
    
    <vue3-datatable
      ref="datatable"
      :loading="loading"
      :rows="rows"
      :columns="cols"
      :totalRows="total_rows"
      :isServerMode="true"
      :page="params.current_page"
      :pageSize="params.pagesize"
      :pageSizeOptions="[5, 10, 20, 50]"
      :sortable="true"
      :sortColumn="params.sort_column"
      :sortDirection="params.sort_direction"
      :search="params.search"
      :hasCheckbox="true"
      :columnFilter="true"
      :stickyHeader="true"
      :height="'800px'"
      :enableHeaderArea="true"
      :headerAreaHeight="headerHeight"
      skin="bh-table-striped bh-table-hover bh-table-bordered"
      @change="changeServer"
    >
      <!-- Header Area Slot -->
      <template #tableHeaderArea>
        <div class="bh-bg-blue-50 bh-p-4 bh-rounded-lg bh-shadow bh-h-full bh-w-full">
          <div class="bh-flex bh-flex-wrap bh-justify-between bh-items-center">
            <div class="bh-flex bh-flex-col">
              <h3 class="bh-text-xl bh-font-semibold bh-text-gray-800">Kullanıcı İstatistikleri</h3>
              <p class="bh-text-sm bh-text-gray-600">Son güncelleme: {{ headerStats.lastUpdated }}</p>
            </div>
            
            <div class="bh-flex bh-gap-4 bh-mt-2 sm:bh-mt-0">
              <div class="bh-bg-white bh-p-3 bh-rounded bh-shadow-sm bh-border bh-border-gray-200">
                <div class="bh-font-semibold bh-text-gray-700">Toplam</div>
                <div class="bh-text-2xl bh-font-bold bh-text-blue-600">{{ headerStats.totalUsers }}</div>
              </div>
              
              <div class="bh-bg-white bh-p-3 bh-rounded bh-shadow-sm bh-border bh-border-gray-200">
                <div class="bh-font-semibold bh-text-gray-700">Aktif</div>
                <div class="bh-text-2xl bh-font-bold bh-text-green-600">{{ headerStats.activeUsers }}</div>
              </div>
              
              <div class="bh-bg-white bh-p-3 bh-rounded bh-shadow-sm bh-border bh-border-gray-200">
                <div class="bh-font-semibold bh-text-gray-700">Pasif</div>
                <div class="bh-text-2xl bh-font-bold bh-text-red-600">{{ headerStats.inactiveUsers }}</div>
              </div>
              
              <div class="bh-bg-white bh-p-3 bh-rounded bh-shadow-sm bh-border bh-border-gray-200">
                <div class="bh-font-semibold bh-text-gray-700">Ortalama Yaş</div>
                <div class="bh-text-2xl bh-font-bold bh-text-purple-600">{{ headerStats.averageAge }}</div>
              </div>
            </div>
          </div>
          
          <div class="bh-mt-2 bh-flex bh-justify-end">
            <select v-model="headerHeight" class="bh-bg-white bh-border bh-border-gray-300 bh-rounded bh-px-2 bh-py-1 bh-text-sm">
              <option value="80px">Küçük (80px)</option>
              <option value="120px">Orta (120px)</option>
              <option value="180px">Büyük (180px)</option>
            </select>
          </div>
        </div>
      </template>
      
      <!-- Table Action Header Slot -->
      <template #tableactionheader>
        <div class="bh-flex bh-items-center bh-justify-between bh-mb-4">
          <div class="bh-flex bh-space-x-2">
            <input
              type="text"
              v-model="params.search"
              placeholder="Ara..."
              class="bh-border bh-border-solid bh-bg-white bh-p-2 bh-outline-0 bh-border-gray-200 focus:bh-border-gray-200 bh-rounded"
            />
            <button 
              type="button" 
              class="bh-bg-blue-600 bh-text-white bh-px-4 bh-py-2 bh-rounded hover:bh-bg-blue-700" 
              @click="resetFunc()"
            >
              Sıfırla
            </button>
          </div>
          
          <div>
            <button class="bh-bg-green-600 bh-text-white bh-px-4 bh-py-2 bh-rounded hover:bh-bg-green-700">
              Yeni Kullanıcı
            </button>
          </div>
        </div>
      </template>
    </vue3-datatable>
  </div>
</template>
