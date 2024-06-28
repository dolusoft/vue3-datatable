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
  filter?: boolean // column filter
  search?: boolean // global search
  sort?: boolean
  html?: boolean
  cellRenderer?: [Function, string]
  headerClass?: string
  cellClass?: string
}
