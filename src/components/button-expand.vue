<script lang="ts">
export default {
    name: 'buttonExpand',
};
</script>
<script setup lang="ts">
import { ExpandedRow } from '../model/helper';
import { Icon } from '@iconify/vue';
import { ref, toRef, watch } from 'vue';

interface Props {
    item?: any;
    expandedrows?: ExpandedRow[];
    expandall?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
    item: [],
    expandedrows: () => [],
    expandall: false,
});

const expandedrows = toRef(props, 'expandedrows');

const _expandallStatus = ref<boolean>(false);

function expandRow(id: number) {
    console.log(expandedrows.value);
    if (props.expandall) {
        _expandallStatus.value = !_expandallStatus.value;
        expandedrows.value.forEach((element) => {
            element.isExpanded = _expandallStatus.value;
        });
    } else {
        const found = expandedrows.value.find((x) => x.id == id);
        if (found) {
            found.isExpanded = !found.isExpanded;
        } else {
            expandedrows.value.push({ id: id, isExpanded: true });
        }
    }
}

const _mixedRows = ref(-1);

watch(
    () => expandedrows.value,
    (newValue, oldValue) => {
        // Note: `newValue` will be equal to `oldValue` here
        // *unless* state.someObject has been replaced

        if (new Set(expandedrows.value.map((x) => x.isExpanded)).size > 1) {
            _mixedRows.value = -1;
            _expandallStatus.value = true;
        } else {
            if (expandedrows.value.at(0)?.isExpanded) {
                _mixedRows.value = 0;
                _expandallStatus.value = true;
            } else {
                _mixedRows.value = 1;
                _expandallStatus.value = false;
            }
        }
    },
    { deep: true }
);
</script>
<template>
    <button class="expandbtn" @click="expandRow(item.id)">
        <template v-if="expandedrows.find((x) => x.id == item.id)?.isExpanded == undefined ? _expandallStatus : expandedrows.find((x) => x.id == item.id)?.isExpanded">
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
