import type { Directive, DirectiveBinding } from 'vue'

const tooltipDirective: Directive = {
  mounted(el: HTMLElement, binding: DirectiveBinding) {
    const text = binding.value || ''
    if (!text) return

    el.setAttribute('data-tooltip', text)
    el.classList.add('has-tooltip')
  },
  updated(el: HTMLElement, binding: DirectiveBinding) {
    const text = binding.value || ''
    if (text) {
      el.setAttribute('data-tooltip', text)
      el.classList.add('has-tooltip')
    } else {
      el.removeAttribute('data-tooltip')
      el.classList.remove('has-tooltip')
    }
  },
  unmounted(el: HTMLElement) {
    el.removeAttribute('data-tooltip')
    el.classList.remove('has-tooltip')
  }
}

export default tooltipDirective
