hx.userFacingText({
  dataTable: {
    addFilter: 'Add Filter',
    advancedSearch: 'Advanced Search',
    and: 'and',
    anyColumn: 'Any column'
    clearFilters: 'Clear Filters',
    clearSelection: 'clear selection',
    loading: 'Loading',
    noData: 'No Data',
    noSort: 'No Sort',
    or: 'or',
    rowsPerPage: 'Rows Per Page',
    search: 'Search',
    selectedRows: '$selected of $total selected.',
    sortBy: 'Sort By'
  }
})


fullWidthColSpan = 999 # the colspan used to make a cell display as an entire row
collapseBreakPoint = 480

columnOptionLookup = (options, name, id) ->
  if options.columns isnt undefined and options.columns[id] isnt undefined and options.columns[id][name] isnt undefined
    options.columns[id][name]
  else
    options[name]

splitArray = (array, index) ->
  left = if index is 0 then [] else array[0...index]
  right = if index is array.length - 1 then [] else array[index+1...array.length]
  [left, array[index], right]

# pagination block (the page selector and the rows per page selector)
createPaginationBlock = (table) ->
  container = hx.detached('div').class('hx-data-table-paginator')

  pickerNode = container.append('button').class('hx-data-table-paginator-picker hx-btn hx-btn-invisible').node()
  picker = new hx.Picker(pickerNode, { dropdownOptions: { align: 'rbrt' } })
    .on 'change', 'hx.data-table', (d) =>
      if d.cause is 'user'
        table.page(d.value.value, undefined, d.cause)

  totalRows = container.append('span').class('hx-data-table-paginator-total-rows')

  back = container.append('button').class('hx-data-table-paginator-back hx-btn hx-btn-invisible')
  back.append('i').class('hx-icon hx-icon-chevron-left')
  back.on 'click', 'hx.data-table', => if not back.classed('hx-data-table-btn-disabled') then table.page(table.page()-1)

  forward = container.append('button').class('hx-data-table-paginator-forward hx-btn hx-btn-invisible')
  forward.append('i').class('hx-icon hx-icon-chevron-right')
  forward.on 'click', 'hx.data-table', => if not forward.classed('hx-data-table-btn-disabled') then table.page(table.page()+1)

  [container, picker]

# pageSizeOptions select
createPageSizeBlock= (table, options) ->
  container = hx.detached('div').class('hx-data-table-page-size')

  container.append('span').text(options.rowsPerPageText + ': ')

  node = container.append('button').class('hx-data-table-page-size-picker hx-btn hx-btn-invisible').node()
  picker = new hx.Picker(node, { dropdownOptions: { align: 'rbrt' } })
    .on 'change', 'hx.data-table', (d) ->
      if d.cause is 'user'
        table.pageSize(d.value.value, undefined, 'user')
        table.page(1, undefined, 'user')

  [container, picker]

spacer = -> hx.detached('div').class('hx-data-table-spacer')

createAdvancedSearchView = (selection, dataTable, options) ->
  # Render individual row
  advancedSearchRowEnter = (filterGroup, filterGroupIndex) ->
    (filterRow, index, trueIndex) ->
      typePickerOptions =
        items: [
          { text: hx.userFacingText('dataTable', 'and'), value: 'and' }
          { text: hx.userFacingText('dataTable', 'or'), value: 'or' }
        ]

      typePickerSel = hx.picker(typePickerOptions)
        .classed('hx-data-table-advanced-search-type hx-section hx-fixed', true)

      typePickerSel.component()
        .on 'change', (data) ->
          if data.cause is 'user'
            prevFilters = dataTable.advancedSearch()
            [leftFilterGroups, filterGroup, rightFilterGroups] = splitArray(prevFilters, filterGroupIndex)

            newFilters = if data.value.value is 'or'
              [leftFilters, filter, rightFilters] = splitArray(filterGroup, trueIndex)
              [leftFilterGroups..., leftFilters, [filter, rightFilters...], rightFilterGroups...]
            else
              [leftAllButLast..., leftLast] = leftFilterGroups
              [leftAllButLast..., [leftLast..., filterGroup...], rightFilterGroups...]

            dataTable.advancedSearch(newFilters)

      anyColumn = {
        text: options.anyColumnText
        value: 'any'
        anyColumn: true
      }

      columnItems = filterRow.headers.map (header) ->
        value: header.id
        orig: header

      columnRenderer = (element, cell) ->
        if cell.anyColumn then hx.select(element).text(cell.text)
        else columnOptionLookup(options, 'headerCellRenderer', cell.orig.id)(element, cell.orig, filterRow.headers)

      columnPickerOptions =
        items: [anyColumn, columnItems...]
        renderer: columnRenderer

      columnPickerSel = hx.picker(columnPickerOptions)
        .classed('hx-data-table-advanced-search-column hx-section hx-fixed', true)

      columnPickerSel.component()
        .on 'change', (data) ->
          if data.cause is 'user'
            prevFilters = dataTable.advancedSearch()
            [leftFilterGroups, filterGroup, rightFilterGroups] = splitArray(prevFilters, filterGroupIndex)
            [leftFilters, filter, rightFilters] = splitArray(filterGroup, trueIndex)
            newFilter = hx.merge(filter, {
              column: data.value.value
            })
            dataTable.advancedSearch([leftFilterGroups..., [leftFilters..., newFilter, rightFilters...], rightFilterGroups...])

      debouncedInput = hx.debounce 200, (e) ->
        prevFilters = dataTable.advancedSearch()
        [leftFilterGroups, filterGroup, rightFilterGroups] = splitArray(prevFilters, filterGroupIndex)
        [leftFilters, filter, rightFilters] = splitArray(filterGroup, trueIndex)
        newFilter = hx.merge(filter, {
          term: e.target.value
        })
        dataTable.advancedSearch([leftFilterGroups..., [leftFilters..., newFilter, rightFilters...], rightFilterGroups...])

      termInput = hx.detached('input').attr('placeholder', options.advancedSearchPlaceholder)
        .class('hx-data-table-advanced-search-input hx-section')
        .attr('required', 'required')
        .on 'input', debouncedInput

      removeBtn = hx.button({context: 'negative'}).classed('hx-data-table-advanced-search-remove hx-btn-invert', true)
        .add(hx.icon({class: 'hx-icon hx-icon-close'}))
        .on 'click', ->
          prevFilters = dataTable.advancedSearch()
          [leftFilterGroups, filterGroup, rightFilterGroups] = splitArray(prevFilters, filterGroupIndex)
          [leftFilters, _, rightFilters] = splitArray(filterGroup, trueIndex)

          newFilters = if trueIndex is 0 and filterGroupIndex is 0
            [rightFilters, rightFilterGroups...]
          else if trueIndex is 0
            [leftFilterGroup..., leftFilterGroupLast] = leftFilterGroups
            [_, filters...] = filterGroup
            [leftFilterGroup..., [leftFilterGroupLast..., filters...], rightFilterGroups...]
          else
            [leftFilterGroups..., [leftFilters..., rightFilters...], rightFilterGroups...]

          filterToUse = newFilters.filter((group) => group.length)

          dataTable.advancedSearch(if filterToUse.length then filterToUse else undefined)

      @append('div').class('hx-data-table-advanced-search-filter hx-section hx-input-group hx-input-group-full-width')
        .add(typePickerSel)
        .add(columnPickerSel)
        .add(termInput)
        .add(removeBtn)
        .node()

  advancedSearchRowUpdate = ({term, column}, element, index) ->
    filterRowSel = hx.select(element)

    validContext = if not term then 'negative' else undefined

    filterRowSel.select('.hx-data-table-advanced-search-type')
      .component().value(if index is 0 then 'or' else 'and')

    filterRowSel.select('.hx-data-table-advanced-search-column')
      .component().value(column or 'any')

    filterRowSel.select('.hx-data-table-advanced-search-input')
      .value(term or '')

  # Render grouped filters
  advancedSearchGroupEnter = (dataTable) ->
    (filterGroup, index, trueIndex) ->
      filterGroupSel = hx.detached('div').class('hx-data-table-advanced-search-filter-group')
      filterGroupView = filterGroupSel.view('.hx-data-table-advanced-search-filter')
          .enter(advancedSearchRowEnter(filterGroup, trueIndex, dataTable))
          .update(advancedSearchRowUpdate)

      hx.component.register(filterGroupSel.node(), {
        filterGroupView
      })
      @append(filterGroupSel).node()

  advancedSearchGroupUpdate = (filterGroup, element, index) ->
    hx.component(element).filterGroupView.apply(filterGroup)

  selection.view('.hx-data-table-advanced-search-filter-group')
    .enter(advancedSearchGroupEnter(this))
    .update(advancedSearchGroupUpdate)


class DataTable extends hx.EventEmitter
  constructor: (selector, options) ->
    super
    hx.component.register(selector, this)

    # XXX: review option names (particularly rowEnabledLookup and rowSelectableLookup) and decide on default values
    resolvedOptions = hx.merge({
      allowHeaderWrap: false
      compact: 'auto'             # 'auto', true, false
      displayMode: 'paginate'     # 'paginate', 'all'
      feed: undefined
      showSearchAboveTable: false
      filter: undefined
      filterEnabled: true
      showAdvancedSearch: false
      advancedSearchEnabled: false
      advancedSearch: undefined
      pageSize: 15
      pageSizeOptions: undefined  # supply an array of numbers to show the user
      retainHorizontalScrollOnRender: true
      retainVerticalScrollOnRender: false
      selectEnabled: false
      singleSelection: false
      sort: undefined
      sortEnabled: true

      # functions used for getting row state
      rowIDLookup: (row) -> row.id
      rowEnabledLookup: (row) -> not row.disabled
      rowSelectableLookup: (row) -> true
      rowCollapsibleLookup: (row) -> false

      # functions for rendering
      collapsibleRenderer: undefined
      cellRenderer: (element, cell, row) -> hx.select(element).text(cell)
      headerCellRenderer: (element, cell, headers) -> hx.select(element).text(cell.name)

      # per column options (headerCellRenderer, cellRenderer, sortEnabled)
      columns: {}

      clearSelectionText: hx.userFacingText('dataTable','clearSelection')
      loadingText: hx.userFacingText('dataTable','loading')
      noDataMessage: hx.userFacingText('dataTable','noData')
      noSortText: hx.userFacingText('dataTable', 'noSort')
      rowsPerPageText: hx.userFacingText('dataTable','rowsPerPage')
      searchPlaceholder: hx.userFacingText('dataTable','search')
      selectedRowsText: hx.userFacingText('dataTable', 'selectedRows')
      sortByText: hx.userFacingText('dataTable','sortBy')

      addFilterText: hx.userFacingText('dataTable', 'addFilter')
      clearFiltersText: hx.userFacingText('dataTable', 'clearFilters')
      anyColumnText: hx.userFacingText('dataTable', 'anyColumn')

      advancedSearchText: hx.userFacingText('dataTable','advancedSearch')
      advancedSearchPlaceholder: hx.userFacingText('dataTable', 'search')
      redrawOnResize: true
    }, options)

    resolvedOptions.pageSize = Math.min resolvedOptions.pageSize, 1000
    resolvedOptions.advancedSearchEnabled = true if resolvedOptions.advancedSearch
    resolvedOptions.showAdvancedSearch = true if resolvedOptions.advancedSearchEnabled

    selection = hx.select(selector).classed('hx-data-table', true)
    content = hx.detached('div').class('hx-data-table-content')

    # loading div
    loadingDiv = hx.detached('div').class('hx-data-table-loading')
      .add(hx.detached('div').class('hx-data-table-loading-inner')
        .add(hx.detached('div').class('hx-spinner'))
        .add(hx.detached('span').text(' ' + resolvedOptions.loadingText)))

    statusBar = hx.detached('div').class('hx-data-table-status-bar')

    statusBarText = hx.detached('span').class('hx-data-table-status-bar-text')

    statusBarClear = hx.detached('span').class('hx-data-table-status-bar-clear')
      .text(" (#{resolvedOptions.clearSelectionText})")
      .on 'click', 'hx.data-table', =>
        @_.selectedRows.clear()
        selection.select('.hx-data-table-content').selectAll('.hx-data-table-row-selected').classed('hx-data-table-row-selected', false)
        @updateSelected()
        @emit 'selectedrowsclear'

    controlPanelCompact = hx.detached('div').class('hx-data-table-control-panel-compact')

    controlPanelCompactToggle = hx.button().classed('hx-data-table-control-panel-compact-toggle hx-btn-invisible', true)
      .add(hx.icon({class: 'hx-icon hx-icon-bars'}))
      .on 'click', ->
        toggleElem = controlPanel
        if toggleElem.classed('hx-data-table-compact-hide')
          toggleElem.classed('hx-data-table-compact-hide', false)
            .style('height', '0px')
            .morph().with('expandv', 150)
            .then ->
              controlPanelCompact.classed('hx-data-table-control-panel-compact-open', true)
            .go()
        else
          toggleElem.morph().with('collapsev', 50)
            .then ->
              toggleElem.classed('hx-data-table-compact-hide', true)
              controlPanelCompact.classed('hx-data-table-control-panel-compact-open', false)
            .thenStyle('display', '')
            .go()

    controlPanel = hx.detached('div').class('hx-data-table-control-panel hx-data-table-compact-hide')
    controlPanelInner = hx.detached('div').class('hx-data-table-control-panel-inner')

    # compact sort - always on the page, only visible in compact mode (so we can just change the class and everything will work)
    compactSort = hx.detached('div').class('hx-data-table-sort')
      .classed('hx-data-table-sort-visible', resolvedOptions.sortEnabled)
      .add(hx.detached('span').text(resolvedOptions.sortByText + ': '))

    sortColPicker = new hx.Picker(compactSort.append('button').class('hx-btn hx-btn-invisible').node())
    sortColPicker.on 'change', 'hx.data-table', (d) =>
      if d.cause is 'user' then @sort({column: sortColPicker.value().column, direction: sortColPicker.value().direction})

    filterContainer = hx.detached('div').class('hx-data-table-filter-container')

    onInput = hx.debounce 200, => @filter(filterInput.value(), undefined, 'user')

    filterInput = hx.detached('input').class('hx-data-table-filter')
      .attr('placeholder', resolvedOptions.searchPlaceholder)
      .classed('hx-data-table-filter-visible', resolvedOptions.filterEnabled)
      .on 'input', 'hx.data-table', onInput

    advancedSearchContainer = hx.detached('div').class('hx-data-table-advanced-search-container')

    advancedSearchToggle = hx.button()
      .class('hx-data-table-advanced-search-toggle hx-btn hx-btn-invisible')
      .text(resolvedOptions.advancedSearchText)

    advancedSearchToggleButton = new hx.Toggle(advancedSearchToggle.node())
    advancedSearchToggleButton.on 'change', (data) => @advancedSearchEnabled(data)

    advancedSearch = hx.detached('div').class('hx-data-table-advanced-search')
    advancedSearchView = createAdvancedSearchView(advancedSearch, this, resolvedOptions)

    advancedSearchButtons = hx.detached('div').class('hx-data-table-advanced-search-buttons')

    addFilter = =>
      currentFilters = @advancedSearch() or [[]]
      [previousFilterGroups..., lastFilterGroup] = currentFilters
      newLastFilterGroup = [lastFilterGroup..., {
        column: 'any',
        term: ''
      }]
      @advancedSearch([previousFilterGroups..., newLastFilterGroup])

    clearFilters = => @advancedSearch(undefined)

    advancedSearchAddFilterButton = hx.button({context: 'positive'})
      .classed('hx-data-table-advanced-search-add-filter hx-data-table-advanced-search-button hx-btn-invert', true)
      .add(hx.icon({class: 'hx-data-table-advanced-search-icon hx-icon hx-icon-plus hx-text-positive'}))
      .add(hx.detached('span').text(resolvedOptions.addFilterText))
      .on 'click', addFilter

    advancedSearchClearFilterButton = hx.button({context: 'negative'})
      .classed('hx-data-table-advanced-search-clear-filters hx-data-table-advanced-search-button hx-btn-invert', true)
      .add(hx.icon({class: 'hx-data-table-advanced-search-icon hx-icon hx-icon-close hx-text-negative'}))
      .add(hx.detached('span').text(resolvedOptions.clearFiltersText))
      .on 'click', clearFilters

    # We create multiple copies of these to show in different places
    # This makes it easier to change the UI as we can show/hide instead of moving them
    [pageSize, pageSizePicker] = createPageSizeBlock(this, resolvedOptions)
    [pageSizeBottom, pageSizePickerBottom] = createPageSizeBlock(this, resolvedOptions)

    [pagination, pagePicker] = createPaginationBlock(this)
    [paginationBottom, pagePickerBottom] = createPaginationBlock(this)
    [paginationCompact, pagePickerCompact] = createPaginationBlock(this)

    # The main pagination is hidden as the compact control panel contains a version of it
    pagination.classed('hx-data-table-compact-hide', true)

    controlPanelBottom = hx.detached('div').class('hx-data-table-control-panel-bottom')

    # Create the structure in one place
    # Some entities still make sense to be built individually (e.g. the loading div)
    selection
      .add(content)
      .add(statusBar
        .add(statusBarText)
        .add(statusBarClear))
      # Control panel displayed at the top for compact mode
      .add(controlPanelCompact
        .add(paginationCompact)
        .add(spacer())
        .add(controlPanelCompactToggle))
      # Main control panel - contains all the components
      .add(controlPanel
        .add(controlPanelInner
          .add(compactSort)
          .add(pagination)
          .add(pageSize)
          .add(spacer())
          .add(filterContainer
            .add(advancedSearchToggle)
            .add(filterInput)))
        # The advanced search container isn't in the main control panel as it is easier to style outside
        .add(advancedSearchContainer
          .add(advancedSearch)
          .add(advancedSearchButtons
            .add(advancedSearchAddFilterButton)
            .add(advancedSearchClearFilterButton))))
      # Bottom control panel - shown in compact mode and when the search is at the top
      .add(controlPanelBottom
        .add(spacer())
        .add(pageSizeBottom)
        .add(paginationBottom))
      # Add the loading div last - helps keep it on top of everything
      .add(loadingDiv)

    # 'private' variables
    @_ = {
      selection: selection
      options: resolvedOptions
      page: 1
      pagePickers: [pagePicker, pagePickerCompact, pagePickerBottom]
      pageSizePickers: [pageSizePicker, pageSizePickerBottom]
      statusBar: statusBar
      sortColPicker: sortColPicker
      selectedRows: new hx.Set   # holds the ids of the selected rows
      expandedRows: new hx.Set
      renderedCollapsibles: {}
      compactState: (resolvedOptions.compact is 'auto' and selection.width() < collapseBreakPoint) or resolvedOptions.compact is true
      advancedSearchView: advancedSearchView
      advancedSearchToggleButton: advancedSearchToggleButton
    }

    # responsive page resize when compact is 'auto'
    selection.on 'resize', 'hx.data-table', =>
      console.log(@_.options)
      if @_.options.redrawOnResize
        console.log('redrawing')
        selection.selectAll('.hx-data-table-collapsible-content-container').map (e) =>
          e.style('max-width', (parseInt(selection.style('width')) - @_.collapsibleSizeDiff) + 'px')

        state = (@compact() is 'auto' and selection.width() < collapseBreakPoint) or @compact() is true
        selection.classed 'hx-data-table-compact', state
        if @_.compactState isnt state
          @_.compactState = state
          @emit('compactchange', {value: @compact(), state: state, cause: 'user'})

    randomId = hx.randomId()

    # deal with shift being down - prevents the text in the table being selected when shift
    # selecting multiple rows (as it looks bad) but also means that data can be selected if required
    # XXX: make this work better / come up with a better solution
    hx.select('body').on 'keydown', 'hx.data-table.shift.' + randomId, (e) =>
      if e.shiftKey and @selectEnabled()
        selection.classed('hx-data-table-disable-text-selection', true)

    hx.select('body').on 'keyup', 'hx.data-table.shift.' + randomId, (e) =>
      if not e.shiftKey and @selectEnabled()
        selection.classed('hx-data-table-disable-text-selection', false)



  # Methods for changing the options
  #---------------------------------

  # general purpose function for setting / getting an option
  option = (name) ->
    (value, cb, cause) ->
      options = @_.options
      if arguments.length > 0
        options[name] = value
        @emit(name.toLowerCase() + 'change', {value: value, cause: (cause or 'api')})
        @render(cb)
        this
      else options[name]

  collapsibleRenderer: option('collapsibleRenderer')
  compact: option('compact')
  displayMode: option('displayMode')
  feed: option('feed')
  filter: option('filter')
  advancedSearch: option('advancedSearch')
  showAdvancedSearch: option('showAdvancedSearch')
  advancedSearchEnabled: option('advancedSearchEnabled')
  showSearchAboveTable: option('showSearchAboveTable')
  filterEnabled: option('filterEnabled')
  noDataMessage: option('noDataMessage')
  pageSize: option('pageSize')
  pageSizeOptions: option('pageSizeOptions')
  redrawOnResize: option('redrawOnResize')
  retainHorizontalScrollOnRender: option('retainHorizontalScrollOnRender')
  retainVerticalScrollOnRender: option('retainVerticalScrollOnRender')
  rowCollapsibleLookup: option('rowCollapsibleLookup')
  rowEnabledLookup: option('rowEnabledLookup')
  rowIDLookup: option('rowIDLookup')
  rowSelectableLookup: option('rowSelectableLookup')
  selectEnabled: option('selectEnabled')
  singleSelection: option('singleSelection')
  sort: option('sort')

  # general purpose function for setting / getting a column option (or the default option of the column id is not specified)
  columnOption = (name) ->
    (columnId, value, cb) ->
      options = @_.options
      if arguments.length > 1 and hx.isString(columnId)
        options.columns[columnId] ?= {}
        options.columns[columnId][name] = value
        @emit(name.toLowerCase() + 'change', {column: columnId, value: value, cause: 'api'})
        @render(cb)
        this
      else if arguments.length > 0
        if hx.isString(columnId) and options.columns[columnId]
          options.columns[columnId][name]
        else
          options[name] = arguments[0]
          @emit(name.toLowerCase() + 'change', {value: value, cause: 'api'})
          @render(arguments[1])
          this
      else options[name]

  allowHeaderWrap: columnOption('allowHeaderWrap')
  cellRenderer: columnOption('cellRenderer')
  headerCellRenderer: columnOption('headerCellRenderer')
  sortEnabled: columnOption('sortEnabled')

  # function for setting / getting options that are only column specific and cannot be set for the whole table
  columnOnlyOption = (name) ->
    (columnId, value, cb) ->
      options = @_.options
      if hx.isString(columnId)
        if arguments.length > 1
          options.columns[columnId] ?= {}
          options.columns[columnId][name] = value
          @emit(name.toLowerCase() + 'change', {column: columnId, value: value, cause: 'api'})
          @render(cb)
          this
        else if options.columns[columnId]
          options.columns[columnId][name]

  maxWidth: columnOnlyOption('maxWidth')


  # Methods for changing the state of the table
  # -------------------------------------------

  page: (value, cb, cause) ->
    if arguments.length > 0
      @_.page =  Math.max(1, value)
      if @_.numPages?
        @_.page = Math.min @_.page, @_.numPages
      @emit('pagechange', {value: @_.page, cause: cause or 'api'})
      @render(cb)
      this
    else @_.page

  selectedRows: (value, cb) ->
    if arguments.length > 0 and not hx.isFunction(value)

      # Deal with single select mode when setting the selected rows
      if @singleSelection() and hx.isArray(value) and value.length
        value = [value[0]]
      @_.selectedRows = new hx.Set(value)
      newSelectedRows = @_.selectedRows.values()
      @emit('selectedrowschange', {value: newSelectedRows, cause: 'api'})
      @_.userLastSelectedIndex = undefined
      @render(cb)
      this
    else
      @_.selectedRows.values()

  expandedRows: (value, cb) ->
    if arguments.length > 0 and not hx.isFunction(value)
      @_.expandedRows = new hx.Set(value)
      @render(cb)
      @emit('expandedrowschange', {value: @_.expandedRows.values(), cause: 'api'})
      this
    else
      @_.expandedRows.values()

  rowsForIds: (ids, cb) ->
    if cb? then @feed().rowsForIds(ids, @rowIDLookup(), cb)
    this

  # Methods that perform an action on the table
  # -------------------------------------------

  renderSuppressed: (value) ->
    if arguments.length > 0
      @_.renderSuppressed = value
      this
    else @_.renderSuppressed

  # redraws the table
  render: (cb) ->
    if @_.renderSuppressed then return

    feed = @feed()

    # check that the feed has been defined - if it hasn't then there is no point in continuing
    if feed is undefined or (feed.headers is undefined or feed.totalCount is undefined or feed.rows is undefined)
      hx.consoleWarning('No feed specified when rendering data table')
      return

    selection = @_.selection
    options = @_.options

    # some utility functions
    getColumnOption = (name, id) -> columnOptionLookup(options, name, id)

    rowToArray = (headers, obj) -> headers.map (header) -> obj.cells[header.id]

    # build the main structure of the table in a detached container
    container = hx.detached('div').class('hx-data-table-content')
    table = container.append('table').class('hx-data-table-table hx-table')
    thead = table.append('thead').class('hx-data-table-head')
    tbody = table.append('tbody').class('hx-data-table-body')
    headerRow = thead.append('tr').class('hx-data-table-row')

    # make the loading div visible
    selection.select('.hx-data-table-loading').style('display', '')

    advancedSearchVisibleAndEnabled = (not options.filterEnabled or options.showAdvancedSearch) and options.advancedSearchEnabled

    selection.select('.hx-data-table-filter')
      .classed('hx-data-table-filter-visible', options.filterEnabled and not advancedSearchVisibleAndEnabled)

    @_.advancedSearchToggleButton.value(options.advancedSearchEnabled)

    selection.select('.hx-data-table-advanced-search-toggle')
      .classed('hx-data-table-advanced-search-visible', options.filterEnabled and options.showAdvancedSearch)

    selection.select('.hx-data-table-advanced-search-container')
      .classed('hx-data-table-advanced-search-visible', advancedSearchVisibleAndEnabled)

    selection.select('.hx-data-table-control-panel')
      .classed('hx-data-table-filter-enabled', options.filterEnabled)

    showCompactControlPanelToggle = options.filterEnabled or options.sortEnabled or options.advancedSearchEnabled or options.pageSizeOptions?.length

    selection.select('.hx-data-table-control-panel-compact-toggle')
      .classed('hx-data-table-control-panel-compact-toggle-visible', showCompactControlPanelToggle)

    # load in the data needed
    # XXX: how much of this could be split out so it's not re-defined every time render is called?
    feed.headers (headers) =>
      if advancedSearchVisibleAndEnabled
        currentFilters = @advancedSearch() or []
        @_.advancedSearchView.apply currentFilters.filter((x) -> x.length).map (filterGroup) ->
          filterGroup.map (filterRow) ->
            hx.merge(filterRow, {
              headers,
              getColumnOption
            })

      selection.select('.hx-data-table-sort')
        .classed('hx-data-table-sort-visible', options.sortEnabled or headers.some((header) -> getColumnOption('sortEnabled', header.id)))

      feed.totalCount (totalCount) =>
        if options.displayMode is 'paginate'
          start = (@page() - 1) * options.pageSize
          end = @page() * options.pageSize - 1
        else
          start = undefined
          end = undefined

        selection.classed('hx-data-table-infinite', totalCount is undefined)

        range = {
          start: start,
          end: end,
          sort: @sort(),
          filter: @filter(),
          advancedSearch: @advancedSearch(),
          useAdvancedSearch: options.showAdvancedSearch and options.advancedSearchEnabled
        }

        feed.rows range, ({rows, filteredCount}) =>
          if options.displayMode is 'paginate'
            multiPage = false
            if filteredCount is undefined
              @_.numPages = undefined
              numText = (start+1) + ' - ' + (end+1)
              multiPage = true
            else

              @_.numPages = Math.max(1, Math.ceil(filteredCount / options.pageSize))

              if @page() > @_.numPages then @page(@_.numPages)

              multiPage = @_.numPages > 1

              if filteredCount > 0 and @_.numPages > 1
                numText = 'of ' + filteredCount
                items = for i in [1..@_.numPages] by 1
                  num = i * options.pageSize
                  text: (num + 1 - options.pageSize) + ' - ' + Math.min(num, filteredCount) # e.g. 1 - 15
                  value: i

                @_.pagePickers.forEach (picker) =>
                  picker
                    .items(items)
                    .value(@page())

            selection.selectAll('.hx-data-table-paginator').classed('hx-data-table-paginator-visible', multiPage)

            selection.selectAll('.hx-data-table-paginator-total-rows').text(numText or '')

            selection.selectAll('.hx-data-table-paginator-back').classed('hx-data-table-btn-disabled', @page() is 1)
            selection.selectAll('.hx-data-table-paginator-forward').classed('hx-data-table-btn-disabled', @page() is @_.numPages)

          selection.select('.hx-data-table-control-panel-compact')
            .classed('hx-data-table-control-panel-compact-visible', multiPage or showCompactControlPanelToggle)

          selection.select('.hx-data-table-control-panel-bottom')
            .classed('hx-data-table-control-panel-bottom-visible', multiPage or options.pageSizeOptions?.length)

          selection.select('.hx-data-table-control-panel')
            .classed('hx-data-table-control-panel-visible', multiPage or showCompactControlPanelToggle)

          if headers.some((header) -> getColumnOption('sortEnabled', header.id))
            currentSort = (@sort() or {})

            # filter out columns that are not sortable so they don't show in the list for compact mode
            sortColumns = hx.flatten(headers
              .map((header) -> if getColumnOption('sortEnabled', header.id)
                [
                  {text: header.name, value: header.id + 'asc', column: header.id, direction: 'asc', cell: header}
                  {text: header.name, value: header.id + 'desc', column: header.id, direction: 'desc',  cell: header}
                ])
              .filter(hx.defined))


            # set the values for the compact sort control
            @_.sortColPicker
              .renderer((element, option) ->
                if option.value
                  getColumnOption('headerCellRenderer', option.cell.id)(element, option.cell, headers)
                  hx.select(element).append('i')
                    .class('hx-data-table-compact-sort-arrow hx-icon hx-icon-chevron-' + (if option.direction is 'asc' then 'up' else 'down'))
                else
                  hx.select(element).text(option.text)
              )
              .items([{text: options.noSortText, value: undefined}].concat sortColumns)

            if currentSort.column and @_.sortColPicker.value().value isnt (currentSort.column + currentSort.direction)
              @_.sortColPicker.value({value: currentSort.column + currentSort.direction})

          # populate the page size picker if there are options set
          if filteredCount isnt undefined and filteredCount > 0
            selectPageSize = options.pageSizeOptions? and options.pageSizeOptions.length > 0
            selection.selectAll('.hx-data-table-page-size').classed('hx-data-table-page-size-visible', selectPageSize)

            if selectPageSize
              if options.pageSizeOptions.indexOf(options.pageSize) is -1
                options.pageSizeOptions.push options.pageSize

              pageSizeOptions = options.pageSizeOptions
                .sort(hx.sort.compare)
                .map((item) -> {text: item, value: item})

              @_.pageSizePickers.forEach (picker) ->
                picker
                  .items(pageSizeOptions)
                  .value(options.pageSize)

          # build the grouped header
          if headers.some((header) -> header.groups?)
            relevantHeaders = headers.filter((e) -> e.groups?).map((e) -> e.groups.length)
            maxHeaderDepth = Math.max.apply(null,  relevantHeaders)

            # Map over to populate columns with groups of '' where not included
            headerGroups = headers.map (e) ->
              groups = e.groups or []
              groups.push '' while groups.length < maxHeaderDepth
              groups

            for row in [maxHeaderDepth-1..0] by -1
              groupedRow = headerRow.insertBefore 'tr'
              groupedRow.append('th').class('hx-data-table-control') if options.selectEnabled or options.collapsibleRenderer?
              count = 1
              for column in [1..headerGroups.length] by 1
                col = headerGroups[column]
                prevCol = headerGroups[column-1]
                if col? and prevCol?
                  parent = col.slice(row, maxHeaderDepth).toString()
                  prevParent = prevCol.slice(row, maxHeaderDepth).toString()

                if column is headerGroups.length or col[row] isnt prevCol[row] or parent isnt prevParent
                  groupedRow.append('th')
                    .attr('colspan', count)
                    .class('hx-data-table-cell-grouped')
                    .text(prevCol[row])
                  count = 0
                count++


          # add the 'select all' checkbox to the header
          if options.selectEnabled or options.collapsibleRenderer?
            headerControlBox = headerRow.append('th').class('hx-data-table-control hx-table-head-no-border')

          if options.selectEnabled and not options.singleSelection
            headerCheckBox = headerControlBox.append('div').class('hx-data-table-checkbox')
              .on 'click', 'hx.data-table', =>
                if rows.length > 0
                  enabledRows = rows.filter (row) -> options.rowEnabledLookup(row)
                  selectMulti(0, rows.length - 1, not enabledRows.every((row) => @_.selectedRows.has(options.rowIDLookup(row))))
            headerCheckBox.append('i').class('hx-icon hx-icon-check')


          # build the header
          headers.forEach (header, i) =>
            cellDiv = headerRow.append('th').class('hx-data-table-cell')
              .classed('hx-table-header-allow-wrap', getColumnOption('allowHeaderWrap', header.id))

            cellDivContent = cellDiv.append('div').class('hx-data-table-cell-inner')

            getColumnOption('headerCellRenderer', header.id)(cellDivContent.append('span').class('hx-data-table-title').node(), header, headers)

            if getColumnOption('sortEnabled', header.id)
              cellDiv.classed('hx-data-table-cell-sort-enabled', true)

              currentSort = @sort()
              dirClass = if currentSort and currentSort.column is header.id
                'hx-icon-sort-' + currentSort.direction + ' hx-data-table-sort-on'
              else 'hx-icon-sort'
              cellDivContent.append('i').class('hx-icon ' + dirClass + ' hx-data-table-sort-icon')

              cellDiv.on 'click', 'hx.data-table', =>
                currentSort = @sort() or {}
                direction = if currentSort.column is header.id
                  if currentSort.direction is 'asc' then 'desc'
                else 'asc'
                column = if direction isnt undefined then header.id
                @sort({column: column, direction: direction}, undefined, 'user')


          @updateSelected = =>
            parentFilter = (parent) ->
              (sel) -> sel.node().parentNode is parent.node()

            getSelectableRows = (parent) ->
              parent
                .selectAll('.hx-data-table-row')
                .filter(parentFilter(parent))
                .classed('hx-data-table-row-selected', false)

            rowDivs = getSelectableRows(tbody)

            leftHeaderBody = container.select('.hx-sticky-table-header-left').select('tbody')
            checkBoxDivs = getSelectableRows(leftHeaderBody)

            if @_.selectedRows.size > 0
              for row, rowIndex in rows
                if @_.selectedRows.has(options.rowIDLookup(row))
                  hx.select(rowDivs.nodes[rowIndex]).classed('hx-data-table-row-selected', true)
                  if checkBoxDivs.nodes[rowIndex]?
                    hx.select(checkBoxDivs.nodes[rowIndex]).classed('hx-data-table-row-selected', true)

            pageHasSelection = tbody.selectAll('.hx-data-table-row-selected').size() > 0
            selection.classed('hx-data-table-has-page-selection', pageHasSelection and not options.singleSelection)
            selection.classed('hx-data-table-has-selection', @_.selectedRows.size > 0 and not options.singleSelection)
            if totalCount isnt undefined
              @_.statusBar
                .select('.hx-data-table-status-bar-text')
                .text(options.selectedRowsText.replace('$selected', @_.selectedRows.size).replace('$total', totalCount))

          # handles multi row selection ('select all' and shift selection)
          selectMulti = (start, end, force) =>
            newRows = []
            newRows.push rows[i] for i in [start..end] by 1

            for row in newRows
              if options.rowEnabledLookup(row) and options.rowSelectableLookup(row)
                id = options.rowIDLookup(row)
                @_.selectedRows[if force then 'add' else 'delete'](id)
                @emit 'selectedrowschange', {row: row, rowValue: @_.selectedRows.has(id), value: @selectedRows(), cause: 'user'}
            @updateSelected()

          # handles row selection.
          selectRow = (row, index, shiftDown) =>
            if @_.userLastSelectedIndex?
              if options.singleSelection and index isnt @_.userLastSelectedIndex
                @_.selectedRows.clear()
              else
                # does the check for whether we're shift selecting and calls into selectMulti if we are
                if shiftDown and index isnt @_.userLastSelectedIndex
                  force = @_.selectedRows.has(options.rowIDLookup(rows[@_.userLastSelectedIndex]))
                  if index > @_.userLastSelectedIndex then selectMulti(@_.userLastSelectedIndex + 1, index, force)
                  else selectMulti(index, @_.userLastSelectedIndex, force)
                  return

            @_.userLastSelectedIndex = index

            if options.rowSelectableLookup(row)
              id = options.rowIDLookup(row)
              deleteOrAdd = if @_.selectedRows.has(id) then 'delete' else 'add'
              @_.selectedRows[deleteOrAdd](id)
              @emit 'selectedrowschange', {row: row, rowValue: @_.selectedRows.has(id), value: @selectedRows(), cause: 'user'}
            @updateSelected()

          # Deal with collapsible rows
          buildCollapsible = ->
            contentRow = hx.detached('tr').class('hx-data-table-collapsible-content-row')
            hiddenRow = hx.detached('tr').class('hx-data-table-collapsible-row-spacer')

            # Add an empty cell so the sticky headers display correctly
            contentRow.append('td').class('hx-data-table-collapsible-cell hx-data-table-collapsible-cell-empty')

            # The div that the user will populate with the collapsibleRender function
            contentDiv = contentRow.append('td').class('hx-data-table-collapsible-cell')
              .attr('colspan',fullWidthColSpan)
              .append('div').class('hx-data-table-collapsible-content-container')
              .append('div').class('hx-data-table-collapsible-content')

            {contentRow: contentRow, hiddenRow: hiddenRow, contentDiv: contentDiv}

          toggleCollapsible = (node, row, force) =>
            # once rows have been clicked once, the nodes are stored in the _.renderedCollapsibles object for re-use
            rowId = options.rowIDLookup(row)
            cc = @_.renderedCollapsibles[rowId] or buildCollapsible(row)
            @_.renderedCollapsibles[rowId] = cc

            # We always insert after here to make sure the nodes are added when setting the collapsible rows with the API
            node.insertAfter(cc.hiddenRow).insertAfter(cc.contentRow)

            currentVis = if force? then force else !cc.contentRow.classed('hx-data-table-collapsible-row-visible')
            cc.contentRow.classed('hx-data-table-collapsible-row-visible', currentVis)
            node.classed('hx-data-table-collapsible-row-visible', currentVis)
            node.select('.hx-data-table-collapsible-toggle').select('i').class(if currentVis then 'hx-icon hx-icon-minus' else 'hx-icon hx-icon-plus')

            if currentVis then options.collapsibleRenderer cc.contentDiv.node(), row
            else
              @_.renderedCollapsibles[rowId].contentRow.remove()
              @_.renderedCollapsibles[rowId].hiddenRow.remove()
              delete @_.renderedCollapsibles[rowId]

            @_.expandedRows[if currentVis then 'add' else 'delete'](rowId)
            @_.stickyHeaders.render()

            @_.collapsibleSizeDiff = parseInt(selection.style('width')) - parseInt(hx.select(cc.contentDiv.node().parentNode).style('width'))

            currentVis

          # build the rows
          if filteredCount is undefined or filteredCount > 0
            rows.forEach (row, rowIndex) =>
              tr = tbody.append('tr').class('hx-data-table-row')
                .classed('hx-data-table-row-selected', @_.selectedRows.has(options.rowIDLookup(row)))
                .classed('hx-data-table-row-disabled', not options.rowEnabledLookup(row))

              tr.on 'click', 'hx.data-table', (e) => @emit 'rowclick', {data: row, node: tr.node()}

              rowIsCollapsible = options.rowCollapsibleLookup(row) # stored as we use it more than once

              # used in compact mode to display the tick correctly without letting text flow behind it.
              tr.classed('hx-data-table-row-select-enabled', options.selectEnabled)

              if options.selectEnabled or options.collapsibleRenderer?
                controlDiv = tr.append('th').class('hx-data-table-control')

                if options.selectEnabled
                  checkbox = controlDiv.append('div').class('hx-data-table-checkbox')
                  checkbox.append('i').class('hx-icon hx-icon-check')

                  if options.rowEnabledLookup(row)
                    checkbox.on 'click', 'hx.data-table', (e) ->
                      e.stopPropagation() # prevent collapsibles being toggled by tick selection in compact mode
                      selectRow(row, rowIndex, e.shiftKey)

                if options.collapsibleRenderer?
                  collapsibleControl = controlDiv.append('div')
                    .class('hx-data-table-collapsible-toggle')
                    .classed('hx-data-table-collapsible-disabled', not rowIsCollapsible)
                  collapsibleControl.append('i').class('hx-icon hx-icon-plus')

                if rowIsCollapsible
                  # restore open collapsibles on render
                  if @_.expandedRows.has(options.rowIDLookup(row)) then toggleCollapsible(tr, row, true)
                  collapsibleControl.on 'click', 'hx.data-table.collapse-row', (e) =>
                    currentVis = toggleCollapsible(tr, row)
                    @emit('expandedrowschange', {value: @_.expandedRows.values(), row: row, rowValue: currentVis, cause: 'user'})

              # populate the row
              for cell, columnIndex in rowToArray(headers, row)

                # Render the 'key' value using the headerCellRenderer
                keyDiv = hx.detached('div').class('hx-data-table-cell-key')
                getColumnOption('headerCellRenderer', headers[columnIndex].id)(keyDiv.node(), headers[columnIndex], headers)

                cellElem = tr.append('td').class('hx-data-table-cell')
                columnMaxWidth = getColumnOption('maxWidth', headers[columnIndex].id)
                if columnMaxWidth?
                  columnMaxWidth = parseInt(columnMaxWidth) + 'px'
                  cellElem
                    .style('max-width', columnMaxWidth)
                    .style('width', columnMaxWidth)
                    .style('min-width', columnMaxWidth)

                cellDiv = cellElem.add(keyDiv)
                  .append('div').class('hx-data-table-cell-value').node()
                getColumnOption('cellRenderer', headers[columnIndex].id)(cellDiv, cell, row)
          else # append the 'No Data' row.
            tbody.append('tr').class('hx-data-table-row-no-data').append('td').attr('colspan', fullWidthColSpan).text(options.noDataMessage)

          @updateSelected()

          # retain the horizontal scroll unless the page has been changed.
          # We only retain the horizontal scroll as when sorting/filtering on
          # the first page it retains the vertical scroll which looks weird.
          if @page() is @_.oldPage
            wrapperNode = selection.select('.hx-data-table-content > .hx-sticky-table-wrapper').node()
            scrollLeft = wrapperNode.scrollLeft if options.retainHorizontalScrollOnRender
            scrollTop = wrapperNode.scrollTop if options.retainVerticalScrollOnRender

          # store the old page - only used for retaining the scroll positions
          @_.oldPage = @page()

          # remove the old content div, and slot in the new one
          selection.select('.hx-data-table-content').insertAfter(container)
          selection.select('.hx-data-table-content').remove()

          selection.classed('hx-data-table-compact', ((options.compact is 'auto') and (selection.width() < collapseBreakPoint)) or (options.compact is true))
            .classed('hx-data-table-show-search-above-content', options.showSearchAboveTable)

          # set up the sticky headers
          stickFirstColumn = options.selectEnabled or options.collapsibleRenderer?
          stickyOpts = {stickFirstColumn: stickFirstColumn and (filteredCount is undefined or filteredCount > 0), fullWidth: true}
          @_.stickyHeaders = new hx.StickyTableHeaders(container.node(), stickyOpts)

          # restore horizontal scroll position
          selection.select('.hx-data-table-content > .hx-sticky-table-wrapper').node().scrollLeft = scrollLeft if scrollLeft?
          selection.select('.hx-data-table-content > .hx-sticky-table-wrapper').node().scrollTop = scrollTop if scrollTop?

          # hide the loading spinner as we're done rendering
          selection.select('.hx-data-table-loading').style('display', 'none')

          @emit 'render'
          cb?()

    this


###
  Feeds

  A feed should be an object with the following functions:

  {
    headers: (cb) ->        # returns a list of header objects ({name, id})
    totalCount: (cb) ->     # returns the total number of rows in the data set
    rows: (range, cb) ->    # returns the row data for the range object specified (range = { start, end, filter, sort }) along with the filtered count
    rowsForIds: (ids, lookupRow, cb) ->  # returns the rows for the ids supplied
  }

  There are predefined feeds for objects and urls.

###
whitespaceSplitRegex = /\s+/
stripLeadingAndTrailingWhitespaceRegex = /^\s+|\s+$/g

getRowSearchTerm = (cellValueLookup, row) ->
  (v for k, v of row.cells).map(cellValueLookup).join(' ').toLowerCase()

defaultTermLookup = (term, rowSearchTerm) ->
  arr = term.replace(stripLeadingAndTrailingWhitespaceRegex,'')
    .split whitespaceSplitRegex
  validPart = hx.find arr, (part) -> ~rowSearchTerm.indexOf part
  hx.defined validPart

getAdvancedSearchFilter = (cellValueLookup = hx.identity, termLookup = defaultTermLookup) ->
  (filters, row) ->
    rowSearchTerm = getRowSearchTerm(cellValueLookup, row)
    # If term is empty this will return false
    validFilters = hx.find filters, (groupedFilters) ->
      invalidFilter = hx.find groupedFilters, (filter) ->
        searchTerm = if filter.column is 'any' then rowSearchTerm else (cellValueLookup(row.cells[filter.column]) + '').toLowerCase()
        not termLookup filter.term.toLowerCase(), searchTerm
      not hx.defined invalidFilter
    hx.defined validFilters

objectFeed = (data, options) ->
  options = hx.merge({
    cellValueLookup: hx.identity
    termLookup: defaultTermLookup

    #XXX: should this provide more information - like the column id being sorted on?
    compare: hx.sort.compare
  }, options)

  options.filter ?= (term, row) -> options.termLookup(term.toLowerCase(), getRowSearchTerm(options.cellValueLookup, row))
  options.advancedSearch ?= getAdvancedSearchFilter(options.cellValueLookup, options.termLookup)

  # cached values
  filtered = undefined
  filterCacheTerm = undefined
  sorted = undefined
  sortCacheTerm = {}
  rowsByIdMap = undefined

  {
    data: data # for debugging
    headers: (cb) -> cb(data.headers)
    totalCount: (cb) -> cb(data.rows.length)
    rows: (range, cb) ->

      if range.sort?.column isnt sortCacheTerm.column
        filtered = undefined

      if range.useAdvancedSearch
        filtered = if range.advancedSearch?.length and (filtered is undefined or filterCacheTerm isnt range.advancedSearch)
          data.rows.filter((row) -> options.advancedSearch(range.advancedSearch, row))
        else
          data.rows.slice()

        filterCacheTerm = range.advancedSearch
        sorted = undefined
      else
        filtered =  if range.filter and (filtered is undefined or filterCacheTerm isnt range.filter)
          data.rows.filter((row) -> options.filter(range.filter, row))
        else
          data.rows.slice()
        filterCacheTerm = range.filter
        sorted = undefined

      if sorted is undefined or sortCacheTerm.column isnt range.sort?.column or sortCacheTerm.direction isnt range.sort?.direction
        sorted = if range.sort and range.sort.column
          direction = if range.sort.direction is 'asc' then 1 else -1
          column = range.sort.column
          filtered.sort (r1, r2) -> direction * options.compare(r1.cells[column], r2.cells[column])
          filtered
        else filtered
        sortCacheTerm.column = range.sort?.column
        sortCacheTerm.direction = range.sort?.direction

      cb({rows: sorted[range.start..range.end], filteredCount: sorted.length})
    rowsForIds: (ids, lookupRow, cb) ->
      if rowsByIdMap is undefined
        rowsByIdMap = {}
        for row in data.rows
          rowsByIdMap[lookupRow(row)] = row
      cb(rowsByIdMap[id] for id in ids)
  }

urlFeed = (url, options) ->
  #XXX: when new calls come in, ignore the ongoing request if there is one / cancel the request if possible

  options = hx.merge({
    extra: undefined,
    cache: false
  }, options)

  # creates a function that might perform caching, depending on the options.cache value
  maybeCached = (fetcher) ->
    if options.cache
      value = undefined
      (cb) ->
        if value
          cb(value)
        else
          fetcher (res) ->
            value = res
            cb(value)
    else
      (cb) -> fetcher(cb)

  jsonCallback = (cb) ->
    (err, value) ->
      hx.consoleWarning(err) if err
      cb(value)

  {
    url: url # for debugging
    headers: maybeCached (cb) ->
      hx.json url, { type: 'headers', extra: options.extra }, jsonCallback(cb)
    totalCount: maybeCached (cb) ->
      hx.json url, { type: 'totalCount', extra: options.extra }, (err, res) ->
        jsonCallback(cb)(err, res.count)
    rows: (range, cb) ->
      hx.json url, { type: 'rows', range: range, extra: options.extra }, jsonCallback(cb)
    rowsForIds: (ids, lookupRow, cb) ->
      hx.json url, { type: 'rowsForIds', ids: ids, extra: options.extra }, jsonCallback(cb)
  }



hx.DataTable = DataTable

hx.dataTable = (options) ->
  selection = hx.detached('div')
  dataTable = new DataTable(selection.node(), options)
  if options and options.feed then dataTable.render()
  selection

hx.dataTable.objectFeed = objectFeed
hx.dataTable.urlFeed = urlFeed
hx.dataTable.getAdvancedSearchFilter = getAdvancedSearchFilter
