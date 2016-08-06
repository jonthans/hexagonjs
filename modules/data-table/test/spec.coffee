describe 'data-table', ->
  origConsoleWarning = hx.consoleWarning
  clockTime = (new Date(2013, 0, 1)).getTime()
  dropdownAnimationTime = 150
  inputDebounceDelay = 200
  animationCompletedDelay = 500

  beforeEach ->
    hx.consoleWarning = chai.spy()

  afterEach ->
    hx.consoleWarning = origConsoleWarning

  noData = {
    headers: [
      { name: 'Name', id: 'name' },
      { name: 'Age', id: 'age' },
      { name: 'Profession', id: 'profession' }
    ],
    rows: []
  }

  threeRowsData = {
    headers: [
      { name: 'Name', id: 'name' },
      { name: 'Age', id: 'age' },
      { name: 'Profession', id: 'profession' }
    ],
    rows: [
      {
        id: '0', # hidden details can go here (not in the cells object)
        collapsible: true,
        cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
      },
      {
        id: '1',
        cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
      },
      {
        id: '2',
        collapsible: true,
        cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
      }
    ]
  }

  headers = ['Name', 'Age', 'Profession']

  fakeEvent = {
    # fake some dom event stuff
    stopPropagation: ->
  }

  fakeShiftEvent = {
    stopPropagation: ->
    shiftKey: true
  }

  # Fake the changing of a picker value by clicking a value
  emulatePickerValueChange = (pickerNode, dt, valueIndex, done, expectation) ->
    clock = sinon.useFakeTimers(clockTime)
    renderSpy = chai.spy expectation
    dt.on 'render', renderSpy

    testHelpers.fakeNodeEvent(pickerNode)(fakeEvent)
    clock.tick(dropdownAnimationTime)
    dropdown = hx.select('.hx-dropdown')
    targetNode = dropdown.selectAll('.hx-menu-item').node(valueIndex)

    pickerEvent = {
      stopPropagation: ->
      target: targetNode
    }

    testHelpers.fakeNodeEvent(dropdown.node())(pickerEvent)
    renderSpy.should.have.been.called()
    clock.restore()
    hx.select('body').clear()
    done()

  checkSetterGetter = (name, valuesToCheck) ->
    describe name, ->
      it 'setting and getting should work', ->
        dt = new hx.DataTable(hx.detached('div').node())
        for value in valuesToCheck
          dt[name](value)
          if value?
            dt[name]().should.eql(value)
          else
            should.not.exist(dt[name]())


  checkOption = (name, valuesToCheck, dontSpy) ->
    describe name, ->
      checkSetterGetter(name, valuesToCheck)

      it 'passing in option to constructor should work', ->
        for value in valuesToCheck
          options = {}
          options[name] = value
          dt = new hx.DataTable(hx.detached('div').node(), options)
          if value?
            dt[name]().should.eql(value)
          else
            should.not.exist(dt[name]())

      it 'should trigger render by default', ->
        for value in valuesToCheck
          options = {}
          options[name] = value
          dt = new hx.DataTable(hx.detached('div').node(), options)
          dt.render = chai.spy()
          dt[name](value)
          dt.render.should.have.been.called()

      it 'should call callback if passed in', ->
        for value in valuesToCheck
          options = {}
          options[name] = value
          dt = new hx.DataTable(hx.detached('div').node(), options)
          dt.feed(hx.dataTable.objectFeed(threeRowsData))
          cb = chai.spy()
          dt[name](value, cb)
          cb.should.have.been.called()

       it 'should emit an event with {cause: api} when changed via the api', (done) ->
        checked = 0
        for value in valuesToCheck
          dt = new hx.DataTable(hx.detached('div').node(), {feed: hx.dataTable.objectFeed(threeRowsData)})
          dt.on name.toLowerCase() + 'change', (d) ->
            if(d.value isnt undefined)
              d.value.should.eql(value)
            d.cause.should.equal('api')
            checked++
            if checked == valuesToCheck.length then done()
          dt[name](value)




  checkColumnOption = (name, valuesToCheck, columnOnly) ->
    describe 'column option: ' + name, ->
      columnId = 'col-id'

      if columnOnly
        it 'should return undefined if the column id is not a string', ->
          dt = new hx.DataTable(hx.detached('div').node())
          should.not.exist(dt[name]())
          should.not.exist(dt[name](undefined))
          for value in valuesToCheck
            should.not.exist(dt[name](value))

        it 'should return undefined if the value is not set for a column', ->
          dt = new hx.DataTable(hx.detached('div').node())
          should.not.exist(dt[name](columnId))

      else
        checkSetterGetter(name, valuesToCheck)
        checkOption(name, valuesToCheck, true)

      it 'passing in option to constructor should work', ->
        for value in valuesToCheck
          options = {columns: {}}
          options.columns[columnId] ?= {}
          options.columns[columnId][name] = value
          dt = new hx.DataTable(hx.detached('div').node(), options)
          dt[name](columnId).should.equal(value)

      it 'should trigger render by default', ->
        for value in valuesToCheck
          dt = new hx.DataTable(hx.detached('div').node())
          dt.render = chai.spy()
          dt[name](columnId, value)
          dt.render.should.have.been.called()

      it 'setting should return the data table for chaining', ->
        dt = new hx.DataTable(hx.detached('div').node())
        for value in valuesToCheck
          dt[name](columnId, value).should.equal(dt)

      it 'setting to undefined should clear the previous value (and re-enable the default)', ->
        dt = new hx.DataTable(hx.detached('div').node())
        for value in valuesToCheck
          dt[name](columnId, value)
          dt[name](columnId).should.equal(value)
          dt[name](columnId, undefined)
          should.not.exist(dt[name](columnId))

      it 'should emit an event with {cause: api, columnId: columnId} when changed via the api', (done) ->
        checked = 0
        for value in valuesToCheck
          dt = new hx.DataTable(hx.detached('div').node(), {feed: hx.dataTable.objectFeed(threeRowsData)})
          dt.on name.toLowerCase() + 'change', (d) ->
            if(d.value isnt undefined)
              d.value.should.eql(value)
            d.column.should.equal(columnId)
            d.cause.should.equal('api')
            checked++
            if checked == valuesToCheck.length then done()
          dt[name](columnId, value)

  testTable = (options, done, spec) ->
    tableOptions = options.tableOptions
    data = options.data or threeRowsData
    containerWidth = options.containerWidth or 1000
    container = hx.detached('div')
      .style('width', containerWidth + 'px')

    if options.containerHeight?
      container.style('height', options.containerHeight + 'px')
    hx.select('body').append(container)
    dt = new hx.DataTable(container.node(), tableOptions)
    dt.feed hx.dataTable.objectFeed(data), ->
      spec(container, dt, options, data)
      hx.select('body').clear()
      done?()

  it 'should have user facing text defined', ->
    hx.userFacingText('dataTable', 'addFilter').should.equal('Add Filter')
    hx.userFacingText('dataTable', 'advancedSearch').should.equal('Advanced Search')
    hx.userFacingText('dataTable', 'and').should.equal('and')
    hx.userFacingText('dataTable', 'anyColumn').should.equal('Any column')
    hx.userFacingText('dataTable', 'clearFilters').should.equal('Clear Filters')
    hx.userFacingText('dataTable', 'clearSelection').should.equal('clear selection')
    hx.userFacingText('dataTable', 'loading').should.equal('Loading')
    hx.userFacingText('dataTable', 'noData').should.equal('No Data')
    hx.userFacingText('dataTable', 'noSort').should.equal('No Sort')
    hx.userFacingText('dataTable', 'or').should.equal('or')
    hx.userFacingText('dataTable', 'rowsPerPage').should.equal('Rows Per Page')
    hx.userFacingText('dataTable', 'search').should.equal('Search')
    hx.userFacingText('dataTable', 'selectedRows').should.equal('$selected of $total selected.')
    hx.userFacingText('dataTable', 'sortBy').should.equal('Sort By')

  describe 'global options', ->
    checkOption('collapsibleRenderer', [((d) -> d), ((d) -> d*2), ((d) -> d+'')])
    checkOption('compact', ['auto', true, false])
    checkOption('displayMode', ['paginate', 'all'])
    checkOption('feed', [hx.dataTable.objectFeed(noData), hx.dataTable.objectFeed(threeRowsData)])
    checkOption('filter', ['bob', 'aaaa', undefined])
    checkOption('advancedSearch', [[[{column: 'any', term: 'a'}]], [[{column: 'any', term: 'a'}, {column: 'any', term: 'b'}]], undefined])
    checkOption('filterEnabled', [true, false])
    checkOption('showAdvancedSearch', [true, false])
    checkOption('advancedSearchEnabled', [true, false])
    checkOption('showSearchAboveTable', [true, false])
    checkOption('noDataMessage', ['No Data', 'Wahooo! You successfully deleted everything.'])
    checkOption('pageSize', [10, 20, 666])
    checkOption('pageSizeOptions', [undefined, [5, 10, 20], [100, 200, 500]])
    checkOption('retainHorizontalScrollOnRender', [true, false])
    checkOption('retainVerticalScrollOnRender', [true, false])
    checkOption('rowCollapsibleLookup', [((d) -> d), ((d) -> d*2), ((d) -> d+'')])
    checkOption('rowEnabledLookup', [((d) -> d), ((d) -> d*2), ((d) -> d+'')])
    checkOption('rowIDLookup', [((d) -> d), ((d) -> d*2), ((d) -> d+'')])
    checkOption('rowSelectableLookup', [((d) -> d), ((d) -> d*2), ((d) -> d+'')])
    checkOption('selectEnabled', [true, false])
    checkOption('singleSelection', [true, false])
    checkOption('sort', [{column: 'name', direction: 'asc'}, {column: 'age', direction: 'desc'}, undefined])

  describe 'column options', ->
    checkColumnOption('allowHeaderWrap', [true, false])
    checkColumnOption('cellRenderer', [((d) -> d), ((d) -> d*2), ((d) -> d+'')])
    checkColumnOption('headerCellRenderer', [((d) -> d), ((d) -> d*2), ((d) -> d+'')])
    checkColumnOption('sortEnabled', [true, false])

  describe 'column only options', ->
    checkColumnOption('maxWidth', [10, 100], true)

  describe 'setter/getters', ->
    checkSetterGetter('renderSuppressed', [true, false])


  describe 'render', ->

    describe 'default options', ->
      testTable {}, undefined, (container, dt, options, data) ->
        it 'should have the correct headers', ->
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.hx-data-table-cell').text().should.eql(headers)
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.hx-data-table-sort-icon').size().should.equal(data.headers.length)

        it 'should have no checkboxes', ->
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.hx-data-table-checkbox').size().should.equal(0)
          container.select('.hx-sticky-table-header-top-left').select('thead').selectAll('.hx-data-table-checkbox').size().should.equal(0)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox').size().should.equal(0)

        it 'should not have the checkbox in the top left', ->
          container.select('.hx-sticky-table-header-top-left').selectAll('.hx-data-table-checkbox').size().should.equal(0)

        it 'should have the correct rows', ->
          rows = container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-row').nodes
          rows.length.should.equal(Math.min(dt.pageSize(), data.rows.length))
          hx.select(rows[0]).selectAll('td').selectAll('.hx-data-table-cell-key').text().should.eql(headers)
          hx.select(rows[0]).selectAll('td').selectAll('.hx-data-table-cell-value').text().should.eql(['Bob', '25', 'Developer'])
          hx.select(rows[1]).selectAll('td').selectAll('.hx-data-table-cell-key').text().should.eql(headers)
          hx.select(rows[1]).selectAll('td').selectAll('.hx-data-table-cell-value').text().should.eql(['Jan', '41', 'Artist'])
          hx.select(rows[2]).selectAll('td').selectAll('.hx-data-table-cell-key').text().should.eql(headers)
          hx.select(rows[2]).selectAll('td').selectAll('.hx-data-table-cell-value').text().should.eql(['Dan', '41', 'Builder'])

        it 'should not show the search above the table', ->
          container.classed('hx-data-table-show-search-above-content').should.equal(false)

        it 'should not show the bottom control panel', ->
          container.select('.hx-data-table-control-panel-bottom-visible').empty().should.equal(true)

        it 'should show the control panel', ->
          container.select('.hx-data-table-control-panel-visible').empty().should.equal(false)

        it 'should not show the paginator', ->
          container.selectAll('.hx-data-table-paginator-visible').size().should.equal(0)

        it 'should not show the row per page picker', ->
          container.selectAll('.hx-data-table-page-size').size().should.equal(2)
          container.selectAll('.hx-data-table-page-size-visible').size().should.equal(0)

        it 'should show the filter box', ->
          container.select('.hx-data-table-filter').size().should.equal(1)
          container.select('.hx-data-table-filter').classed('hx-data-table-filter-visible').should.equal(true)

        it 'should not show collapsible expand icons', ->
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-collapsible-toggle').size().should.equal(0)

        it 'should not show the no data row when there is data', ->
          container.select('.hx-data-table-row-no-data').size().should.equal(0)

        it 'should have no disabled rows', ->
          container.selectAll('.hx-data-table-row-disabled').size().should.equal(0)



    describe 'allowHeaderWrap', ->
      it 'should add the allowHeaderWrap class to all columns when enabled by default', (done) ->
        tableOptions =
          allowHeaderWrap: true
        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').selectAll('.hx-table-header-allow-wrap').size().should.equal(3)

      it 'should allow allowHeaderWrap for individual columns', (done) ->
        tableOptions =
          columns:
            name:
              allowHeaderWrap: true
            age:
              allowHeaderWrap: false
            profession:
              allowHeaderWrap: false

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').selectAll('.hx-table-header-allow-wrap').size().should.equal(1)

      it 'should override default allowHeaderWrap when defined for a column', (done) ->
        tableOptions =
          allowHeaderWrap: true
          columns:
            name:
              allowHeaderWrap: false

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').selectAll('.hx-table-header-allow-wrap').size().should.equal(2)



    describe 'cellRenderer', ->
      it 'should call the cellRenderer', (done) ->
        tableOptions =
          cellRenderer: (elem) -> hx.select(elem).classed('bob', true)
        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-wrapper').select('tbody').select('.hx-data-table-row').selectAll('.bob').size().should.equal(3)

      it 'should call the cellRenderer for individual columns', (done) ->
        tableOptions =
          columns:
            name:
              cellRenderer: (elem) -> hx.select(elem).classed('bob', true)
            age:
              cellRenderer: (elem) -> hx.select(elem).classed('dave', true)
            profession:
              cellRenderer: (elem) -> hx.select(elem).classed('steve', true)

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-wrapper').select('tbody').select('.hx-data-table-row').selectAll('.bob').size().should.equal(1)
          container.select('.hx-sticky-table-wrapper').select('tbody').select('.hx-data-table-row').selectAll('.dave').size().should.equal(1)
          container.select('.hx-sticky-table-wrapper').select('tbody').select('.hx-data-table-row').selectAll('.steve').size().should.equal(1)

      it 'should use a column cellRenderer instead of the default cellRenderer if one is defined', (done) ->
        tableOptions =
          cellRenderer: (elem) -> hx.select(elem).classed('kate', true)
          columns:
            name:
              cellRenderer: (elem) -> hx.select(elem).classed('bob', true)

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-wrapper').select('tbody').select('.hx-data-table-row').selectAll('.bob').size().should.equal(1)
          container.select('.hx-sticky-table-wrapper').select('tbody').select('.hx-data-table-row').selectAll('.kate').size().should.equal(2)



    describe 'collapsibleRenderer', ->
      tableOptions = {
        collapsibleRenderer: (elem) -> hx.select(elem).class('bob').text('dave')
        rowCollapsibleLookup: (row) -> true
      }

      testTable {tableOptions}, undefined, (container, dt, options, data) ->
        it 'should show collapsible expand icons', ->
          container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-collapsible-toggle').size().should.equal(data.rows.length)

        it 'should render collapsible rows correctly when toggling with the button', ->
          handlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-collapsible-toggle')
            .nodes.map(testHelpers.fakeNodeEvent)

          handlers[0](fakeEvent)
          container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-collapsible-content-row').size().should.equal(1)
          container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-collapsible-content-row').size().should.equal(1)
          container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.bob').size().should.equal(1)

          handlers[1](fakeEvent)
          container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-collapsible-content-row').size().should.equal(2)
          container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-collapsible-content-row').size().should.equal(2)
          container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.bob').size().should.equal(2)



    describe 'expandedRows', ->
      it "should not open a row that doesn't pass the rowCollapsibleLookup check", (done) ->
        tableOptions = {
          collapsibleRenderer: (element, d) -> hx.select(element).class('bob')
          rowCollapsibleLookup: (row) -> !!row.collapsible
        }
        testTable {tableOptions}, done, (container, dt, options, data) ->
          dt.expandedRows ['0', '1'], ->
            container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-collapsible-content-row').size().should.equal(1)
            container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-collapsible-content-row').size().should.equal(1)
            container.select('.hx-sticky-table-wrapper').selectAll('.bob').size().should.equal(1)

      it "should get the correct row id's", (done) ->
        tableOptions = {
          collapsibleRenderer: (element, d) -> hx.select(element).class('bob')
          rowCollapsibleLookup: (row) -> !!row.collapsible
        }
        testTable {tableOptions}, done, (container, dt, options, data) ->
          dt.expandedRows().should.eql([])

          clickHandlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-collapsible-toggle')
            .nodes.map(testHelpers.fakeNodeEvent)

          clickHandlers.forEach (h) -> h?() # open all collapsibles
          dt.expandedRows().should.eql(['0', '2'])

          clickHandlers[0](fakeEvent) # close first collapsible
          dt.expandedRows().should.eql(['2'])

          clickHandlers[2](fakeEvent) # close second collapsible
          clickHandlers[0](fakeEvent) # open first collapsible
          dt.expandedRows().should.eql(['0'])



    describe 'compact', ->
      describe 'auto', ->
        it 'should display in desktop mode when the width is greater than 480', (done) ->
          testTable {tableOptions: {compact: 'auto'}}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-compact').should.equal(false)

        it 'should display in compact mode when the width is less than 480', (done) ->
          testTable {containerWidth: 470, tableOptions: {compact: 'auto'}}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-compact').should.equal(true)

      describe 'true', ->
        it 'should always display in compact mode', (done) ->
          testTable {tableOptions: {compact: true}}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-compact').should.equal(true)

      describe 'false', ->
        it 'should always display in desktop mode', (done) ->
          testTable {containerWidth: 470, tableOptions: {compact: false}}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-compact').should.equal(false)



    describe 'displayMode', ->
      describe 'paginate', ->
        testTable {tableOptions: {displayMode: 'paginate'}}, undefined, (container, dt, options, data) ->
          it 'should not show the paginator when there is one page', ->
            dt._.numPages.should.equal(1)
            container.selectAll('.hx-data-table-paginator-visible').size().should.equal(0)

        it 'should show the paginator when there is more than one page', (done) ->
          testTable {tableOptions: {displayMode: 'paginate', pageSize: 1}}, done, (container, dt, options, data) ->
            container.selectAll('.hx-data-table-paginator-visible').size().should.equal(3)
            dt._.numPages.should.equal(3)

        it 'should change the page when the picker is changed', (done) ->
          testTable {tableOptions: {displayMode: 'paginate', pageSize: 1}}, undefined, (container, dt, options, data) ->
            dt.on 'render', ->
              dt.page().should.equal(2)
              hx.select('body').clear()
              done()

            container
              .select('.hx-data-table-paginator-picker')
              .component()
              .emit('change', {value: {value: 2}, cause: 'user'})

        it 'should change the page when the back button is clicked', (done) ->
          testTable {tableOptions: {displayMode: 'paginate', pageSize: 1}}, undefined, (container, dt, options, data) ->
            dt.page(2)
            dt.on 'render', ->
              dt.page().should.equal(1)
              hx.select('body').clear()
              done()

            testHelpers.fakeNodeEvent(container.select('.hx-data-table-paginator-back').node())(fakeEvent)

        it 'should change the page when the forward button is clicked', (done) ->
          testTable {tableOptions: {displayMode: 'paginate', pageSize: 1}}, undefined, (container, dt, options, data) ->
            dt.on 'render', ->
              dt.page().should.equal(2)
              hx.select('body').clear()
              done()

            testHelpers.fakeNodeEvent(container.select('.hx-data-table-paginator-forward').node())(fakeEvent)

        it 'should not change the page when the back button is disabled', (done) ->
          testTable {tableOptions: {displayMode: 'paginate', pageSize: 1}}, undefined, (container, dt, options, data) ->
            dt.render = chai.spy()
            testHelpers.fakeNodeEvent(container.select('.hx-data-table-paginator-back').node())(fakeEvent)
            dt.page().should.equal(1)
            dt.render.should.not.have.been.called()
            hx.select('body').clear()
            done()

        it 'should not change the page when the forward button is disabled', (done) ->
          testTable {tableOptions: {displayMode: 'paginate', pageSize: 1}}, undefined, (container, dt, options, data) ->
            dt.page(dt._.numPages)
            dt.render = chai.spy()
            testHelpers.fakeNodeEvent(container.select('.hx-data-table-paginator-forward').node())(fakeEvent)
            dt.page().should.equal(dt._.numPages)
            dt.render.should.not.have.been.called()
            hx.select('body').clear()
            done()

      describe 'all', ->
        it 'should hide the paginator block', (done) ->
          testTable {tableOptions: {displayMode: 'all', pageSize: 1}}, done, (container, dt, options, data) ->
            should.not.exist(dt._.numPages)
            container.selectAll('.hx-data-table-paginator-visible').size().should.equal(0)
            container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('tr').size().should.equal(3)



    describe 'filterEnabled', ->
      describe 'true', ->
        it 'should show the filter box', (done) ->
          testTable {tableOptions: {filterEnabled: true}}, done, (container, dt, options, data) ->
            container.select('.hx-data-table-filter').size().should.equal(1)
            container.select('.hx-data-table-filter').classed('hx-data-table-filter-visible').should.equal(true)

      describe 'false', ->
        it 'should not show the filter box', (done) ->
          testTable {tableOptions: {filterEnabled: false}}, done, (container, dt, options, data) ->
            container.select('.hx-data-table-filter').size().should.equal(1)
            container.select('.hx-data-table-filter').classed('hx-data-table-filter-visible').should.equal(false)



    describe 'headerCellRenderer', ->
      it 'should call the headerCellRenderer', (done) ->
        tableOptions =
          headerCellRenderer: (elem) -> hx.select(elem).classed('bob', true)
        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.bob').size().should.equal(3)

      it 'should call the headerCellRenderer for individual columns', (done) ->
        tableOptions =
          columns:
            name:
              headerCellRenderer: (elem) -> hx.select(elem).classed('bob', true)
            age:
              headerCellRenderer: (elem) -> hx.select(elem).classed('dave', true)
            profession:
              headerCellRenderer: (elem) -> hx.select(elem).classed('steve', true)

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.bob').size().should.equal(1)
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.dave').size().should.equal(1)
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.steve').size().should.equal(1)

      it 'should use a column headerCellRenderer instead of the default headerCellRenderer if one is defined', (done) ->
        tableOptions =
          headerCellRenderer: (elem) -> hx.select(elem).classed('kate', true)
          columns:
            name:
              headerCellRenderer: (elem) -> hx.select(elem).classed('bob', true)

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.bob').size().should.equal(1)
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.kate').size().should.equal(2)



    describe 'noDataMessage', ->
      it 'should have the right value for the no data message', (done) ->
        testTable {data: noData, tableOptions: {noDataMessage: 'no data to display'}}, done, (container, dt, options, data) ->
          container.select('.hx-data-table-row-no-data').text().should.equal(dt.noDataMessage())



    describe 'page', ->
      testTable {tableOptions: {pageSize: 1}}, undefined, (container, dt, options, data) ->
        it 'should set and get the visible page', ->
          dt._.numPages.should.equal(3)
          dt.page(2).page().should.equal(2)

        it 'should not set the page to be less than 0', ->
          dt.page(-5).page().should.equal(1)

        it 'should not set the page to be greater than the number of pages', ->
          dt._.numPages.should.equal(3)
          dt.page(20).page().should.equal(3)

      it 'changing the page should change the visible data', (done) ->
        testTable {tableOptions: {pageSize: 1}}, done, (container, dt, options, data) ->
          rows = container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-row').nodes
          hx.select(rows[0]).selectAll('td').selectAll('.hx-data-table-cell-key').text().should.eql(headers)
          hx.select(rows[0]).selectAll('td').selectAll('.hx-data-table-cell-value').text().should.eql(['Bob', '25', 'Developer'])

          dt.page 2, ->
            rows = container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-row').nodes
            hx.select(rows[0]).selectAll('td').selectAll('.hx-data-table-cell-key').text().should.eql(headers)
            hx.select(rows[0]).selectAll('td').selectAll('.hx-data-table-cell-value').text().should.eql(['Jan', '41', 'Artist'])

      it 'the renderer should correct the page number if it is greater than the data', (done) ->
        dt = new hx.DataTable(hx.detached('div').node())
        dt.page(10)
        hx.consoleWarning.should.have.been.called()
        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          dt.page().should.equal(1)
          done()



    describe 'pageSize', ->
      it 'should show the correct number of rows on a page', (done) ->
        testTable {tableOptions: {pageSize: 1}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-row').size().should.equal(1)
          dt._.numPages.should.equal(3)

      it 'should only have pages if there is data to go on them', (done) ->
        testTable {tableOptions: {pageSize: 30}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('.hx-data-table-row').size().should.equal(3)
          dt._.numPages.should.equal(1)



    describe 'pageSizeOptions', ->
      it 'should not show the row per page picker by default', (done) ->
        testTable {tableOptions: {pageSizeOptions: undefined}}, done, (container, dt, options, data) ->
          container.selectAll('.hx-data-table-page-size').size().should.equal(2)
          container.selectAll('.hx-data-table-page-size-visible').size().should.equal(0)

      testTable {tableOptions: {pageSizeOptions: [4, 1, 3, 2]}}, undefined, (container, dt, options, data) ->
        it 'should show the rows per page picker', ->
          container.selectAll('.hx-data-table-page-size').size().should.equal(2)
          container.selectAll('.hx-data-table-page-size-visible').size().should.equal(2)

        it 'should sort the options in numeric order', ->
          dt.pageSizeOptions().should.eql([1, 2, 3, 4, 15])

        it 'should add the pageSize as an option when its not in the array', ->
          dt.pageSizeOptions().indexOf(15).should.not.equal(-1)

      it 'should change the page size when the picker value is changed', (done) ->
        testTable {tableOptions: {pageSizeOptions: [4, 1, 3, 2]}}, undefined, (container, dt, options, data) ->
          dt.on 'render', ->
            container.select('.hx-sticky-table-wrapper').select('tbody').selectAll('tr').size().should.equal(1)
            dt.pageSize().should.equal(1)
            hx.select('body').clear()
            done()

          container
            .select('.hx-data-table-page-size-picker')
            .component()
            .emit('change', {value: {value: 1, text: '1'}, cause: 'user'})

      it 'should not add the pageSize as an option if it is in the array', (done) ->
        testTable {tableOptions: {pageSizeOptions: [5, 10, 15]}}, done, (container, dt, options, data) ->
          dt.pageSizeOptions().should.eql([5, 10, 15])



    if navigator.userAgent.toLowerCase().indexOf('phantom') is -1
      # Phantom doesn't work properly with the styles so browsers should check this works correctly.
      describe 'retainHorizontalScrollOnRender', ->
        describe 'true', ->
          it 'should restore the horizontal scroll when re-rendering', (done) ->
            tableOpts = {containerWidth: 100, tableOptions: {compact: false, retainHorizontalScrollOnRender: true, retainVerticalScrollOnRender: false}}
            testTable tableOpts, done, (container, dt, options, data) ->
              container.select('.hx-sticky-table-wrapper').node().scrollLeft = 5
              container.select('.hx-sticky-table-wrapper').node().scrollLeft.should.equal(5)
              dt.render()
              container.select('.hx-sticky-table-wrapper').node().scrollLeft.should.equal(5)


        describe 'false', ->
          it 'should not restore the horizontal scroll when re-rendering', (done) ->
            tableOpts = {containerWidth: 100, tableOptions: {compact: false, retainHorizontalScrollOnRender: false, retainVerticalScrollOnRender: false}}
            testTable tableOpts, done, (container, dt, options, data) ->
              container.select('.hx-sticky-table-wrapper').node().scrollLeft = 5
              container.select('.hx-sticky-table-wrapper').node().scrollLeft.should.equal(5)
              dt.render()
              container.select('.hx-sticky-table-wrapper').node().scrollLeft.should.equal(0)



      describe 'retainVerticalScrollOnRender', ->
        describe 'true', ->
          it 'should restore the vertical scroll when re-rendering', (done) ->
            tableOpts = {containerHeight: 100, tableOptions: {compact: false, retainHorizontalScrollOnRender: false, retainVerticalScrollOnRender: true}}
            testTable tableOpts, done, (container, dt, options, data) ->
              container.select('.hx-sticky-table-wrapper').node().scrollTop = 5
              container.select('.hx-sticky-table-wrapper').node().scrollTop.should.equal(5)
              dt.render()
              container.select('.hx-sticky-table-wrapper').node().scrollTop.should.equal(5)

        describe 'false', ->
          it 'should not restore the vertical scroll when re-rendering', (done) ->
            tableOpts = {containerHeight: 100, tableOptions: {compact: false, retainHorizontalScrollOnRender: false, retainVerticalScrollOnRender: false}}
            testTable tableOpts, done, (container, dt, options, data) ->
              container.select('.hx-sticky-table-wrapper').node().scrollTop = 5
              container.select('.hx-sticky-table-wrapper').node().scrollTop.should.equal(5)
              dt.render()
              container.select('.hx-sticky-table-wrapper').node().scrollTop.should.equal(0)



    describe 'rowCollapsibleLookup', ->
      it 'should show the icons correctly', (done) ->
        testTable {tableOptions: {collapsibleRenderer: (->), rowCollapsibleLookup: ((row) -> !!row.collapsible)}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-collapsible-toggle').size().should.equal(3)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-collapsible-disabled').size().should.equal(1)



    describe 'rowEnabledLookup', ->
      it 'should show rows as disabled', (done) ->
        testTable {tableOptions: {rowEnabledLookup: ((row) -> !row.collapsible)}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-disabled').size().should.equal(2)



    describe 'rowSelectableLookup', ->
      it 'should allow all rows to be selected by default', (done) ->
        testTable {tableOptions: {selectEnabled: true}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox')
            .nodes.map(testHelpers.fakeNodeEvent)
            .forEach (h) -> h?(fakeEvent)

          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(3)

      it 'should prevent rows being selected', (done) ->
        testTable {tableOptions: {selectEnabled: true, rowSelectableLookup: ((row) -> !row.collapsible)}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox')
            .nodes.map(testHelpers.fakeNodeEvent)
            .forEach (h) -> h?(fakeEvent)

          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)



    describe 'selectedRows', ->
      it 'should be possible for the user to deselect a row selected by the api', (done) ->
        feed = hx.dataTable.objectFeed
          headers: [
            name: 'Name'
            id: 'name'
          ]
          rows: [
            id: 0
            cells:
              name: 'Bob'
          ]
        tableSel = hx.detached 'div'
        tableOpts =
          feed: feed
          singleSelection: true
          selectEnabled: true
        table = new hx.DataTable tableSel.node(), tableOpts
        table.selectedRows [0]

        table.on 'selectedrowschange', (data) ->
          if data.cause is 'user'
            # Row 0 was selected before, so now we're unselecting it
            data.value.should.eql []
            done()
        checkSel = tableSel.select '.hx-sticky-table-wrapper .hx-data-table-checkbox'
        faker = testHelpers.fakeNodeEvent checkSel.node()
        faker fakeEvent


      it "should be able to unselect rows having selected them, when singleSelection is enabled", (done) ->
        testTable {tableOptions: {selectEnabled: true, singleSelection: true}}, done, (container, dt, options, data) ->
          dt.selectedRows ['0'], ->
            dt.selectedRows [], ->
              dt.selectedRows().should.eql([])

      it 'should select rows by id', (done) ->
        testTable {tableOptions: {selectEnabled: true}}, done, (container, dt, options, data) ->
          dt.selectedRows ['0', '1'], ->
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(2)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(2)
            container.remove()

      it 'should get the correct row ids from the selection', (done) ->
        testTable {tableOptions: {selectEnabled: true}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox')
            .nodes.map(testHelpers.fakeNodeEvent)
            .forEach (h) -> h?(fakeEvent)

          dt.selectedRows().should.eql(['0', '1', '2'])

      it 'should get the correct row ids from the selection', (done) ->
        testTable {tableOptions: {selectEnabled: true}}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox')
            .nodes.map(testHelpers.fakeNodeEvent)
            .forEach (h) -> h?(fakeEvent)

          dt.selectedRows().should.eql(['0', '1', '2'])

      it 'should only select one item when singleSelection is enabled', (done) ->
        testTable {tableOptions: {selectEnabled: true, singleSelection: true}}, done, (container, dt, options, data) ->
          dt.selectedRows ['0', '1'], ->
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(1)

      it 'should emit an event when the value is changed via the api', (done) ->
        dt = new hx.DataTable(hx.detached('div').node(), {selectEnabled: true, feed: hx.dataTable.objectFeed(threeRowsData)})
        dt.on 'selectedrowschange', (d) ->
          d.value.should.eql(['0', '1'])
          d.cause.should.equal('api')
          done()

        dt.selectedRows(['0', '1'])



    describe 'selectEnabled', ->
      testTable {tableOptions: selectEnabled: true}, undefined, (container, dt, options, data) ->
        it 'should have checkboxes', ->
          container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox').size().should.equal(3)

        it 'should have the checkbox in the top left', ->
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.hx-data-table-checkbox').size().should.equal(1)
          container.select('.hx-sticky-table-header-top-left').select('thead').selectAll('.hx-data-table-checkbox').size().should.equal(1)

      it 'should select all the rows when clicking the checkbox in the top left', (done) ->
        testTable {tableOptions: selectEnabled: true}, done, (container, dt, options, data) ->
          selectAllHandler = testHelpers.fakeNodeEvent container.select('.hx-sticky-table-header-top-left').select('thead').select('.hx-data-table-checkbox').node()

          container.classed('hx-data-table-has-page-selection').should.equal(false)
          container.classed('hx-data-table-has-selection').should.equal(false)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

          selectAllHandler(fakeEvent)
          container.classed('hx-data-table-has-page-selection').should.equal(true)
          container.classed('hx-data-table-has-selection').should.equal(true)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(3)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(3)

          selectAllHandler(fakeEvent)
          container.classed('hx-data-table-has-page-selection').should.equal(false)
          container.classed('hx-data-table-has-selection').should.equal(false)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

      it 'should clear the selection when the (clear selection) link is clicked', (done) ->
        testTable {tableOptions: selectEnabled: true}, done, (container, dt, options, data) ->
          selectAllHandler = testHelpers.fakeNodeEvent container.select('.hx-sticky-table-header-top-left').select('thead').select('.hx-data-table-checkbox').node()

          container.classed('hx-data-table-has-page-selection').should.equal(false)
          container.classed('hx-data-table-has-selection').should.equal(false)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

          selectAllHandler(fakeEvent)
          container.classed('hx-data-table-has-page-selection').should.equal(true)
          container.classed('hx-data-table-has-selection').should.equal(true)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(3)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(3)

          clearSelectionHandler = testHelpers.fakeNodeEvent container.select('.hx-data-table-status-bar').select('.hx-data-table-status-bar-clear').node()

          clearSelectionHandler(fakeEvent)
          container.classed('hx-data-table-has-page-selection').should.equal(false)
          container.classed('hx-data-table-has-selection').should.equal(false)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

      it 'should not break when clicking the top left tick with no data', (done) ->
        testTable {data: noData, tableOptions: selectEnabled: true}, done, (container, dt, options, data) ->
          selectAllHandler = testHelpers.fakeNodeEvent container.select('.hx-sticky-table-header-top').select('thead').select('.hx-data-table-checkbox').node()

          container.classed('hx-data-table-has-page-selection').should.equal(false)
          container.classed('hx-data-table-has-selection').should.equal(false)

          selectAllHandler(fakeEvent)
          container.classed('hx-data-table-has-page-selection').should.equal(false)
          container.classed('hx-data-table-has-selection').should.equal(false)

      it 'should not allow disabled rows to be selected', ->
        it 'should select the correct range from top to bottom', (done) ->
          testTable {tableOptions: selectEnabled: true, rowEnabledLookup: (row) -> !row.collapsible}, done, (container, dt, options, data) ->
            clickHandlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox')
              .nodes.map(testHelpers.fakeNodeEvent)

            container.classed('hx-data-table-has-page-selection').should.equal(false)
            container.classed('hx-data-table-has-selection').should.equal(false)

            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

            clickHandlers[0](fakeEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

      it 'should toggle the row when clicked twice', ->
        it 'should select the correct range from top to bottom', (done) ->
          testTable {tableOptions: selectEnabled: true}, done, (container, dt, options, data) ->
            clickHandlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox')
              .nodes.map(testHelpers.fakeNodeEvent)

            container.classed('hx-data-table-has-page-selection').should.equal(false)
            container.classed('hx-data-table-has-selection').should.equal(false)

            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

            clickHandlers[0](fakeEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(1)

            clickHandlers[0](fakeEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)


      describe 'shift selection', ->
        it 'should select the correct range from top to bottom', (done) ->
          testTable {tableOptions: selectEnabled: true}, done, (container, dt, options, data) ->
            clickHandlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox')
              .nodes.map(testHelpers.fakeNodeEvent)

            container.classed('hx-data-table-has-page-selection').should.equal(false)
            container.classed('hx-data-table-has-selection').should.equal(false)

            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

            clickHandlers[0](fakeEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(1)

            clickHandlers[2](fakeShiftEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(3)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(3)

        it 'should select the correct range from bottom to top', (done) ->
          testTable {tableOptions: selectEnabled: true}, done, (container, dt, options, data) ->
            clickHandlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox')
              .nodes.map(testHelpers.fakeNodeEvent)

            container.classed('hx-data-table-has-page-selection').should.equal(false)
            container.classed('hx-data-table-has-selection').should.equal(false)

            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

            clickHandlers[2](fakeEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(1)

            clickHandlers[0](fakeShiftEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(3)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(3)

        it 'should not allow unselectable rows to be selected', (done) ->
          testTable {tableOptions: selectEnabled: true, rowSelectableLookup: (row) -> !!row.collapsible}, done, (container, dt, options, data) ->
            clickHandlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox')
              .nodes.map(testHelpers.fakeNodeEvent)

            container.classed('hx-data-table-has-page-selection').should.equal(false)
            container.classed('hx-data-table-has-selection').should.equal(false)

            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

            clickHandlers[0](fakeEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(1)

            clickHandlers[2](fakeShiftEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(2)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(2)

        it 'should not allow disabled rows to be selected', (done) ->
          testTable {tableOptions: selectEnabled: true, rowEnabledLookup: (row) -> !!row.collapsible}, done, (container, dt, options, data) ->
            clickHandlers = container.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox')
              .nodes.map(testHelpers.fakeNodeEvent)

            container.classed('hx-data-table-has-page-selection').should.equal(false)
            container.classed('hx-data-table-has-selection').should.equal(false)

            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(0)

            clickHandlers[0](fakeEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(1)

            clickHandlers[2](fakeShiftEvent)
            container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(2)
            container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-row-selected').size().should.equal(2)


        it 'should class the container correctly when pressing shift to prevent text selection', (done) ->
          testTable {tableOptions: selectEnabled: true}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-disable-text-selection').should.equal(false)
            shiftDownHandler = testHelpers.fakeNodeEvent hx.select('body').node(), 'keydown'
            shiftUpHandler = testHelpers.fakeNodeEvent hx.select('body').node(), 'keyup'
            shiftDownHandler(fakeShiftEvent)
            container.classed('hx-data-table-disable-text-selection').should.equal(true)
            shiftUpHandler(fakeEvent)
            container.classed('hx-data-table-disable-text-selection').should.equal(false)



    describe 'singleSelection', ->
      testTable {tableOptions: selectEnabled: true, singleSelection: true}, undefined, (container, dt, options, data) ->
        it 'should have checkboxes', ->
          container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox').size().should.equal(3)

        it 'should not have the checkbox in the top left', ->
          container.select('.hx-sticky-table-header-top').select('thead').selectAll('.hx-data-table-checkbox').size().should.equal(0)
          container.select('.hx-sticky-table-header-top-left').select('thead').selectAll('.hx-data-table-checkbox').size().should.equal(0)

        it 'should only allow one row to be selected', ->
          clickHandlers = container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox')
            .nodes.map(testHelpers.fakeNodeEvent)

          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)

          clickHandlers[0](fakeEvent)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)

          clickHandlers[1](fakeEvent)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)

          clickHandlers[1](fakeEvent)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)

      it 'should only select the new row on shift selection', (done) ->
        testTable {tableOptions: selectEnabled: true, singleSelection: true}, done, (container, dt, options, data) ->
          clickHandlers = container.select('.hx-sticky-table-header-left').selectAll('.hx-data-table-checkbox')
            .nodes.map(testHelpers.fakeNodeEvent)

          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(0)

          clickHandlers[0](fakeEvent)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)

          clickHandlers[1](fakeShiftEvent)
          container.select('.hx-sticky-table-wrapper').selectAll('.hx-data-table-row-selected').size().should.equal(1)



    describe 'sortEnabled', ->
      it 'should add the sort icons correctly', (done) ->
        testTable {tableOptions: sortEnabled: true}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').selectAll('.hx-data-table-sort-icon').size().should.equal(3)

      it 'should add the sort icons correctly for individual columns', (done) ->
        tableOptions =
          columns:
            name:
              sortEnabled: true
            age:
              sortEnabled: false
            profession:
              sortEnabled: false

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').selectAll('.hx-data-table-sort-icon').size().should.equal(1)

      it 'should use a column sortEnabled instead of the default sortEnabled if one is defined', (done) ->
        tableOptions =
          sortEnabled: false
          columns:
            name:
              sortEnabled: true

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-header-top').selectAll('.hx-data-table-sort-icon').size().should.equal(1)

      it 'should change the sort when clicking a sort icon', (done) ->
        testTable {tableOptions: sortEnabled: true}, done, (container, dt, options, data) ->
          clickHandlers = container.select('.hx-sticky-table-header-top').selectAll('.hx-data-table-cell-sort-enabled')
            .nodes.map(testHelpers.fakeNodeEvent)

          should.not.exist(dt.sort())

          clickHandlers[0](fakeEvent)
          dt.sort().should.eql({column: 'name', direction: 'asc'})

          clickHandlers[0](fakeEvent)
          dt.sort().should.eql({column: 'name', direction: 'desc'})

          clickHandlers[0](fakeEvent)
          dt.sort().should.eql({column: undefined, direction: undefined})

          clickHandlers[0](fakeEvent)
          dt.sort().should.eql({column: 'name', direction: 'asc'})

          clickHandlers[1](fakeEvent)
          dt.sort().should.eql({column: 'age', direction: 'asc'})

      describe 'compact mode', ->
        it 'should show the compact control panel for default options', ->
          testTable {tableOptions: {compact: true}}, undefined, (container, dt, options, data) ->
            container.select('.hx-data-table-control-panel-compact-visible').empty().should.equal(false)

        it 'should not show the sort control if there are no sorts', ->
          testTable {tableOptions: {compact: true, sortEnabled: false}}, undefined, (container, dt, options, data) ->
            container.select('.hx-data-table-sort').classed('hx-data-table-sort-visible').should.equal(false)

        it 'should show the sort control if sort is only enabled for one column ', ->
          testTable {tableOptions: {compact: true, sortEnabled: false, columns: {name: {sortEnabled: true}}}}, undefined, (container, dt, options, data) ->
            container.select('.hx-data-table-sort').classed('hx-data-table-sort-visible').should.equal(true)

        it 'should change the sort column when changing the sort picker', (done) ->
          testTable {tableOptions: {compact: true}}, undefined, (container, dt, options, data) ->
            pickerNode = container.select('.hx-data-table-sort')
              .select('.hx-picker').node()

            pickerExpectation = ->
              dt.sort().should.eql({column: 'name', direction: 'asc'})

            emulatePickerValueChange(pickerNode, dt, 1, done, pickerExpectation)

        it 'should remove the sort when the sort column is set to no sort', (done) ->
          tableOptions =
            compact: true
            sort: {column: 'name', direction: 'asc'}

          testTable {tableOptions}, undefined, (container, dt, options, data) ->
            pickerNode = container.select('.hx-data-table-sort')
              .select('.hx-picker').node()

            pickerExpectation = ->
              dt.sort().should.eql({column: undefined, direction: undefined})

            emulatePickerValueChange(pickerNode, dt, 0, done, pickerExpectation)



    describe 'maxWidth', ->
      it 'should set the max width for individual columns', (done) ->
        tableOptions =
          columns:
            name:
              maxWidth: 10

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-sticky-table-wrapper').select('tbody').select('tr').selectAll('td').forEach (cell, index) ->
            if index is 0
              cell.attr('style').should.equal('max-width: 10px; width: 10px; min-width: 10px; ')
            else
              should.not.exist(cell.attr('style'))



    describe 'sort', ->
      it 'should call the feed with the correct arguments', (done) ->
        dt = new hx.DataTable(hx.detached('div').node())
        feed = hx.dataTable.objectFeed(threeRowsData)
        headersSpy = chai.spy.on(feed, 'headers')
        totalCountSpy = chai.spy.on(feed, 'totalCount')
        rowsSpy = chai.spy.on(feed, 'rows')
        dt.feed(feed)
        dt.sort {column: 'age', direction: 'asc'}, ->
          headersSpy.should.have.been.called()
          totalCountSpy.should.have.been.called()
          rowsSpy.should.have.been.called()
          rowsSpy.should.have.been.called.with({ start: 0, end: 14, sort: {column: 'age', direction: 'asc'}, filter: undefined, advancedSearch: undefined, useAdvancedSearch: false })
          done()



    describe 'filter', ->
      it 'should call the feed with the correct arguments', (done) ->
        dt = new hx.DataTable(hx.detached('div').node())
        feed = hx.dataTable.objectFeed(threeRowsData)
        headersSpy = chai.spy.on(feed, 'headers')
        totalCountSpy = chai.spy.on(feed, 'totalCount')
        rowsSpy = chai.spy.on(feed, 'rows')
        dt.feed(feed)
        dt.filter 'filter-term', ->
          headersSpy.should.have.been.called()
          totalCountSpy.should.have.been.called()
          rowsSpy.should.have.been.called()
          rowsSpy.should.have.been.called.with({ start: 0, end: 14, sort: undefined, filter: 'filter-term', advancedSearch: undefined, useAdvancedSearch: false })
          done()

      it 'should call filter when changing the filter input', (done) ->
        clock = sinon.useFakeTimers(clockTime)
        container = hx.detached('div')
        dt = new hx.DataTable(container.node())
        filterSpy = chai.spy.on(dt, 'filter')
        filterSpy.should.not.have.been.called()
        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          filterSpy.should.have.been.called.with()

          filterInput = container.select('.hx-data-table-filter')
          filterEvent = testHelpers.fakeNodeEvent filterInput.node(), 'input'
          filterInput.value('a')
          filterEvent(fakeEvent)
          clock.tick(inputDebounceDelay)
          filterSpy.should.have.been.called.with()
          filterSpy.should.have.been.called.with('a', undefined, 'user')
          clock.restore()
          done()



    describe 'showSearchAboveTable', ->
      it 'should add the correct class to the table', (done) ->
        # The re-ordering is done by CSS
        tableOptions =
          showSearchAboveTable: true

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.classed('hx-data-table-show-search-above-content').should.equal(true)
          container.select('.hx-data-table-control-panel-bottom-visible').size().should.equal(0)
          container.select('.hx-data-table-control-panel-visible').size().should.equal(1)

      it 'should show the bottom control panel if there are page size options', (done) ->
        # The re-ordering is done by CSS
        tableOptions =
          showSearchAboveTable: true
          pageSizeOptions: [1,2,3,4,5]

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.classed('hx-data-table-show-search-above-content').should.equal(true)
          container.select('.hx-data-table-control-panel-bottom-visible').size().should.equal(1)
          container.select('.hx-data-table-control-panel-visible').size().should.equal(1)

      it 'should show the bottom control panel if there are multiple pages', (done) ->
        # The re-ordering is done by CSS
        tableOptions =
          showSearchAboveTable: true
          pageSize: 1

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.classed('hx-data-table-show-search-above-content').should.equal(true)
          container.select('.hx-data-table-control-panel-bottom-visible').size().should.equal(1)
          container.select('.hx-data-table-control-panel-visible').size().should.equal(1)



    describe 'grouped headers', ->
      ### Expected structure
        |          TH            |                                   |
        |     MH1      |   MH2   |  MH2  |  MH1  |                   |
        |  BH1 |  BH2  |   BH2   |  BH   |  BH   |  BH  |     |  BH  |
      ###

      groupedHeaders = [
        { name: 'Col 1', id: 'c1', groups: ['BH1','MH1','TH']}
        { name: 'Col 2', id: 'c2', groups: ['BH2','MH1','TH']}
        { name: 'Col 3', id: 'c3', groups: ['BH2','MH2','TH']}
        { name: 'Col 4', id: 'c4', groups: ['BH','MH2']}
        { name: 'Col 5', id: 'c5', groups: ['BH','MH1']}
        { name: 'Col 6', id: 'c6', groups: ['BH']}
        { name: 'Col 7', id: 'c7'}
        { name: 'Col 8', id: 'c8', groups: ['BH']}
      ]

      groupedHeaderData = {
        headers: groupedHeaders
        rows: [
          {
            id: '0'
            cells: {'c1': 'a','c2': 'a','c3': 'a','c4': 'a','c5': 'a','c6': 'a','c7': 'a', 'c8': 'a'}
          }
        ]
      }

      groupedHeaderNoData = {
        headers: groupedHeaders
        rows: []
      }

      describe 'without data', ->

        it 'should render correctly', (done) ->
          testTable {data: groupedHeaderData, tableOptions: {}}, done, (container, dt, options, data) ->
            rows = container.select('.hx-sticky-table-header-top').select('thead').selectAll('tr')
            rows.size().should.equal(4)

            firstRow = hx.select(rows.nodes[0])
            secondRow = hx.select(rows.nodes[1])
            thirdRow = hx.select(rows.nodes[2])

            firstRow.selectAll('.hx-data-table-cell-grouped').size().should.equal(2)
            firstRow.selectAll('th').text().should.eql(['TH', ''])

            secondRow.selectAll('.hx-data-table-cell-grouped').size().should.equal(5)
            secondRow.selectAll('th').text().should.eql(['MH1', 'MH2', 'MH2', 'MH1', ''])

            thirdRow.selectAll('.hx-data-table-cell-grouped').size().should.equal(8)
            thirdRow.selectAll('th').text().should.eql(['BH1', 'BH2', 'BH2', 'BH', 'BH', 'BH', '', 'BH'])


        it 'should render correctly with selection enabled', (done) ->
          testTable {data: groupedHeaderData, tableOptions: {selectEnabled: true}}, done, (container, dt, options, data) ->
            rows = container.select('.hx-sticky-table-header-top').select('thead').selectAll('tr')
            rows.size().should.equal(4)
            rows.selectAll('.hx-data-table-control').size().should.equal(4)
            rows.selectAll('.hx-data-table-checkbox').size().should.equal(1)
            hx.select(rows.nodes[0]).selectAll('th').text().should.eql(['', 'TH', ''])
            hx.select(rows.nodes[1]).selectAll('th').text().should.eql(['', 'MH1', 'MH2', 'MH2', 'MH1', ''])
            hx.select(rows.nodes[2]).selectAll('th').text().should.eql(['', 'BH1', 'BH2', 'BH2', 'BH', 'BH', 'BH', '', 'BH'])

        it 'should render correctly with collapsibles enabled', (done) ->
          testTable {data: groupedHeaderData, tableOptions: {collapsibleRenderer: ->}}, done, (container, dt, options, data) ->
            rows = container.select('.hx-sticky-table-header-top').select('thead').selectAll('tr')
            rows.size().should.equal(4)
            rows.selectAll('.hx-data-table-control').size().should.equal(4)
            rows.selectAll('.hx-data-table-checkbox').size().should.equal(0)
            hx.select(rows.nodes[0]).selectAll('th').text().should.eql(['', 'TH', ''])
            hx.select(rows.nodes[1]).selectAll('th').text().should.eql(['', 'MH1', 'MH2', 'MH2', 'MH1', ''])
            hx.select(rows.nodes[2]).selectAll('th').text().should.eql(['', 'BH1', 'BH2', 'BH2', 'BH', 'BH', 'BH', '', 'BH'])

      describe 'with data', ->

        it 'should render correctly', (done) ->
          testTable {data: groupedHeaderData, tableOptions: {}}, done, (container, dt, options, data) ->
            rows = container.select('.hx-sticky-table-header-top').select('thead').selectAll('tr')
            rows.size().should.equal(4)

            firstRow = hx.select(rows.nodes[0])
            secondRow = hx.select(rows.nodes[1])
            thirdRow = hx.select(rows.nodes[2])

            firstRow.selectAll('.hx-data-table-cell-grouped').size().should.equal(2)
            firstRow.selectAll('th').text().should.eql(['TH', ''])

            secondRow.selectAll('.hx-data-table-cell-grouped').size().should.equal(5)
            secondRow.selectAll('th').text().should.eql(['MH1', 'MH2', 'MH2', 'MH1', ''])

            thirdRow.selectAll('.hx-data-table-cell-grouped').size().should.equal(8)
            thirdRow.selectAll('th').text().should.eql(['BH1', 'BH2', 'BH2', 'BH', 'BH', 'BH', '', 'BH'])

        it 'should render correctly with selection enabled', (done) ->
          testTable {data: groupedHeaderData, tableOptions: {selectEnabled: true}}, done, (container, dt, options, data) ->
            rows = container.select('.hx-sticky-table-header-top-left').select('thead').selectAll('tr')
            rows.size().should.equal(4)
            rows.selectAll('.hx-data-table-control').size().should.equal(4)
            rows.selectAll('.hx-data-table-checkbox').size().should.equal(1)
            hx.select(rows.nodes[0]).select('th').text().should.eql('')
            hx.select(rows.nodes[1]).select('th').text().should.eql('')
            hx.select(rows.nodes[2]).select('th').text().should.eql('')

        it 'should render correctly with collapsibles enabled', (done) ->
          testTable {data: groupedHeaderData, tableOptions: {collapsibleRenderer: ->}}, done, (container, dt, options, data) ->
            rows = container.select('.hx-sticky-table-header-top-left').select('thead').selectAll('tr')
            rows.size().should.equal(4)
            rows.selectAll('.hx-data-table-control').size().should.equal(4)
            rows.selectAll('.hx-data-table-checkbox').size().should.equal(0)
            hx.select(rows.nodes[0]).select('th').text().should.eql('')
            hx.select(rows.nodes[1]).select('th').text().should.eql('')
            hx.select(rows.nodes[2]).select('th').text().should.eql('')



    describe 'advanced search', ->
      describe 'advancedSearch', ->
        it 'should enable the advanced search filtering if passed in the options', (done) ->
          tableOptions =
            advancedSearch: [[{column: 'any', term: ''}]]

          testTable {tableOptions}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-show-search-above-content').should.equal(false)
            container.selectAll('.hx-data-table-control-panel-bottom-visible').size().should.equal(0)
            container.selectAll('.hx-data-table-control-panel-visible').size().should.equal(1)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(2)
            container.selectAll('.hx-data-table-filter-visible').size().should.equal(0)

      describe 'showAdvancedSearch', ->
        it 'should show the advanced search toggle when filters are enabled', (done) ->
          tableOptions =
            showAdvancedSearch: true

          testTable {tableOptions}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-show-search-above-content').should.equal(false)
            container.selectAll('.hx-data-table-control-panel-bottom-visible').size().should.equal(0)
            container.selectAll('.hx-data-table-control-panel-visible').size().should.equal(1)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(1)


        it 'should not show the advanced search toggle when filters are disabled', (done) ->
          tableOptions =
            showAdvancedSearch: true
            filterEnabled: false

          testTable {tableOptions}, done, (container, dt, options, data) ->
            container.classed('hx-data-table-show-search-above-content').should.equal(false)
            container.selectAll('.hx-data-table-control-panel-bottom-visible').size().should.equal(0)
            container.selectAll('.hx-data-table-control-panel-visible').size().should.equal(1)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(0)



      describe 'advancedSearchEnabled', ->
        it 'should not be enabled by default', (done) ->
          tableOptions =
            showAdvancedSearch: true

          testTable {tableOptions}, done, (container, dt, options, data) ->
            dt.advancedSearchEnabled().should.equal(false)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(1)
            container.selectAll('.hx-data-table-filter-visible').size().should.equal(1)


        it 'should default to being visible if enabled', (done) ->
          tableOptions =
            advancedSearchEnabled: true

          testTable {tableOptions}, done, (container, dt, options, data) ->
            dt.showAdvancedSearch().should.equal(true)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(2)
            container.selectAll('.hx-data-table-filter-visible').size().should.equal(0)


        it 'should hide the filter input when enabled', (done) ->
          tableOptions =
            advancedSearchEnabled: true

          testTable {tableOptions}, done, (container, dt, options, data) ->
            dt.advancedSearchEnabled().should.equal(true)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(2)
            container.selectAll('.hx-data-table-filter-visible').size().should.equal(0)

        it 'should toggle the advanced and regular filters correctly', (done) ->
          tableOptions =
            showAdvancedSearch: true

          testTable {tableOptions}, done, (container, dt, options, data) ->
            dt.advancedSearchEnabled().should.equal(false)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(1)
            container.selectAll('.hx-data-table-filter-visible').size().should.equal(1)

            testHelpers.fakeNodeEvent(container.select('.hx-data-table-advanced-search-toggle').node(), 'click')(fakeEvent)

            dt.advancedSearchEnabled().should.equal(true)
            container.selectAll('.hx-data-table-advanced-search-visible').size().should.equal(2)
            container.selectAll('.hx-data-table-filter-visible').size().should.equal(0)

      describe 'advancedSearch', ->
        it 'should render the advanced search correctly',(done) ->
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}], [{column: 'any', term: 'c'}]]

          testTable {tableOptions}, done, (container, dt, options, data) ->
            advancedSearchContainer = container.select('.hx-data-table-advanced-search-container')
            advancedSearchContainer.classed('hx-data-table-advanced-search-visible').should.equal(true)
            advancedSearchContainer.selectAll('.hx-data-table-advanced-search-filter-group').size().should.equal(2)
            filterRows = advancedSearchContainer.selectAll('.hx-data-table-advanced-search-filter')
            filterRows.size().should.equal(3)

            checkValue = (node, typePickerVal, columnPickerVal, termVal) ->
              elem = hx.select(node)
              if typePickerVal
                elem.select('.hx-data-table-advanced-search-type').component().value().value.should.equal(typePickerVal)
              elem.select('.hx-data-table-advanced-search-column').component().value().value.should.equal(columnPickerVal)
              elem.select('.hx-data-table-advanced-search-input').value().should.equal(termVal)

            checkValue(filterRows.node(0), undefined, 'any', 'a')
            checkValue(filterRows.node(1), 'and', 'name', 'b')
            checkValue(filterRows.node(2), 'or', 'any', 'c')

        it 'should make a new advancedSearch group when changing the type picker for a filter', (done) ->
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'c'}]]

          testTable {tableOptions}, undefined, (container, dt, options, data) ->
            filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
            filterRows.size().should.equal(3)

            pickerNode = hx.select(filterRows.node(1))
              .select('.hx-data-table-advanced-search-type').node()

            pickerExpectation = ->
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}], [{column: 'name', term: 'b'}, {column: 'any', term: 'c'}]])

            emulatePickerValueChange(pickerNode, dt, 1, done, pickerExpectation)


        it 'should update the advancedSearch when changing the column picker for a filter', (done) ->
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'c'}]]

          testTable {tableOptions}, undefined, (container, dt, options, data) ->
            filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
            filterRows.size().should.equal(3)

            pickerNode = hx.select(filterRows.node(1))
              .select('.hx-data-table-advanced-search-column').node()

            pickerExpectation = ->
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'age', term: 'b'}, {column: 'any', term: 'c'}]])

            emulatePickerValueChange(pickerNode, dt, 2, done, pickerExpectation)

        it 'should update the advancedSearch when changing the term for a filter', (done) ->
          clock = sinon.useFakeTimers(clockTime)
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'c'}]]

          testTable {tableOptions}, undefined, (container, dt, options, data) ->
            filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
            filterRows.size().should.equal(3)

            termNode = hx.select(filterRows.node(2)).select('.hx-data-table-advanced-search-input')

            termNode.value('d')
            testHelpers.fakeNodeEvent(termNode.node(), 'input')({target: {value: 'd'}})
            clock.tick(inputDebounceDelay + 1)
            dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'd'}]])
            clock.restore()
            hx.select('body').clear()
            done()


        it 'should default to "any" for the column value', (done) ->
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{term: 'a'}]]

          testTable {tableOptions}, done, (container, dt, options, data) ->
            filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
            filterRows.size().should.equal(1)

            pickerVal = hx.select(filterRows.node(0)).select('.hx-data-table-advanced-search-column').component().value()
            pickerVal.value.should.eql('any')
            pickerVal.anyColumn.should.eql(true)

        it 'should add a filter correctly', (done) ->
          tableOptions =
            advancedSearchEnabled: true

          testTable {tableOptions}, done, (container, dt, options, data) ->
            clearNode = container.select('.hx-data-table-advanced-search-add-filter').node()
            testHelpers.fakeNodeEvent(clearNode)(fakeEvent)
            dt.advancedSearch().should.eql([[{column: 'any', term: ''}]])

        it 'should add a filter correctly when there is a filter group', (done) ->
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'c'}]]

          testTable {tableOptions}, done, (container, dt, options, data) ->
            clearNode = container.select('.hx-data-table-advanced-search-add-filter').node()
            testHelpers.fakeNodeEvent(clearNode)(fakeEvent)
            dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'c'}, {column: 'any', term: ''}]])

        it 'should add a filter correctly when there are multiple filter groups', (done) ->
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}], [{column: 'any', term: 'c'}]]

          testTable {tableOptions}, done, (container, dt, options, data) ->
            clearNode = container.select('.hx-data-table-advanced-search-add-filter').node()
            testHelpers.fakeNodeEvent(clearNode)(fakeEvent)
            dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}], [{column: 'any', term: 'c'}, {column: 'any', term: ''}]])


        it 'should clear the filters correctly', (done) ->
          tableOptions =
            advancedSearchEnabled: true
            advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'c'}]]

          testTable {tableOptions}, done, (container, dt, options, data) ->
            clearNode = container.select('.hx-data-table-advanced-search-clear-filters').node()
            testHelpers.fakeNodeEvent(clearNode)(fakeEvent)
            should.not.exist(dt.advancedSearch())


        describe 'removing filters', ->

          it 'should remove a single filter', (done) ->
            tableOptions =
              showAdvancedSearch: true
              advancedSearchEnabled: true
              advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'any', term: 'c'}]]

            testTable {tableOptions}, done, (container, dt, options, data) ->
              filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
              filterRows.size().should.equal(3)

              removeNode = hx.select(filterRows.node(1)).select('.hx-data-table-advanced-search-remove').node()

              testHelpers.fakeNodeEvent(removeNode)(fakeEvent)
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'any', term: 'c'}]])


          it 'should remove the first filter in a group', (done) ->
            tableOptions =
              showAdvancedSearch: true
              advancedSearchEnabled: true
              advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}], [{column: 'any', term: 'c'}, {column: 'name', term: 'b'}]]

            testTable {tableOptions}, done, (container, dt, options, data) ->
              filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
              filterRows.size().should.equal(4)

              removeNode = hx.select(filterRows.node(2)).select('.hx-data-table-advanced-search-remove').node()

              testHelpers.fakeNodeEvent(removeNode)(fakeEvent)
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}, {column: 'name', term: 'b'}]])


          it 'should remove the last filter from a group', (done) ->
            tableOptions =
              showAdvancedSearch: true
              advancedSearchEnabled: true
              advancedSearch: [[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}], [{column: 'any', term: 'c'}]]

            testTable {tableOptions}, done, (container, dt, options, data) ->
              filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
              filterRows.size().should.equal(3)

              removeNode = hx.select(filterRows.node(2)).select('.hx-data-table-advanced-search-remove').node()

              testHelpers.fakeNodeEvent(removeNode)(fakeEvent)
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'name', term: 'b'}]])

          it 'should remove the last filter from a group when there are groups either side of it', (done) ->
            tableOptions =
              showAdvancedSearch: true
              advancedSearchEnabled: true
              advancedSearch: [[{column: 'any', term: 'a'}], [{column: 'name', term: 'b'}], [{column: 'any', term: 'c'}]]

            testTable {tableOptions}, done, (container, dt, options, data) ->
              filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
              filterRows.size().should.equal(3)

              removeNode = hx.select(filterRows.node(1)).select('.hx-data-table-advanced-search-remove').node()

              testHelpers.fakeNodeEvent(removeNode)(fakeEvent)
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}], [{column: 'any', term: 'c'}]])

          it 'should remove the first filter from a group when there are groups either side of it', (done) ->
            tableOptions =
              showAdvancedSearch: true
              advancedSearchEnabled: true
              advancedSearch: [[{column: 'any', term: 'a'}], [{column: 'name', term: 'b'}, {column: 'any', term: 'd'}], [{column: 'any', term: 'c'}]]

            testTable {tableOptions}, done, (container, dt, options, data) ->
              filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
              filterRows.size().should.equal(4)

              removeNode = hx.select(filterRows.node(1)).select('.hx-data-table-advanced-search-remove').node()

              testHelpers.fakeNodeEvent(removeNode)(fakeEvent)
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}, {column: 'any', term: 'd'}], [{column: 'any', term: 'c'}]])

          it 'should remove a filter from a group without affecting the surrounding groups', (done) ->
            tableOptions =
              showAdvancedSearch: true
              advancedSearchEnabled: true
              advancedSearch: [[{column: 'any', term: 'a'}], [{column: 'name', term: 'b'}, {column: 'any', term: 'd'}], [{column: 'any', term: 'c'}]]

            testTable {tableOptions}, done, (container, dt, options, data) ->
              filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
              filterRows.size().should.equal(4)

              removeNode = hx.select(filterRows.node(2)).select('.hx-data-table-advanced-search-remove').node()

              testHelpers.fakeNodeEvent(removeNode)(fakeEvent)
              dt.advancedSearch().should.eql([[{column: 'any', term: 'a'}], [{column: 'name', term: 'b'}], [{column: 'any', term: 'c'}]])

          it 'should remove the last filter', (done) ->
            tableOptions =
              showAdvancedSearch: true
              advancedSearchEnabled: true
              advancedSearch: [[{column: 'any', term: 'a'}]]

            testTable {tableOptions}, done, (container, dt, options, data) ->
              filterRows = container.select('.hx-data-table-advanced-search-container').selectAll('.hx-data-table-advanced-search-filter')
              filterRows.size().should.equal(1)

              removeNode = hx.select(filterRows.node(0)).select('.hx-data-table-advanced-search-remove').node()

              testHelpers.fakeNodeEvent(removeNode)(fakeEvent)
              should.not.exist(dt.advancedSearch())


      describe 'hx.dataTable.getAdvancedSearchFilter', ->
        it 'should use the defaults if provided', ->
          advancedSearchFilter = hx.dataTable.getAdvancedSearchFilter()

          filter = [[{column: 'name', term: 'Bob'}]]

          advancedSearchFilter(filter, {cells: {name: 'Bob'}}).should.equal(true)
          advancedSearchFilter(filter, {cells: {name: 'Steve'}}).should.equal(false)
          advancedSearchFilter(filter, {cells: {name: 'Bobby'}}).should.equal(true)

          filter = [[{column: 'any', term: 'Bob'}, {column: 'any', term: 'Steve'}]]

          advancedSearchFilter(filter, {cells: {name: 'Bob', surname: 'Steve'}}).should.equal(true)
          advancedSearchFilter(filter, {cells: {name: 'steve', surname: 'bob'}}).should.equal(true)

        it 'should use the provided cellValueLookup', ->
          cellValueLookup = (cell) -> cell.value

          advancedSearchFilter = hx.dataTable.getAdvancedSearchFilter(cellValueLookup)

          filter = [[{column: 'name', term: 'Bob'}]]

          advancedSearchFilter(filter, {cells: {name: {text: 'a', value: 'Bob'}}}).should.equal(true)
          advancedSearchFilter(filter, {cells: {name: {text: 'b', value: 'Steve'}}}).should.equal(false)
          advancedSearchFilter(filter, {cells: {name: {text: 'c', value: 'Bobby'}}}).should.equal(true)

        it 'should use the provided termLookup', ->
          termLookup = (term, rowSearchTerm) -> rowSearchTerm.indexOf(term) > -1

          filter = [[{column: 'name', term: 'Bob Steve'}]]

          advancedSearchFilter = hx.dataTable.getAdvancedSearchFilter(undefined, termLookup)

          advancedSearchFilter(filter, {cells: {name: 'Bob Steve'}}).should.equal(true)
          advancedSearchFilter(filter, {cells: {name: 'bob a steve'}}).should.equal(false)

          filter = [[{column: 'any', term: 'Bob'}, {column: 'any', term: 'Steve'}]]

          advancedSearchFilter(filter, {cells: {name: 'Bob', surname: 'Steve'}}).should.equal(true)
          advancedSearchFilter(filter, {cells: {name: 'steve', surname: 'bob'}}).should.equal(true)


    describe 'option combinations', ->
      it 'advancedSearchEnabled (true) and showSearchAboveTable (true) should show the advanced search above the table', (done) ->
        tableOptions =
          advancedSearchEnabled: true
          showSearchAboveTable: true

        testTable {tableOptions}, done, (container, dt, options, data) ->
          # We assume the styles work here - the re-ordering of the control panel is done purely with CSS...
          container.classed('hx-data-table-show-search-above-content').should.equal(true)
          container.select('.hx-data-table-advanced-search-container').classed('hx-data-table-advanced-search-visible').should.equal(true)


      it 'advancedSearchEnabled(true) and filterEnabled (false) should only show the advanced search', (done) ->
        tableOptions =
          advancedSearchEnabled: true
          filterEnabled: false

        testTable {tableOptions}, done, (container, dt, options, data) ->
          container.select('.hx-data-table-advanced-search-container').classed('hx-data-table-advanced-search-visible').should.equal(true)
          container.select('.hx-data-table-advanced-search-toggle').classed('hx-data-table-advanced-search-visible').should.equal(false)
          container.select('.hx-data-table-filter').classed('hx-data-table-filter-visible').should.equal(false)


      describe 'compact', ->
        it 'filterEnabled (true) and sortEnabled (false) should show the compact control panel', (done) ->
          tableOptions =
            compact: true
            filterEnabled: true
            sortEnabled: false

          testTable {tableOptions}, done, (container, dt, options, data) ->
            container.select('.hx-data-table-control-panel-compact').classed('hx-data-table-control-panel-compact-visible').should.equal(true)
            container.select('.hx-data-table-control-panel-bottom').classed('hx-data-table-control-panel-bottom-visible').should.equal(false)

        it 'advancedSearchEnabled (true) and filterEnabled/sortEnabled (false) should show the compact control panel', (done) ->
          tableOptions =
            compact: true
            advancedSearchEnabled: true
            filterEnabled: false
            sortEnabled: false

          testTable {tableOptions}, done, (container, dt, options, data) ->
            container.select('.hx-data-table-control-panel-compact').classed('hx-data-table-control-panel-compact-visible').should.equal(true)
            container.select('.hx-data-table-control-panel-bottom').classed('hx-data-table-control-panel-bottom-visible').should.equal(false)

        it 'pageSizeOptions and filterEnabled/sortEnabled (false) should show the compact control panel and bottom control panel', (done) ->
          tableOptions =
            compact: true
            pageSizeOptions: [1,2,3,4,5]
            filterEnabled: false
            sortEnabled: false

          testTable {tableOptions}, done, (container, dt, options, data) ->
            container.select('.hx-data-table-control-panel-compact').classed('hx-data-table-control-panel-compact-visible').should.equal(true)
            container.select('.hx-data-table-control-panel-bottom').classed('hx-data-table-control-panel-bottom-visible').should.equal(true)

        it 'should not show the control panels when there is nothing to show in them', (done) ->
          tableOptions =
            compact: true
            filterEnabled: false
            sortEnabled: false

          testTable {tableOptions}, done, (container, dt, options, data) ->
            container.select('.hx-data-table-control-panel-compact').classed('hx-data-table-control-panel-compact-visible').should.equal(false)
            container.select('.hx-data-table-control-panel-bottom').classed('hx-data-table-control-panel-bottom-visible').should.equal(false)

        it 'should toggle the control panel visibility when the toggle is clicked', (done) ->
          clock = sinon.useFakeTimers(clockTime)
          tableOptions =
            compact: true

          testTable {tableOptions}, done, (container, dt, options, data) ->
            toggleButton = container.select('.hx-data-table-control-panel-compact-toggle')
            toggleButton.classed('hx-data-table-control-panel-compact-toggle-visible').should.equal(true)
            controlPanel = container.select('.hx-data-table-control-panel')
            controlPanelCompact = container.select('.hx-data-table-control-panel-compact')
            controlPanel.classed('hx-data-table-control-panel-visible hx-data-table-compact-hide').should.equal(true)
            testHelpers.fakeNodeEvent(toggleButton.node())(fakeEvent)
            clock.tick(animationCompletedDelay)
            controlPanel.classed('hx-data-table-compact-hide').should.equal(false)
            controlPanelCompact.classed('hx-data-table-control-panel-compact-open').should.equal(true)
            testHelpers.fakeNodeEvent(toggleButton.node())(fakeEvent)
            clock.tick(animationCompletedDelay)
            controlPanel.classed('hx-data-table-compact-hide').should.equal(true)
            controlPanelCompact.classed('hx-data-table-control-panel-compact-open').should.equal(false)
            clock.restore()


    ###
  selection = hx.select('body').append('div')
        .style 'width', '500px'
        .style 'height', '500px'
      graph = new hx.Graph(selection.node(), redrawOnResize: false)
      axis = graph.addAxis(x: { title: 'foo' }, y: { title: 'bar' })
      axis.addSeries('line', data: [{ x: 0, y: 1 }])
      graph.render()

      renderSpy = chai.spy()
      graph.on 'render', renderSpy
      selection.style 'width', '400px'
      testHelpers.fakeNodeEvent(selection.node(), 'resize')()
      renderSpy.should.not.have.been.called()
###
    describe 'redrawonresize', ->
      it 'should redraw the table on resizing the container by default', ->
        container = hx.select('body').append('div').style('width', '1000px').style('height', '500px')
        dt = new hx.DataTable(container.node())
        dt.feed(threeRowsData)

        renderSpy = chai.spy()
        dt.on 'render', renderSpy
        container.style 'width', '400px'
        testHelpers.fakeNodeEvent(container.node(), 'resize')()
        renderSpy.should.have.been.called()

      it 'should not redraw the table on resizing the container if told not to', ->
        container = hx.select('body').append('div').style('width', '1000px').style('height', '500px')
        dt = new hx.DataTable(container.node(), redrawOnResize: false)
        dt.feed(threeRowsData)

        renderSpy = chai.spy()
        dt.on 'render', renderSpy
        container.style 'width', '400px'
        testHelpers.fakeNodeEvent(container.node(), 'resize')()
        renderSpy.should.not.have.been.called()

      it 'should redraw the table when changing the redrawOnResize option', ->
        container = hx.select('body').append('div').style('width', '1000px').style('height', '500px')
        dt = new hx.DataTable(container.node(), redrawOnResize: true)
        dt.feed(threeRowsData)

        renderSpy = chai.spy()
        dt.on 'render', renderSpy
        dt.redrawOnResize false
        renderSpy.should.have.been.called()
        dt.redrawOnResize().should.be.true()


  describe 'rowsForIds', ->
    it 'should return the correct values', (done) ->
      dt = new hx.DataTable(hx.detached('div').node())
      dt.feed(hx.dataTable.objectFeed(threeRowsData))
      dt.rowsForIds ['0', '2'], (rows) ->
        rows.should.eql([threeRowsData.rows[0], threeRowsData.rows[2]])
        done()

    it 'should return the same rows when called multiple times', (done) ->
      dt = new hx.DataTable(hx.detached('div').node())
      dt.feed(hx.dataTable.objectFeed(threeRowsData))
      dt.rowsForIds ['0', '2'], (rows) ->
        rows.should.eql([threeRowsData.rows[0], threeRowsData.rows[2]])

        dt.rowsForIds ['0', '2', '3'], (rows) ->
          rows.should.eql(rows)
          done()

    it 'should do nothing if no callback is provided', ->
      dt = new hx.DataTable(hx.detached('div').node())

      feed = hx.dataTable.objectFeed(threeRowsData)
      feed.rowsForIds = chai.spy()
      dt.feed feed

      dt.rowsForIds(['1'])
      feed.rowsForIds.should.not.have.been.called()



  describe 'renderSuppressed', ->
    it 'should prevent render from doing anything when true', ->
      container = hx.detached('div').style('width', '1000px')
      dt = new hx.DataTable(container.node())
      f = chai.spy()
      dt.renderSuppressed(true)
      dt.feed hx.dataTable.objectFeed(threeRowsData), f
      f.should.not.have.been.called()
      container.select('.hx-data-table-content').node().childNodes.length.should.equal(0)
      container.selectAll('.hx-data-table-table').size().should.equal(0)







  describe 'events', ->

    describe 'sortchange', ->
      it 'should emit an event when sort clicked with cause: user', (done) ->
        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node())

        dt.on 'sortchange', (d) ->
          d.value.column.should.equal('name')
          d.value.direction.should.equal('asc')
          d.cause.should.equal('user')
          done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-top').select('.hx-data-table-cell').node(), 'click')()

    describe 'filterchange', ->
      it 'should emit an event when filter changed with cause: user', (done) ->
        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node())

        dt.on 'filterchange', (d) ->
          d.value.should.equal('test')
          d.cause.should.equal('user')
          done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          selection.select('.hx-data-table-filter').value('test')
          testHelpers.fakeNodeEvent(selection.select('.hx-data-table-filter').node(), 'input')()


    describe 'selectedrowschange', ->
      it 'should emit an event when rows are selected/deselected', (done) ->
        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node(), {
          selectEnabled: true,
          rowSelectableLookup: (row) -> true
        })

        n = 0
        dt.on 'selectedrowschange', (d) ->

          if n is 0
            d.row.should.eql(threeRowsData.rows[0])
            d.rowValue.should.equal(true)
            d.value.should.eql([threeRowsData.rows[0].id])
            d.cause.should.equal('user')
            n++
          else if n is 1
            d.row.should.eql(threeRowsData.rows[2])
            d.rowValue.should.equal(true)
            d.value.should.eql([threeRowsData.rows[0].id, threeRowsData.rows[2].id])
            d.cause.should.equal('user')
            n++
          else if n is 2
            d.row.should.eql(threeRowsData.rows[0])
            d.rowValue.should.equal(false)
            d.value.should.eql([threeRowsData.rows[2].id])
            d.cause.should.equal('user')
            done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox').node(0), 'click')(fakeEvent)
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox').node(2), 'click')(fakeEvent)
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox').node(0), 'click')(fakeEvent)

    describe 'selectedrowsclear', ->
      it 'should emit an event when the selected rows is cleared', (done) ->
        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node(), {
          selectEnabled: true,
          rowSelectableLookup: (row) -> true
        })

        n = 0
        dt.on 'selectedrowschange', (d) ->
          if n is 1
            testHelpers.fakeNodeEvent(selection.select('.hx-data-table-status-bar-clear').node(0), 'click')(fakeEvent)
          n++

        dt.on 'selectedrowsclear', (d) ->
          done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox').node(0), 'click')(fakeEvent)
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-left').select('tbody').selectAll('.hx-data-table-checkbox').node(2), 'click')(fakeEvent)

    describe 'expandedrowschange', ->
      it 'should emit an event when row is collapsed/expanded', (done) ->

        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node(), {
          collapsibleRenderer: ->
          rowCollapsibleLookup: (row) -> true
        })

        first = true
        dt.on 'expandedrowschange', (d) ->
          d.row.should.eql(threeRowsData.rows[0])
          if first
            d.rowValue.should.equal(true)
            d.value.should.eql([threeRowsData.rows[0].id])
            d.cause.should.equal('user')
            first = false
          else
            d.rowValue.should.equal(false)
            d.value.should.eql([])
            d.cause.should.equal('user')
            done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-left').select('.hx-data-table-collapsible-toggle').node(), 'click')()
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-header-left').select('.hx-data-table-collapsible-toggle').node(), 'click')()

    describe 'rowclick', ->
      it 'should emit an event when the row is clicked', (done) ->
        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node(), {pageSizeOptions: [5, 10, 15]})

        dt.on 'rowclick', (d) ->
          d.data.should.eql(threeRowsData.rows[0])
          d.node.should.be.an.instanceof(Element)
          done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          testHelpers.fakeNodeEvent(selection.select('.hx-sticky-table-wrapper').select('.hx-data-table-body').select('.hx-data-table-row').node(), 'click')()

    describe 'render', ->
      it 'should emit an event when the row is clicked', (done) ->
        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node(), {pageSizeOptions: [5, 10, 15]})

        dt.on 'render', -> done()

        dt.feed hx.dataTable.objectFeed(threeRowsData)

    describe 'pagesizechange', ->
      it 'should emit an event when the page size is changed with cause: user', (done) ->
        selection = hx.detached('div')
        dt = new hx.DataTable(selection.node(), {pageSizeOptions: [5, 10, 15]})

        dt.on 'pagesizechange', (d) ->
          d.value.should.equal(10)
          d.cause.should.equal('user')
          done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          selection
            .select('.hx-data-table-page-size-picker')
            .component()
            .emit('change', {value: {value: 10, text: '10'}, cause: 'user'})

    describe 'pagechange', ->

      describe 'should emit an event when the page changes', ->

        it 'should work when setting the page to 2', (done) ->
          selection = hx.detached('div')
          dt = new hx.DataTable(selection.node(), {pageSize: 2, pageSizeOptions: [5, 10, 15]})
          dt.on 'pagechange', (d) ->
            d.value.should.eql(2)
            d.cause.should.equal('user')
            done()
          dt.feed hx.dataTable.objectFeed(threeRowsData), ->
            selection.select('.hx-data-table-paginator-picker').component().emit('change', {value: {value: 2}, cause: 'user'})

        it 'should work when setting the page to 1', (done) ->
          selection = hx.detached('div')
          dt = new hx.DataTable(selection.node(), {pageSize: 2, pageSizeOptions: [5, 10, 15]})
          dt.on 'pagechange', (d) ->
            d.value.should.equal(1)
            d.cause.should.equal('user')
            done()
          dt.feed hx.dataTable.objectFeed(threeRowsData), ->
            selection.select('.hx-data-table-paginator-picker').component().emit('change', {value: {value: 1}, cause: 'user'})

    describe 'compactchange', ->
      it 'should emit an event when changing from full to compact', (done) ->

        container = hx.select('body').append('div').style('width', '1000px')

        dt = new hx.DataTable(container.node())

        dt.on 'compactchange', (d) ->
          d.value.should.equal('auto')
          d.state.should.equal(true)
          d.cause.should.equal('user')
          hx.select('body').clear()
          done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          container.style('width', '100px')

      it 'should emit an event when changing from compact to full', (done) ->
        container = hx.select('body').append('div').style('width', '100px')

        dt = new hx.DataTable(container.node())

        dt.on 'compactchange', (d) ->
          d.value.should.equal('auto')
          d.state.should.equal(false)
          d.cause.should.equal('user')
          dt.off('compactchange')
          hx.select('body').clear()
          done()

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          container.style('width', '1000px')

       it 'should not emit an event if it doesnt change mode', (done) ->

        container = hx.select('body').append('div').style('width', '1000px')

        dt = new hx.DataTable(container.node())

        called = false
        dt.on 'compactchange', (d) ->
          called = true

        dt.feed hx.dataTable.objectFeed(threeRowsData), ->
          container.style('width', '900px')

          f = ->
            called.should.equal(false)
            done()
          setTimeout(f, 50)



  describe 'data feeds', ->
    describe 'object data feed', ->
      data = {
        headers: [
          { name: 'Name', id: 'name' },
          { name: 'Age', id: 'age' },
          { name: 'Profession', id: 'profession' }
        ],
        rows: [
          {
            id: 0, # hidden details can go here (not in the cells object)
            cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
          },
          {
            id: 1,
            cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
          },
          {
            id: 2,
            cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
          }
        ]
      }

      it 'should get the number of rows in the data set', (done) ->
        hx.dataTable.objectFeed(data).totalCount (count) ->
          count.should.equal(3)
          done()

      it 'should get the headers from the data set', (done) ->
        hx.dataTable.objectFeed(data).headers (headers) ->
          headers.should.eql([
            { name: 'Name', id: 'name' },
            { name: 'Age', id: 'age' },
            { name: 'Profession', id: 'profession' }
          ])
          done()

      it 'should get the rows from the data set 1', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 0, end: 0}, (data) ->
          data.rows.should.eql([
            {
              id: 0,
              cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
            }
          ])
          data.filteredCount.should.equal(3)
          done()

      it 'should get the rows from the data set 2', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 1, end: 2}, (data) ->
          data.rows.should.eql([
            {
              id: 1,
              cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
            },
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            }
          ])
          data.filteredCount.should.equal(3)
          done()

      it 'should get the rows from the data set with filtering', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 0, end: 2, filter: '41'}, (data) ->
          data.rows.should.eql([
            {
              id: 1,
              cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
            },
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            }
          ])
          data.filteredCount.should.equal(2)
          done()

      it 'should get the rows from the data set with filtering and limited range', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 1, end: 1, filter: '41'}, (data) ->
          data.rows.should.eql([
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            }
          ])
          data.filteredCount.should.equal(2)
          done()

      it 'should get the rows from the data set with sorting (asc)', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 0, end: 2, sort: {column: 'name', direction: 'asc'}}, (data) ->
          data.rows.should.eql([
            {
              id: 0, # hidden details can go here (not in the cells object)
              cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
            },
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            },
            {
              id: 1,
              cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
            }
          ])
          data.filteredCount.should.equal(3)
          done()

      it 'should get the rows from the data set with sorting (desc)', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 0, end: 2, sort: {column: 'name', direction: 'desc'}}, (data) ->
          data.rows.should.eql([
            {
              id: 1,
              cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
            },
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            },
            {
              id: 0, # hidden details can go here (not in the cells object)
              cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
            }
          ])
          data.filteredCount.should.equal(3)
          done()

      it 'should get the rows from the data set with sorting and limited range', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 1, end: 2, sort: {column: 'name', direction: 'asc'}}, (data) ->
          data.rows.should.eql([
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            },
            {
              id: 1,
              cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
            }
          ])
          data.filteredCount.should.equal(3)
          done()

      it 'should get the rows from the data set with sorting and filtering', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 0, end: 2, sort: {column: 'name', direction: 'asc'}, filter: '41'}, (data) ->
          data.rows.should.eql([
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            },
            {
              id: 1,
              cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
            }
          ])
          data.filteredCount.should.equal(2)
          done()

      it 'should get the rows from the data set with sorting and filtering and limited range', (done) ->
        hx.dataTable.objectFeed(data).rows {start: 0, end: 0, sort: {column: 'name', direction: 'asc'}, filter: '41'}, (data) ->
          data.rows.should.eql([
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            }
          ])
          data.filteredCount.should.equal(2)
          done()

      it 'should get the rows for ids correctly 1', (done) ->
        lookup = (row) -> row.id
        hx.dataTable.objectFeed(data).rowsForIds [0, 1], lookup, (rows) ->
          rows.should.eql([
            {
              id: 0, # hidden details can go here (not in the cells object)
              cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
            },
            {
              id: 1,
              cells: { 'name': 'Jan', 'age': 41, 'profession': 'Artist' }
            }
          ])
          done()

      it 'should get the rows for ids correctly 2', (done) ->
        lookup = (row) -> row.id
        hx.dataTable.objectFeed(data).rowsForIds [2, 0], lookup, (rows) ->
          rows.should.eql([
            {
              id: 2,
              cells: { 'name': 'Dan', 'age': 41, 'profession': 'Builder' }
            },
            {
              id: 0, # hidden details can go here (not in the cells object)
              cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
            }
          ])
          done()

      it 'should use the provided filter function', ->
        options =
          filter: (term, row) -> row.cells.name is term
        hx.dataTable.objectFeed(data, options).rows {filter: 'Bob', start: 0, end: 2}, (data) ->
          data.rows.should.eql([
            {
              id: 0,
              cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
            }
          ])
          data.filteredCount.should.equal(1)

      it 'should use the provided advanced search function', ->
        options =
          advancedSearch: (filters, row) -> row.cells.name is filters[0][0].term
        hx.dataTable.objectFeed(data, options).rows {useAdvancedSearch: true, advancedSearch: [[{column: 'name', term: 'Bob'}]], start: 0, end: 2}, (data) ->
          data.rows.should.eql([
            {
              id: 0,
              cells: { 'name': 'Bob', 'age': 25, 'profession': 'Developer' }
            }
          ])
          data.filteredCount.should.equal(1)

      describe 'advanced search', ->
        advancedSearchData = {
          headers: [
            { id: 'name', name: "Name" }
            { id: 'phone', name: "Phone" }
            { id: 'email', name: "Email" }
            { id: 'company', name: "Company" }
            { id: 'city', name: "City" }
            { id: 'keywords', name: "Keywords" }
            { id: 'salary', name: "Salary" }
          ]
          rows: [
            { cells: { name: "Wing Simon", phone: "(0151) 610 0311", email: "Curabitur.vel.lectus@nibhdolor.com", company: "Fringilla Corp.", city: "Frignano", keywords: "Morbi sit amet", salary: "£235.59" } }
            { cells: { name: "Simon Olsen", phone: "056 1366 7271", email: "mauris.sapien.cursus@Proinultrices.com", company: "Aenean Foundation", city: "Istanbul", keywords: "non magna. Nam", salary: "£337.53" } }
            { cells: { name: "Juliet Ruiz", phone: "0800 692945", email: "vel@Aliquam.ca", company: "Auctor Velit Aliquam Corp.", city: "Kungälv", keywords: "consequat nec, mollis", salary: "£463.76" } }
            { cells: { name: "Olivia Caldwell", phone: "(01370) 43740", email: "Aenean.massa@condimentum.co.uk", company: "Fringilla Porttitor Vulputate Inc.", city: "Birmingham", keywords: "Donec fringilla. Donec", salary: "£257.33" } }
            { cells: { name: "Odette Ferrell", phone: "(011495) 29835", email: "dolor@aliquetPhasellus.co.uk", company: "Tincidunt Company", city: "Quedlinburg", keywords: "ac, eleifend vitae,", salary: "£353.87" } }
            { cells: { name: "Lilah Lamb", phone: "07624 294538", email: "gravida@nonmassa.com", company: "Tellus Justo Sit LLP", city: "Vagli Sotto", keywords: "commodo auctor velit.", salary: "£292.15" } }
          ]
        }

        it 'should return the complete dataset when the filter is not defined', (done) ->
          filter = undefined
          hx.dataTable.objectFeed(advancedSearchData).rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            data.rows.should.eql(advancedSearchData.rows)
            data.filteredCount.should.equal(6)
            done()

        it 'should return the complete dataset when the filter is empty', (done) ->
          filter = []
          hx.dataTable.objectFeed(advancedSearchData).rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            data.rows.should.eql(advancedSearchData.rows)
            data.filteredCount.should.equal(6)
            done()

        it 'should return the complete dataset when the filter is empty', (done) ->
          filter = [[]]
          hx.dataTable.objectFeed(advancedSearchData).rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            data.rows.should.eql(advancedSearchData.rows)
            data.filteredCount.should.equal(6)
            done()

        it 'should get the rows from the data set with filtering on multiple columns', (done) ->
          filter = [
            [{
              column: 'name',
              term: 'a',
            }, {
              column: 'phone',
              term: '1',
            }]
          ]
          hx.dataTable.objectFeed(advancedSearchData).rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            data.rows.should.eql([
              { cells: { name: "Olivia Caldwell", phone: "(01370) 43740", email: "Aenean.massa@condimentum.co.uk", company: "Fringilla Porttitor Vulputate Inc.", city: "Birmingham", keywords: "Donec fringilla. Donec", salary: "£257.33" } }
            ])
            data.filteredCount.should.equal(1)
            done()

        it 'should filter multiple times on the same data', (done) ->
          filter = [
            [{
              column: 'any'
              term: 'a'
            }]
          ]
          feed = hx.dataTable.objectFeed(advancedSearchData)

          firstData = undefined

          feed.rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            firstData = data.rows
            data.rows.should.eql([
              { cells: { name: "Wing Simon", phone: "(0151) 610 0311", email: "Curabitur.vel.lectus@nibhdolor.com", company: "Fringilla Corp.", city: "Frignano", keywords: "Morbi sit amet", salary: "£235.59" } }
              { cells: { name: "Simon Olsen", phone: "056 1366 7271", email: "mauris.sapien.cursus@Proinultrices.com", company: "Aenean Foundation", city: "Istanbul", keywords: "non magna. Nam", salary: "£337.53" } }
              { cells: { name: "Juliet Ruiz", phone: "0800 692945", email: "vel@Aliquam.ca", company: "Auctor Velit Aliquam Corp.", city: "Kungälv", keywords: "consequat nec, mollis", salary: "£463.76" } }
              { cells: { name: "Olivia Caldwell", phone: "(01370) 43740", email: "Aenean.massa@condimentum.co.uk", company: "Fringilla Porttitor Vulputate Inc.", city: "Birmingham", keywords: "Donec fringilla. Donec", salary: "£257.33" } }
              { cells: { name: "Odette Ferrell", phone: "(011495) 29835", email: "dolor@aliquetPhasellus.co.uk", company: "Tincidunt Company", city: "Quedlinburg", keywords: "ac, eleifend vitae,", salary: "£353.87" } }
              { cells: { name: "Lilah Lamb", phone: "07624 294538", email: "gravida@nonmassa.com", company: "Tellus Justo Sit LLP", city: "Vagli Sotto", keywords: "commodo auctor velit.", salary: "£292.15" } }
            ])
            data.filteredCount.should.equal(6)

            filter = [
              [{
                column: 'name',
                term: 'a',
              }, {
                column: 'phone',
                term: '1',
              }]
            ]

            feed.rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
              data.rows.should.eql([
                { cells: { name: "Olivia Caldwell", phone: "(01370) 43740", email: "Aenean.massa@condimentum.co.uk", company: "Fringilla Porttitor Vulputate Inc.", city: "Birmingham", keywords: "Donec fringilla. Donec", salary: "£257.33" } }
              ])
              data.filteredCount.should.equal(1)
              done()

        it 'should filter on "any" column', (done) ->
          filter = [
            [{
              column: 'any'
              term: 'a'
            }]
          ]
          hx.dataTable.objectFeed(advancedSearchData).rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            data.rows.should.eql([
              { cells: { name: "Wing Simon", phone: "(0151) 610 0311", email: "Curabitur.vel.lectus@nibhdolor.com", company: "Fringilla Corp.", city: "Frignano", keywords: "Morbi sit amet", salary: "£235.59" } }
              { cells: { name: "Simon Olsen", phone: "056 1366 7271", email: "mauris.sapien.cursus@Proinultrices.com", company: "Aenean Foundation", city: "Istanbul", keywords: "non magna. Nam", salary: "£337.53" } }
              { cells: { name: "Juliet Ruiz", phone: "0800 692945", email: "vel@Aliquam.ca", company: "Auctor Velit Aliquam Corp.", city: "Kungälv", keywords: "consequat nec, mollis", salary: "£463.76" } }
              { cells: { name: "Olivia Caldwell", phone: "(01370) 43740", email: "Aenean.massa@condimentum.co.uk", company: "Fringilla Porttitor Vulputate Inc.", city: "Birmingham", keywords: "Donec fringilla. Donec", salary: "£257.33" } }
              { cells: { name: "Odette Ferrell", phone: "(011495) 29835", email: "dolor@aliquetPhasellus.co.uk", company: "Tincidunt Company", city: "Quedlinburg", keywords: "ac, eleifend vitae,", salary: "£353.87" } }
              { cells: { name: "Lilah Lamb", phone: "07624 294538", email: "gravida@nonmassa.com", company: "Tellus Justo Sit LLP", city: "Vagli Sotto", keywords: "commodo auctor velit.", salary: "£292.15" } }
            ])
            data.filteredCount.should.equal(6)
            done()

        it 'should get the rows from the data set with filtering on multiple columns using "or"', (done) ->
          filter = [
            [{
              column: 'name',
              term: 'a',
            }], [{
              column: 'phone',
              term: '1',
            }]
          ]
          hx.dataTable.objectFeed(advancedSearchData).rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            data.rows.should.eql([
              { cells: { name: "Wing Simon", phone: "(0151) 610 0311", email: "Curabitur.vel.lectus@nibhdolor.com", company: "Fringilla Corp.", city: "Frignano", keywords: "Morbi sit amet", salary: "£235.59" } }
              { cells: { name: "Simon Olsen", phone: "056 1366 7271", email: "mauris.sapien.cursus@Proinultrices.com", company: "Aenean Foundation", city: "Istanbul", keywords: "non magna. Nam", salary: "£337.53" } }
              { cells: { name: "Olivia Caldwell", phone: "(01370) 43740", email: "Aenean.massa@condimentum.co.uk", company: "Fringilla Porttitor Vulputate Inc.", city: "Birmingham", keywords: "Donec fringilla. Donec", salary: "£257.33" } }
              { cells: { name: "Odette Ferrell", phone: "(011495) 29835", email: "dolor@aliquetPhasellus.co.uk", company: "Tincidunt Company", city: "Quedlinburg", keywords: "ac, eleifend vitae,", salary: "£353.87" } }
              { cells: { name: "Lilah Lamb", phone: "07624 294538", email: "gravida@nonmassa.com", company: "Tellus Justo Sit LLP", city: "Vagli Sotto", keywords: "commodo auctor velit.", salary: "£292.15" } }
            ])
            data.filteredCount.should.equal(5)
            done()

        it 'should perform a complex filter', (done) ->
          filter = [
            [{
              column: 'name',
              term: 'a',
            }, {
              column: 'email',
              term: '.com',
            }], [{
              column: 'company',
              term: 'corp.',
            }, {
              column: 'phone',
              term: '1',
            }], [{
              column: 'keywords',
              term: 'nam',
            }]
          ]
          hx.dataTable.objectFeed(advancedSearchData).rows {start: 0, end: 5, useAdvancedSearch: true, advancedSearch: filter}, (data) ->
            data.rows.should.eql([
              { cells: { name: "Wing Simon", phone: "(0151) 610 0311", email: "Curabitur.vel.lectus@nibhdolor.com", company: "Fringilla Corp.", city: "Frignano", keywords: "Morbi sit amet", salary: "£235.59" } }
              { cells: { name: "Simon Olsen", phone: "056 1366 7271", email: "mauris.sapien.cursus@Proinultrices.com", company: "Aenean Foundation", city: "Istanbul", keywords: "non magna. Nam", salary: "£337.53" } }
              { cells: { name: "Lilah Lamb", phone: "07624 294538", email: "gravida@nonmassa.com", company: "Tellus Justo Sit LLP", city: "Vagli Sotto", keywords: "commodo auctor velit.", salary: "£292.15" } }
            ])
            data.filteredCount.should.equal(3)
            done()


    describe 'infinite data', ->

      # feed for use when testing the infinite data
      infiniteFeed = {
        headers: (cb) -> cb([
          { name: 'Name', id: 'name' },
          { name: 'Age', id: 'age' },
          { name: 'Profession', id: 'profession' }
        ])
        totalCount: (cb) ->
          cb(undefined)
        rows: (range, cb) ->
          cb({
            rows: [range.start..range.end].map (i) -> {id: i, cells: {'name': 'Name' + i, 'age': i, 'profession': 'Job' + i}},
            filteredCount: undefined
          })
        rowsForIds: (ids, lookupRow, cb) ->
          cb(ids.map (i) -> {id: i, cells: {'name': 'Name' + i, 'age': i, 'profession': 'Job' + i}})
      }

      it 'should have the hx-data-table-infinite class (so that hiding of non-used elements happens)', (done) ->
        container = hx.detached('div').style('width', '1000px')
        dt = new hx.DataTable(container.node(), {
          pageSizeOptions: [5, 10, 15]
        })

        dt.feed infiniteFeed, ->
          container.classed('hx-data-table-infinite').should.equal(true)
          done()

      describe 'should display the correct text for the currently visible rows', ->
        container = hx.detached('div').style('width', '1000px')
        dt = new hx.DataTable(container.node(), {
          pageSize: [5, 10, 15]
        })

        dt.feed(infiniteFeed)

        it 'pageSize: 3', (done) ->
          dt.pageSize 3, ->
            container.select('.hx-data-table-paginator-total-rows').text().should.equal('1 - 3')
            done()

        it 'pageSize: 15', (done) ->
          dt.pageSize 15, ->
            container.select('.hx-data-table-paginator-total-rows').text().should.equal('1 - 15')
            done()

        it 'pageSize: 200, page: 2', (done) ->
          dt.pageSize 200, ->
            dt.page 2, ->
              container.select('.hx-data-table-paginator-total-rows').text().should.equal('201 - 400')
              done()

      describe 'should correctly disable the pagnation arrows given the page number', ->
        container = hx.detached('div').style('width', '1000px')
        dt = new hx.DataTable(container.node())

        dt.feed(infiniteFeed)

        it 'page: 1 should disable the back button', (done) ->
          dt.pageSize 15, ->
            dt.page 1, ->
              container.select('.hx-data-table-paginator-back').classed('hx-data-table-btn-disabled').should.equal(true)
              done()

        it 'page: 2 should enable the back button', (done) ->
          dt.pageSize 15, ->
            dt.page 2, ->
              container.select('.hx-data-table-paginator-back').classed('hx-data-table-btn-disabled').should.equal(false)
              done()


    describe 'url feed', ->
      json = undefined
      setupFakeHxJson = (response, expectedUrl, expectedPostData) ->
        json = hx.json
        hx.json = (url, data, cb) ->
          if expectedUrl isnt undefined
            url.should.eql(expectedUrl)
          else
            should.not.exist(data)

          if expectedPostData isnt undefined
            data.should.eql(expectedPostData)
          else
            should.not.exist(data)

          cb(undefined, response)

      tearDownFakeHxJson = -> hx.json = json


      testFeedWithOptions = (options) ->
        it 'headers', (done) ->
          setupFakeHxJson(['header1', 'header2', 'header3'], 'some-url', {type: 'headers', extra: options?.extra})
          hx.dataTable.urlFeed('some-url', options).headers (headers) ->
            headers.should.eql(['header1', 'header2', 'header3'])
            tearDownFakeHxJson()
            done()

        it 'totalCount', (done) ->
          setupFakeHxJson({count: 3}, 'some-url', {type: 'totalCount', extra: options?.extra})
          hx.dataTable.urlFeed('some-url', options).totalCount (count) ->
            count.should.equal(3)
            tearDownFakeHxJson()
            done()

        it 'rows', (done) ->
          result = {
            rows: [
              {'id': 0, 'cells': {'whatever': 1}},
              {'id': 1, 'cells': {'whatever': 2}}
            ],
            filteredCount: 5
          }
          setupFakeHxJson(result, 'some-url', {type: 'rows', range: {start: 0, end: 5, filter: 'something'}, extra: options?.extra})
          hx.dataTable.urlFeed('some-url', options).rows {start: 0, end: 5, filter: 'something'}, (res) ->
            res.should.eql(result)
            tearDownFakeHxJson()
            done()

        it 'rowsForIds', (done) ->
          result = [
            {'id': 0, 'cells': {'whatever': 1}},
            {'id': 1, 'cells': {'whatever': 2}}
          ]
          setupFakeHxJson(result, 'some-url', {type: 'rowsForIds', ids: [0, 1], extra: options?.extra})
          hx.dataTable.urlFeed('some-url', options).rowsForIds [0, 1], undefined, (res) ->
            res.should.eql(result)
            tearDownFakeHxJson()
            done()

      describe 'with default options should make the correct requests for', ->
        testFeedWithOptions(undefined)

      describe 'with cached: true should make the correct requests for', ->
        testFeedWithOptions({cache: true})

        it 'should cache the headers', (done) ->
          setupFakeHxJson(['header1', 'header2', 'header3'], 'some-url', {type: 'headers', extra: undefined})
          jsonSpy = chai.spy.on(hx, 'json')
          feed = hx.dataTable.urlFeed('some-url', {cache: true})
          feed.headers (headers) ->
            headers.should.eql(['header1', 'header2', 'header3'])
            feed.headers (headers) ->
              headers.should.eql(['header1', 'header2', 'header3'])
              jsonSpy.should.have.been.called.once
              tearDownFakeHxJson()
              done()

        it 'should cache the totalCount', (done) ->
          setupFakeHxJson({count: 5}, 'some-url', {type: 'totalCount', extra: undefined})
          jsonSpy = chai.spy.on(hx, 'json')
          feed = hx.dataTable.urlFeed('some-url', {cache: true})
          feed.totalCount (totalCount) ->
            totalCount.should.equal(5)
            feed.totalCount (totalCount) ->
              totalCount.should.equal(5)
              jsonSpy.should.have.been.called.once
              tearDownFakeHxJson()
              done()

      describe 'with extra object passed in should make the correct requests for', ->
        testFeedWithOptions({extra: 'some-value'})



  describe 'fluid api', ->
    it 'should return a selection', ->
      hx.dataTable().should.be.an.instanceof(hx.Selection)

    it 'should not render if a feed is not defined', ->
      hx.dataTable().select('.hx-data-table-content').html().should.equal('')

    it 'should render if a feed is defined', ->
      hx.dataTable({feed: hx.dataTable.objectFeed(threeRowsData)}).select('.hx-data-table-content').selectAll('td').empty().should.equal(false)
