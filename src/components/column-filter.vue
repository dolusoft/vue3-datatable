<template>
  <div
    class="bh-filter-menu bh-absolute bh-z-[1] bh-bg-white bh-shadow-md bh-rounded-md bh-top-full bh-right-0 bh-w-32 bh-mt-1"
  >
    <div
      class="bh-text-[13px] bh-font-normal bh-rounded bh-overflow-hidden"
      @click.stop="close"
    >
      <button
        type="button"
        :class="{ active: props.column.condition === '' }"
        @click="select('')"
      >
        {{
          (props.columnFilterLang && props.columnFilterLang['NoFilter']) ??
          'No filter'
        }}
      </button>
      <template v-if="props.column.type === 'string'">
        <button
          type="button"
          :class="{ active: props.column.condition === 'Contains' }"
          @click="select('Contains')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Contains']) ??
            'Contains'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotContains' }"
          @click="select('NotContains')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotContains']) ??
            'NotContains'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'Equal' }"
          @click="select('Equal')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Equal']) ??
            'Equal'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotEqual' }"
          @click="select('NotEqual')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotEqual']) ??
            'NotEqual'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'StartsWith' }"
          @click="select('StartsWith')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['StartsWith']) ??
            'StartsWith'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'EndsWith' }"
          @click="select('EndsWith')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['EndsWith']) ??
            'EndsWith'
          }}
        </button>
      </template>
      <template v-else-if="props.column.type === 'number'">
        <button
          type="button"
          :class="{ active: props.column.condition === 'Equal' }"
          @click="select('Equal')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Equal']) ??
            'Equal'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotEqual' }"
          @click="select('NotEqual')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotEqual']) ??
            'NotEqual'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'GreaterThan' }"
          @click="select('GreaterThan')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['GreaterThan']) ??
            'GreaterThan'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'GreaterThanOrEqual' }"
          @click="select('GreaterThanOrEqual')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['GreaterThanOrEqual']) ??
            'GreaterThanOrEqual'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'LessThan' }"
          @click="select('LessThan')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['LessThan']) ??
            'LessThan'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'LessThanOrEqual' }"
          @click="select('LessThanOrEqual')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['LessThanOrEqual']) ??
            'LessThanOrEqual'
          }}
        </button>
      </template>
      <template v-else-if="props.column.type === 'date'">
        <button
          type="button"
          :class="{ active: props.column.condition === 'Equal' }"
          @click="select('Equal')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Equal']) ??
            'Equal'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotEqual' }"
          @click="select('NotEqual')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotEqual']) ??
            'Not equal'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'GreaterThan' }"
          @click="select('GreaterThan')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['GreaterThan']) ??
            'GreaterThan'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'LessThan' }"
          @click="select('LessThan')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['LessThan']) ??
            'LessThan'
          }}
        </button>
      </template>

      <button
        type="button"
        :class="{ active: props.column.condition === 'IsNull' }"
        @click="select('IsNull')"
      >
        {{
          (props.columnFilterLang && props.columnFilterLang['IsNull']) ??
          'IsNull'
        }}
      </button>
      <button
        type="button"
        :class="{ active: props.column.condition === 'IsNotNull' }"
        @click="select('IsNotNull')"
      >
        {{
          (props.columnFilterLang && props.columnFilterLang['IsNotNull']) ??
          'IsNotNull'
        }}
      </button>
    </div>
  </div>
</template>
<script lang="ts">
export default {
  name: 'columnFilter'
}
</script>
<script setup lang="ts">
import { onBeforeUnmount, onMounted } from 'vue'

const props = defineProps(['column', 'columnFilterLang'])

onBeforeUnmount(() => {
  document.removeEventListener('click', close)
})
onMounted(() => {
  document.addEventListener('click', close)
})
const emit = defineEmits(['close', 'filterChange'])

const close = () => {
  emit('close')
}

const select = (condition: any) => {
  props.column.condition = condition
  if (condition === '') {
    props.column.value = ''
  }

  emit('filterChange', props.column)
}
</script>
