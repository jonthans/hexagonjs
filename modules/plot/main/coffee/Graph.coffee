hx.userFacingText({
  plot: {
    noData: 'No Data'
  }
})

# XXX: hard coded config values - move these to a config file for the graphing api
tickSize = 6
labelOffset = tickSize + 4
axisPadding = 4

class Graph extends hx.EventEmitter

  constructor: (@selector, options) ->
    super

    hx.component.register(@selector, this)

    @_ = {
      options: hx.shallowMerge({
        zoomRangeStart: 0,
        zoomRangeEnd: 1,
        labelsEnabled: true,
        legendsEnabled: false,
        legendLocation: 'auto',
        noDataText: hx.userFacingText('plot', 'noData')
        redrawOnResize: true
      }, options),
      axes: new hx.List
    }

    #XXX: move to the underscore object

    id = hx.randomId()

    selection = hx.select(@selector)

    selection.on 'resize', 'hx.plot', => if @_.options.redrawOnResize then @render()
    @svgTarget = selection.append("svg").attr('class', 'hx-graph')
    defs = @svgTarget.append('defs')
    @axesTarget = @svgTarget.append('g').attr('class', 'hx-axes')
    @plotTarget = @svgTarget.append('g').attr('class', 'hx-plot')

    # used to clip the drawing inside the graph
    clipPath = defs.append('clipPath').attr('id', 'clip-series-'+id)
    @clipRect = clipPath.append('rect')
    @plotTarget.attr('clip-path', 'url(#clip-series-'+id+')')

    touchX1 = 0
    touchX2 = 0
    savedZoomStart = 0
    savedZoomEnd = 1

    @svgTarget.on 'pointerdown', 'hx.plot', (p) =>
      x = Math.round(p.x - @svgTarget.box().left)
      y = Math.round(p.y - @svgTarget.box().top)
      updateLabels(this, x, y)

      if p.event.targetTouches and p.event.targetTouches.length > 1
        p.event.preventDefault()
        p.event.stopPropagation()
        touchX1 = p.event.targetTouches[0].clientX - @svgTarget.box().left - @plotArea.x1
        touchX2 = p.event.targetTouches[1].clientX - @svgTarget.box().left - @plotArea.x1
        savedZoomStart = @zoomRangeStart()
        savedZoomEnd = @zoomRangeEnd()

    threshold = 0.01

    @svgTarget.on 'touchmove', 'hx.plot', (e) =>
      if e.targetTouches.length > 1 and @zoomEnabled()
        e.preventDefault()
        e.stopPropagation()

        w = @plotArea.x2 - @plotArea.x1

        x1 = e.targetTouches[0].clientX - @svgTarget.box().left - @plotArea.x1
        x2 = e.targetTouches[1].clientX - @svgTarget.box().left - @plotArea.x1

        xn = (touchX1 + touchX2) / (2 * w)

        xhat = savedZoomStart + (savedZoomEnd - savedZoomStart) * xn

        z = Math.abs(touchX1 - touchX2) / Math.abs(x1 - x2)

        startFactor = (savedZoomStart - xhat)
        endFactor = (savedZoomEnd - xhat)
        if @zoomRangeEnd == 1 and startFactor > -threshold
          startFactor = -threshold
        if @zoomRangeStart() == 0 and endFactor < threshold
          endFactor = threshold
        @zoomRangeStart(hx.clampUnit(xhat + z * startFactor))
        @zoomRangeEnd(hx.clampUnit(xhat + z * endFactor))
        @emit('zoom', {start: @zoomRangeStart(), end: @zoomRangeEnd()})

        @render()

    @svgTarget.on 'mousemove', 'hx.plot', (p) =>
      x = Math.round(p.clientX - @svgTarget.box().left)
      y = Math.round(p.clientY - @svgTarget.box().top)
      if @labelsEnabled()
        updateLabels(this, x, y)

      if @legendEnabled()
        legendContainer = @svgTarget.select('.hx-legend-container')

        if @legendLocation() is 'hover'
          legendContainer.style('display', '')

        # update the legend position
        if (@legendLocation() is 'auto' || @legendLocation() is 'hover')

          if x - @plotArea.x1 < (@plotArea.x1 + @plotArea.x2) / 2
            # bottom-right
            legendContainer.attr('transform', 'translate(' + (@plotArea.x2 - 10 - legendContainer.width()) + ',' + (@plotArea.y1 + 10) + ')')
          else
            # top-left
            legendContainer.attr('transform', 'translate(' + (@plotArea.x1 + 10) + ',' + (@plotArea.y1 + 10) + ')')

    @svgTarget.on 'mouseleave', 'hx.plot', =>
      if @legendEnabled() && @legendLocation() is 'hover'
        @svgTarget.select('.hx-legend-container').style('display', 'none')

    @svgTarget.on 'pointerleave', 'hx.plot', (p) -> clearLabels()

    @svgTarget.on 'click', 'hx.plot', (p) =>
      x = Math.round(p.x - @svgTarget.box().left)
      y = Math.round(p.y - @svgTarget.box().top)
      labelMeta = getClosestMeta(this, x, y)
      if labelMeta
        data =
          event: p
          data: labelMeta.values
          series: labelMeta.series
        @emit 'click', data
        labelMeta.series.emit 'click', data

    @svgTarget.on 'wheel', 'hx.plot', (e) =>
      if @zoomEnabled()
        e.preventDefault()
        e.stopPropagation()

        threshold = 0.01

        delta = - e.deltaY
        if e.deltaMode is 1
          delta *= 20

        zoomRangeStart = @zoomRangeStart()
        zoomRangeEnd = @zoomRangeEnd()

        x = e.clientX - @svgTarget.box().left - @plotArea.x1
        w = @plotArea.x2 - @plotArea.x1
        xn = hx.clampUnit(x / w)
        xhat = zoomRangeStart + (zoomRangeEnd - zoomRangeStart) * xn
        z = 1 - delta / 600
        startFactor = (zoomRangeStart - xhat)
        endFactor = (zoomRangeEnd - xhat)
        if zoomRangeEnd == 1 and startFactor > -threshold
          startFactor = -threshold
        if zoomRangeStart == 0 and endFactor < threshold
          endFactor = threshold
        @zoomRangeStart(hx.clampUnit(xhat + z * startFactor))
        @zoomRangeEnd(hx.clampUnit(xhat + z * endFactor))
        @emit('zoom', {start: @zoomRangeStart(), end: @zoomRangeEnd()})

        @render()
    options?.axes?.forEach (axis) => @addAxis axis

  zoomRangeStart: optionSetterGetter('zoomRangeStart')
  zoomRangeEnd: optionSetterGetter('zoomRangeEnd')
  zoomEnabled: optionSetterGetter('zoomEnabled')
  labelsEnabled: optionSetterGetter('labelsEnabled')
  legendEnabled: optionSetterGetter('legendEnabled')
  legendLocation: optionSetterGetter('legendLocation')
  redrawOnResize: optionSetterGetter('redrawOnResize')

  axes: (axes) ->
    if arguments.length > 0
      @_.axes = new hx.List(axes)
      @axes().forEach (a) -> a.graph = this
      this
    else
      @_.axes.values()

  addAxis: (options) ->

    axis = if options instanceof Axis then options else new Axis(options)
    axis.graph = this
    @_.axes.add axis
    axis

  removeAxis: (axis) ->
    if @_.axes.remove(axis)
      axis.graph = null
      axis

  render: ->

    selection = hx.select(@selector)
    @width = Number(selection.width())
    @height = Number(selection.height())

    if @width <= 0 or @height <= 0 then return

    hasData = @axes().some (axis) ->
      axis.series().some (series) ->
        data = series.data()
        hx.isObject(data) or data.length > 0

    self = this
    @svgTarget.view('.hx-plot-no-data', 'text')
      .update ->
        @text(self._.options.noDataText)
        .attr('x', self.width/2)
        .attr('y', self.height/2)
      .apply(if hasData then [] else [true])

    # prepare the group data by tagging the series with group and series ids
    @axes().forEach((a) -> a.tagSeries())

    enter = (d) ->
      node = @append('g').class('hx-axis').node()
      d.setupAxisSvg(node)
      node

    # preprocessing step to get all the measurement details for the axes
    totalX = 0
    @axesTarget.view('.hx-axis', 'g')
      .enter(enter)
      .update (d, element) ->
        d.preupdateXAxisSvg(element)
        totalX += d.xAxisSize
      .apply(@axes())

    totalY = 0
    @axesTarget.view('.hx-axis', 'g')
      .enter(enter)
      .update (d, element) ->
        d.preupdateYAxisSvg(element, totalX)
        totalY += d.yAxisSize
      .apply(@axes())

    # draw the axes
    x = 0
    y = 0
    @axesTarget.view('.hx-axis', 'g')
      .enter(enter)
      .update (d, element) ->
        d.updateAxisSvg(element, y, x, totalY, totalX)
        x += d.xAxisSize
        y += d.yAxisSize
      .apply(@axes())

    # calculate the plot area. (the x and y are the correct way around here!)
    @plotArea = {
      x1: y,
      y1: 0,
      x2: @width,
      y2: @height - x
    }

    # dont render anything more if the plot area has no area - this is to prevent divide by 0 errors
    if ((@plotArea.x2-@plotArea.x1) <= 0) or ((@plotArea.y2-@plotArea.y1) <= 0) then return

    # draw the data
    @plotTarget.view('.hx-axis-data', 'g')
      .enter ->
        g = @append('g').class('hx-axis-data')
        g.append('g').class('hx-graph-fill-layer')
        g.append('g').class('hx-graph-sparse-layer')
        g.node()
      .update (d, element) ->
        d.updateDataSvg(
          @select('.hx-graph-fill-layer').node(),
          @select('.hx-graph-sparse-layer').node()
        )
      .apply(@axes())

    if @legendEnabled()
      legendContainer = @svgTarget.select('.hx-legend-container')
      if legendContainer.size() == 0
        legendContainer = @svgTarget.append('g').class('hx-legend-container')

      # collect up the series and update the legend container
      populateLegendSeries(legendContainer, hx.flatten(@axes().map((axis) -> axis.series())))

      switch @legendLocation()
        when 'top-left'
          legendContainer.attr('transform', 'translate(' + (@plotArea.x1 + 10) + ',' + (@plotArea.y1 + 10) + ')')
        when 'bottom-right'
          legendContainerTransformX = @plotArea.x2 - 10 - legendContainer.width()
          legendContainerTransformY = @plotArea.y2 - 5 - legendContainer.height()
          legendContainer.attr('transform', 'translate(' + legendContainerTransformX + ',' + legendContainerTransformY + ')')
        when 'bottom-left'
          legendContainer.attr('transform', 'translate(' + (@plotArea.x1 + 10) + ',' + (@plotArea.y2 - 5 - legendContainer.height()) + ')')
        when 'hover'
          legendContainer.style('display', 'none')
        else
          legendContainer.attr('transform', 'translate(' + (@plotArea.x2 - 10 - legendContainer.width()) + ',' + (@plotArea.y1 + 10) + ')')

    else
      @svgTarget.select('.hx-legend-container').remove()

    # recalculate the clip path for the plot area
    @clipRect
      .attr('x', @plotArea.x1)
      .attr('y', @plotArea.y1)
      .attr('width', @plotArea.x2 - @plotArea.x1)
      .attr('height', @plotArea.y2 - @plotArea.y1)

    @emit 'render'
    this

  getClosestMeta = (graph, x, y) ->
    x = hx.clamp(graph.plotArea.x1, graph.plotArea.x2, x)
    y = hx.clamp(graph.plotArea.y1, graph.plotArea.y2, y)

    labels = hx.flatten graph.axes().map (axis) -> axis.getLabelDetails x, y

    labels = labels.filter (label) ->
      graph.plotArea.x1 <= label.x <= graph.plotArea.x2 and graph.plotArea.y1 <= label.y <= graph.plotArea.y2

    bestMeta = undefined
    bestDistance = undefined
    for l in labels
      xx = l.x - x
      yy = l.y - y
      distance = xx*xx + yy*yy

      if bestDistance==undefined or distance < bestDistance
        bestMeta = l
        bestDistance = distance

    bestMeta

  clearLabels = () ->
    hx.select('body')
      .select('.hx-plot-label-container')
      .clear()

  updateLabels = (graph, x, y) ->

    updateLabel = (data, element) ->
      hx.select(element)
        .style('left', Math.round(window.pageXOffset + graph.svgTarget.box().left + data.x) + 'px')
        .style('top', Math.round(window.pageYOffset + graph.svgTarget.box().top + data.y) + 'px')

      data.series.labelRenderer()(element, data)

    bestMeta = getClosestMeta(graph, x, y)

    if hx.select('body').select('.hx-plot-label-container').empty()
      hx.select('body').append('div').class('hx-plot-label-container')

    hx.select('body')
      .select('.hx-plot-label-container')
      .view('.hx-plot-label', 'div')
        .update(updateLabel)
        .apply(if bestMeta then boundLabel(bestMeta, graph) else [])

