import { ref } from 'vue'
import { useAbortController } from './useAbortController'

/**
 * Composable for making fetch requests with automatic cancellation
 * Includes loading state and debounced requests
 */
export function useFetch<T = any>(baseUrl?: string) {
    const loading = ref(false)
    const error = ref<Error | null>(null)
    const data = ref<T | null>(null)
    const { getSignal } = useAbortController()

    let timeoutId: ReturnType<typeof setTimeout> | null = null

    const request = async (
        url: string,
        options?: RequestInit,
        debounce = 0
    ): Promise<T | null> => {
        // Clear previous timeout
        if (timeoutId) {
            clearTimeout(timeoutId)
        }

        return new Promise((resolve) => {
            const execute = async () => {
                try {
                    loading.value = true
                    error.value = null

                    const signal = getSignal()
                    const fullUrl = baseUrl ? `${baseUrl}${url}` : url

                    const response = await fetch(fullUrl, {
                        ...options,
                        signal
                    })

                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`)
                    }

                    const result = await response.json()
                    data.value = result
                    resolve(result)
                    return result
                } catch (err: any) {
                    if (err.name === 'AbortError') {
                        // Request was cancelled, don't update error state
                        resolve(null)
                        return null
                    }
                    error.value = err
                    resolve(null)
                    return null
                } finally {
                    loading.value = false
                }
            }

            if (debounce > 0) {
                timeoutId = setTimeout(execute, debounce)
            } else {
                execute()
            }
        })
    }

    const post = (url: string, body: any, debounce = 0) => {
        return request(
            url,
            {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            },
            debounce
        )
    }

    const get = (url: string, debounce = 0) => {
        return request(url, { method: 'GET' }, debounce)
    }

    return {
        loading,
        error,
        data,
        request,
        post,
        get
    }
}
