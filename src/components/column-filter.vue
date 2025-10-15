<template>
  <div
    ref="menuRef"
    class="bh-filter-menu bh-absolute bh-z-[1] bh-bg-white dark:bh-bg-gray-800 bh-shadow-md bh-rounded-md bh-top-full bh-right-0 bh-w-32 bh-mt-1 bh-border bh-border-solid bh-border-gray-200 dark:bh-border-gray-600"
  >
    <div
      class="bh-text-[13px] bh-font-normal bh-rounded bh-overflow-hidden"
    >
      <button
        type="button"
        :class="{ active: props.column.condition === '' }"
        @click.stop="select('')"
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
          @click.stop="select('Contains')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Contains']) ??
            'Contains'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotContains' }"
          @click.stop="select('NotContains')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotContains']) ??
            'NotContains'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'Equal' }"
          @click.stop="select('Equal')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Equal']) ??
            'Equal (=)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotEqual' }"
          @click.stop="select('NotEqual')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotEqual']) ??
            'NotEqual (!=)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'StartsWith' }"
          @click.stop="select('StartsWith')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['StartsWith']) ??
            'StartsWith'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'EndsWith' }"
          @click.stop="select('EndsWith')"
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
          @click.stop="select('Equal')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Equal']) ??
            'Equal (=)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotEqual' }"
          @click.stop="select('NotEqual')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotEqual']) ??
            'NotEqual (!=)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'GreaterThan' }"
          @click.stop="select('GreaterThan')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['GreaterThan']) ??
            'GreaterThan (>)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'GreaterThanOrEqual' }"
          @click.stop="select('GreaterThanOrEqual')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['GreaterThanOrEqual']) ??
            'GreaterThanOrEqual (>=)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'LessThan' }"
          @click.stop="select('LessThan')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['LessThan']) ??
            'LessThan (<)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'LessThanOrEqual' }"
          @click.stop="select('LessThanOrEqual')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['LessThanOrEqual']) ??
            'LessThanOrEqual (<=)'
          }}
        </button>
      </template>
      <template v-else-if="props.column.type === 'date'">
        <button
          type="button"
          :class="{ active: props.column.condition === 'Equal' }"
          @click.stop="select('Equal')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['Equal']) ??
            'Equal (=)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'NotEqual' }"
          @click.stop="select('NotEqual')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['NotEqual']) ??
            'Not equal (!=)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'GreaterThan' }"
          @click.stop="select('GreaterThan')"
        >
          {{
            (props.columnFilterLang &&
              props.columnFilterLang['GreaterThan']) ??
            'GreaterThan (>)'
          }}
        </button>
        <button
          type="button"
          :class="{ active: props.column.condition === 'LessThan' }"
          @click.stop="select('LessThan')"
        >
          {{
            (props.columnFilterLang && props.columnFilterLang['LessThan']) ??
            'LessThan (<)'
          }}
        </button>
      </template>

      <button
        type="button"
        :class="{ active: props.column.condition === 'IsNull' }"
        @click.stop="select('IsNull')"
      >
        {{
          (props.columnFilterLang && props.columnFilterLang['IsNull']) ??
          'IsNull'
        }}
      </button>
      <button
        type="button"
        :class="{ active: props.column.condition === 'IsNotNull' }"
        @click.stop="select('IsNotNull')"
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
import { ref } from 'vue'
import { onClickOutside } from '@vueuse/core'

const props = defineProps(['column', 'columnFilterLang'])
const emit = defineEmits(['close', 'filterChange'])

const menuRef = ref(null)

// Close menu when clicking outside
onClickOutside(menuRef, () => {
  emit('close')
})

const select = (condition: any) => {
  props.column.condition = condition
  if (condition === '') {
    props.column.value = ''
  }

  emit('filterChange', props.column)
  emit('close')
}
</script>
