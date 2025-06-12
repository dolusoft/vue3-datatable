<script lang="ts">
export default {
    name: 'buttonExpand'
}
</script>
<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { ref, toRef, watch } from 'vue'

import { type ExpandedRow } from '../model/helper'

interface Props {
    item?: any
    expandedrows?: ExpandedRow[]
    expandall?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    item: [],
    expandedrows: () => [],
    expandall: false
})

const expandedrows = toRef(props, 'expandedrows')

const _expandallStatus = ref<boolean>(false)

function expandRow(id: number) {
    console.log('🔍 expandRow çağrıldı:', { id, expandall: props.expandall })
    
    if (props.expandall) {
        console.log('📋 expandall=true - tümünü değiştir')
        _expandallStatus.value = !_expandallStatus.value
        expandedrows.value.forEach(element => {
            element.isExpanded = _expandallStatus.value
        })
        console.log('📋 tüm satırlar:', expandedrows.value)
    } else {
        console.log('🎯 expandall=false - sadece tek satır')
        const found = expandedrows.value.find(x => x.id == id)
        if (found) {
            console.log('✏️ mevcut satır güncellendi:', found)
            found.isExpanded = !found.isExpanded
        } else {
            console.log('➕ yeni satır eklendi:', id)
            expandedrows.value.push({ id: id, isExpanded: true })
        }
        console.log('🎯 güncel expandedrows:', expandedrows.value)
    }
}

// ID'yi item'dan al - önce _rowIndex sonra id
const getItemId = (item: any) => {
    return item._rowIndex !== undefined ? item._rowIndex : (item.id || 0)
}

const _mixedRows = ref(-1)

watch(() => expandedrows.value, () => {
    console.log('👀 watcher tetiklendi:', { expandall: props.expandall, expandedrows: expandedrows.value })
    
    if (!props.expandall) {
        console.log('⚠️ expandall=false, watcher işlem yapmıyor')
        return
    }

    console.log('📈 expandall=true, global state yönetimi')
    // Sadece expandall modunda global state yönet
    if (new Set(expandedrows.value.map(x => x.isExpanded)).size > 1) {
        _mixedRows.value = -1
        _expandallStatus.value = true
        console.log('🔄 karışık durum: mixedRows=-1')
    } else {
        if (expandedrows.value.at(0)?.isExpanded) {
            _mixedRows.value = 0
            _expandallStatus.value = true
            console.log('✅ hepsi açık: mixedRows=0')
        } else {
            _mixedRows.value = 1
            _expandallStatus.value = false
            console.log('❌ hepsi kapalı: mixedRows=1')
        }
    }
}, { deep: true })

</script>
<template>
    <button class="expandbtn" @click="expandRow(getItemId(item))">
        <template v-if="expandedrows.find(x => x.id == getItemId(item))?.isExpanded === true">
            <template v-if="props.expandall">
                <template v-if="_mixedRows">
                    <!-- <Icon icon="ion:chevron-expand" /> -->
                    <Icon icon="fluent:chevron-down-up-16-filled" />
                </template>
                <template v-else>
                    <Icon icon="mdi:chevron-down" />
                </template>
            </template>
            <template v-else>
                <Icon icon="mdi:chevron-down" />
            </template>
        </template>
        <template v-else>
            <template v-if="props.expandall">
                <template v-if="_mixedRows == -1">
                    <Icon icon="ion:chevron-expand" />
                </template>
                <template v-else-if="_mixedRows == 0">
                    <Icon icon="mdi:chevron-down" />
                </template>
                <template v-else>
                    <Icon icon="mdi:chevron-right" />
                </template>
            </template>
            <template v-else>
                <Icon icon="mdi:chevron-right" />
            </template>
        </template>
    </button>
</template>
<style scoped>
.expandbtn {
    cursor: pointer;
}
</style>
