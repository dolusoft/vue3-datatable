export interface ColumnDefinition {
  isUnique?: boolean
  field?: string
  title?: string
  value?: any
  condition?: any
  type?: string // string|date|number|bool
  width?: string | undefined
  minWidth?: string | undefined
  maxWidth?: string | undefined
  hide?: boolean
  dataOnly?: boolean // hide from UI but include in data/query
  filter?: boolean // column filter
  search?: boolean // global search
  sort?: boolean
  html?: boolean
  cellRenderer?: [Function, string]
  headerClass?: string
  cellClass?: string
  // Truncate options
  truncate?: boolean // Enable text truncation with ellipsis (default: true)
  truncateLines?: number // Number of lines to show before truncating (default: 1)
  showTooltip?: boolean // Show tooltip on hover for truncated content (default: true)
}

export interface FilterCondition {
  value: string
  label: string
  icon?: string
}
