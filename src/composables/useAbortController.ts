import { onUnmounted, ref } from 'vue'

/**
 * Composable for managing AbortController
 * Automatically aborts pending requests on unmount
 */
export function useAbortController() {
    const controller = ref<AbortController | null>(null)

    const abort = () => {
        if (controller.value) {
            controller.value.abort()
            controller.value = null
        }
    }

    const getSignal = () => {
        abort() // Cancel previous request
        controller.value = new AbortController()
        return controller.value.signal
    }

    // Auto cleanup on unmount
    onUnmounted(() => {
        abort()
    })

    return {
        getSignal,
        abort
    }
}
