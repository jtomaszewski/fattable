"use strict"

# =====
# UTILS
# =====

cumsum = (arr) ->
  cs = [ 0.0 ]
  s = 0.0
  for x in arr
    s += x
    cs.push s
  cs

bound = (x, m, M) ->
  if (x < m) then m else if (x > M) then M else x

binary_search = (arr, x) ->
  if arr[0] > x
    0
  else
    a = 0
    b = arr.length
    while (a + 2 < b)
      m = (a+b) / 2 | 0
      v = arr[m]
      if v < x
        a = m
      else if v > x
        b = m
      else
        return m
    return a

distance = (a1, a2) ->
  Math.abs(a2-a1)

closest = (x, vals...) ->
  d = Infinity
  res = undefined
  for x_ in vals
    d_ = distance x,x_
    if d_ < d
      d = d_
      res = x_
  res

# Given an array of positive increasing integers arr
# and an integer totalWidth, return the smallest integer l
# such that arr_{x+l} - arr_{x} is always greater than scrollWidth.
#
# If no such l exists, just return arr.length
smallest_diff_subsequence = (arr, scrollWidth) ->
  l = 1
  start = 0
  while start + l < arr.length
    if arr[start+l] - arr[start] > scrollWidth
      start += 1
    else
      l += 1
  return l

prefixedTransformCssKey = (->
  el = document.createElement "div"
  for testKey in ["transform", "WebkitTransform", "MozTransform", "OTransform", "MsTransform"]
    if el.style[testKey] != undefined
      return testKey)()

class LRUCache
  constructor: (@size=100) ->
    @data = {}
    @lru_keys = []

  # Returns true if the key k is
  # already in the cache.
  has: (k) ->
    @data.hasOwnProperty k

  # If key k is in the cache,
  # calls cb immediatly with  as arguments
  #    - v, the value associated to k
  #    - k, the key requested for.loca
  # if not, cb will be called
  # asynchronously.
  #if @data.hasOwnProperty(k)
  get: (k) ->
    @data[k]

  set: (k,v) ->
    idx = @lru_keys.indexOf k
    if idx >= 0
      @lru_keys.splice idx, 1
    @lru_keys.push k
    if @lru_keys.length >= @size
      removeKey = @lru_keys.shift()
      delete @data[removeKey]
    @data[k] = v

# This method can get coordinates for both a mouse click
# or a touch depending on the given event
getEventPointerCoordinates = (event) ->
  c =
    x: 0
    y: 0
  if event
    touches = if event.touches and event.touches.length then event.touches else [ event ]
    e = event.changedTouches and event.changedTouches[0] or touches[0]
    if e
      c.x = e.clientX or e.pageX or 0
      c.y = e.clientY or e.pageY or 0
  c

getEventTouches = (e) ->
  if e.touches and e.touches.length then e.touches else [ {
    pageX: e.pageX
    pageY: e.pageY
  } ]

# =====
# Fattable CODE
# =====


class TableModel
  hasCell: (i,j) -> false

  hasColumnHeader: (j) -> false

  hasRowHeader: (i) -> false

  getCell: (i,j, cb=(->)) ->
    cb "getCell not implemented"

  getColumnHeader: (j,cb=(->)) ->
    cb "getColumnHeader not implemented"

  getRowHeader: (i,cb=(->)) ->
    cb "getRowHeader not implemented"


# Extend this class if you
# don't need to access your data in a asynchronous
# fashion (e.g. via ajax).
#
# You only need to override
# getHeaderSync and getCellSync
class SyncTableModel extends TableModel
  getCellSync: (i,j) ->
    # Override me !
    i + "," + j

  getColumnHeaderSync: (j) ->
    # Override me !
    "col " + j

  getRowHeaderSync: (i) ->
    # Override me !
    "row " + i

  hasCell: (i,j) -> true

  hasColumnHeader: (j) -> true

  hasRowHeader: (i) -> true

  getCell: (i,j, cb=(->)) ->
    cb @getCellSync i,j

  getColumnHeader: (j,cb=(->)) ->
    cb @getColumnHeaderSync j

  getRowHeader: (i,cb=(->)) ->
    cb @getRowHeaderSync i


# Extend this class if you have access
# to your data in a page fashion
# and you want to use a LRU cache
class PagedAsyncTableModel extends TableModel
  constructor: (cacheSize=100) ->
    @pageCache = new LRUCache cacheSize
    @columnHeaderPageCache = new LRUCache cacheSize
    @rowHeaderPageCache = new LRUCache cacheSize
    @fetchCallbacks = {}
    @columnHeaderFetchCallbacks = {}
    @rowHeaderFetchCallbacks = {}

  # Should return a string identifying your page.
  cellPageName: (i,j) ->
    # Override me

  # Should return a string identifying the page of the column.
  columnHeaderPageName: (j) ->
    # Override me

  # Should return a string identifying the page of the column.
  rowHeaderPageName: (i) ->
    # Override me

  getColumnHeader: (j) ->
    pageName = @columnHeaderPageName j
    if @columnHeaderPageCache.has pageName
      cb @columnHeaderPageCache.get(pageName)(j)
    else if @columnHeaderFetchCallbacks[pageName]?
      @columnHeaderFetchCallbacks[pageName].push [j, cb ]
    else
      @columnHeaderFetchCallbacks[pageName] = [ [j, cb ] ]
      @fetchColumnHeaderPage pageName, (page) =>
        @columnHeaderPageCache.set pageName, page
        for [j,cb] in @columnHeaderFetchCallbacks[pageName]
          cb page(j)
        delete @columnHeaderFetchCallbacks[pageName]

  getRowHeader: (i) ->
    pageName = @rowHeaderPageName i
    if @rowHeaderPageCache.has pageName
      cb @rowHeaderPageCache.get(pageName)(i)
    else if @rowHeaderFetchCallbacks[pageName]?
      @rowHeaderFetchCallbacks[pageName].push [i, cb ]
    else
      @rowHeaderFetchCallbacks[pageName] = [ [i, cb ] ]
      @fetchRowHeaderPage pageName, (page) =>
        @rowHeaderPageCache.set pageName, page
        for [i,cb] in @rowHeaderFetchCallbacks[pageName]
          cb page(i)
        delete @rowHeaderFetchCallbacks[pageName]

  hasCell: (i,j) ->
    pageName = @cellPageName i,j
    @pageCache.has pageName

  getCell: (i,j, cb=(->)) ->
    pageName = @cellPageName i,j
    if @pageCache.has pageName
      cb @pageCache.get(pageName)(i,j)
    else if @fetchCallbacks[pageName]?
      @fetchCallbacks[pageName].push [i, j, cb ]
    else
      @fetchCallbacks[pageName] = [ [i, j, cb ] ]
      @fetchCellPage pageName, (page) =>
        @pageCache.set pageName, page
        for [i,j,cb] in @fetchCallbacks[pageName]
          cb page(i,j)
        delete @fetchCallbacks[pageName]

  fetchCellPage: (pageName, cb) ->
    # override this
    # a page is a function that
    # returns the cell value for any (i,j)

  fetchColumnHeaderPage: (pageName, cb) ->
    # override this

  fetchRowHeaderPage: (pageName, cb) ->
    # override this


# The cell painter tells how
# to fill, and style cells.
# Do not set height or width.
# in either fill and setup methods.
class Painter
  # Setup method are called at the creation
  # of the cells. That is during initialization
  # and for all window resize event.
  #
  # Cells are recycled.
  setupCell: (cellDiv) ->

  # Setup method are called at the creation
  # of the column header. That is during
  # initialization and for all window resize
  # event.
  #
  # Columns are recycled.
  setupColumnHeader: (headerDiv) ->

  setupRowHeader: (headerDiv) ->

  # Will be called whenever a cell is
  # put out of the DOM
  cleanUpCell: (cellDiv) ->

  # Will be called whenever a column is
  # put out of the DOM
  cleanUpColumnHeader: (headerDiv) ->

  cleanUpRowHeader: (headerDiv) ->

  cleanUp: (table) ->
    for _,cell of table.cells
      @cleanUpCell cell
    for _,header of table.columns
      @cleanUpColumnHeader header
    for _,header of table.rows
      @cleanUpRowHeader header

  # Fills and style a column div.
  fillColumnHeader: (headerDiv, data) ->
    headerDiv.textContent = data

  # Fills and style a row div.
  fillRowHeader: (headerDiv, data) ->
    headerDiv.textContent = data

  # Fills and style a cell div.
  fillCell: (cellDiv, data) ->
    cellDiv.textContent = data

  # Mark a column header as pending.
  # Its content is not in cache
  # and needs to be fetched
  fillColumnHeaderPending: (headerDiv) ->
    headerDiv.textContent = "NA"

  # Mark a row header as pending.
  # Its content is not in cache
  # and needs to be fetched
  fillRowHeaderPending: (headerDiv) ->
    headerDiv.textContent = "NA"

  # Mark a cell content as pending
  # Its content is not in cache and
  # needs to be fetched
  fillCellPending: (cellDiv) ->
    cellDiv.textContent = "NA"


class EventRegister
  constructor: ->
    @boundEvents = []

  bind: (target, event, cb) ->
    @boundEvents.push [target, event, cb]
    target.addEventListener event, cb

  unbindAll: ->
    for [target, event, cb] in @boundEvents
      target.removeEventListener event, cb
    @boundEvents = []


class ScrollBarProxy
  constructor: (@bodyContainer, @columnHeaderContainer, @rowHeaderContainer, @totalWidth, @totalHeight, eventRegister, @horizontalScrollbarVisible=true, @verticalScrollbarVisible=true, @enableDragMove=true) ->
    @verticalScrollbar = document.createElement "div"
    @verticalScrollbar.className += " fattable-v-scrollbar"
    @verticalScrollbar.style.visibility = "hidden" if !@verticalScrollbarVisible
    @horizontalScrollbar = document.createElement "div"
    @horizontalScrollbar.className += " fattable-h-scrollbar"
    @horizontalScrollbar.style.visibility = "hidden" if !@horizontalScrollbarVisible

    @bodyContainer.appendChild @horizontalScrollbar
    @bodyContainer.appendChild @verticalScrollbar

    bigContentHorizontal = document.createElement "div"
    bigContentHorizontal.style.height = 1 + "px";
    bigContentHorizontal.style.width = @totalWidth + "px";
    bigContentVertical = document.createElement "div"
    bigContentVertical.style.width = 1 + "px";
    bigContentVertical.style.height = @totalHeight + "px";

    @horizontalScrollbar.appendChild bigContentHorizontal
    @verticalScrollbar.appendChild bigContentVertical

    @scrollbarMargin = Math.max @horizontalScrollbar.offsetHeight, @verticalScrollbar.offsetWidth
    @verticalScrollbar.style.bottom = @scrollbarMargin + "px";
    @horizontalScrollbar.style.right = @scrollbarMargin + "px";

    @scrollLeft = 0
    @scrollTop  = 0
    @horizontalScrollbar.onscroll = =>
      if not @dragging
        if @scrollLeft != @horizontalScrollbar.scrollLeft
          @scrollLeft = @horizontalScrollbar.scrollLeft
          @onScroll @scrollLeft, @scrollTop
    @verticalScrollbar.onscroll = =>
      if not @dragging
        if @scrollTop != @verticalScrollbar.scrollTop
          @scrollTop = @verticalScrollbar.scrollTop
          @onScroll @scrollLeft, @scrollTop

    if @enableDragMove
      # setting up middle click drag
      eventRegister.bind @bodyContainer, 'mousedown', (event) =>
        if event.button == 1
          @dragging = true
          @bodyContainer.className = "fattable-body-container fattable-moving"
          @dragging_dX = @scrollLeft + event.clientX
          @dragging_dY = @scrollTop + event.clientY
      eventRegister.bind @bodyContainer, 'mouseup', (event) =>
        @dragging = false
        @bodyContainer.className = "fattable-body-container"

      eventRegister.bind @bodyContainer, 'mousemove', (event) =>
        # Firefox pb see https://bugzilla.mozilla.org/show_bug.cgi?id=732621
        deferred = =>
          if @dragging
            newX = -event.clientX + @dragging_dX
            newY = -event.clientY + @dragging_dY
            @setScrollXY newX, newY
        window.setTimeout deferred, 0
      eventRegister.bind @bodyContainer, 'mouseout', (event) =>
        if @dragging
          if (not event.toElement?) || (event.toElement.parentElement.parentElement != @bodyContainer)
            @bodyContainer.className = "fattable-body-container"
            @dragging = false

      # setting up middle click drag on head container
      # (refactor this)
      eventRegister.bind @columnHeaderContainer, 'mousedown', (event) =>
        if event.button == 1
          @columnHeaderDragging = true
          @columnHeaderContainer.className = "fattable-header-container fattable-column-header-container fattable-moving"
          @dragging_dX = @scrollLeft + event.clientX

      eventRegister.bind @rowHeaderContainer, 'mousedown', (event) =>
        if event.button == 1
          @rowHeaderDragging = true
          @rowHeaderContainer.className = "fattable-header-container fattable-row-header-container fattable-moving"
          @dragging_dY = @scrollTop + event.clientY

      eventRegister.bind @bodyContainer, 'mouseup', (event) =>
        if event.button == 1
          @columnHeaderDragging = false
          @rowHeaderDragging = false
          @columnHeaderContainer.className = "fattable-header-container"
          # cancel click events
          # if we were actually dragging with the middle button.
          event.stopPropagation()
          captureClick = (e) ->
            e.stopPropagation()
            @removeEventListener 'click', captureClick, true
          @bodyContainer.addEventListener 'click', captureClick, true

      eventRegister.bind @columnHeaderContainer, 'mousemove', (event) =>
        # Firefox pb see https://bugzilla.mozilla.org/show_bug.cgi?id=732621
        deferred = =>
          if @columnHeaderDragging
            newX = -event.clientX + @dragging_dX
            @setScrollXY newX
        window.setTimeout deferred, 0
      eventRegister.bind @columnHeaderContainer, 'mouseout', (event) =>
        if @columnHeaderDragging
          if (not event.toElement?) || (event.toElement.parentElement.parentElement != @columnHeaderContainer)
            @columnHeaderContainer.className = "fattable-header-container fattable-column-header-container"
          @columnHeaderDragging = false

      eventRegister.bind @rowHeaderContainer, 'mousemove', (event) =>
        # Firefox pb see https://bugzilla.mozilla.org/show_bug.cgi?id=732621
        deferred = =>
          if @rowHeaderDragging
            newY = -event.clientY + @dragging_dY
            @setScrollXY undefined, newY
        window.setTimeout deferred, 0
      eventRegister.bind @rowHeaderContainer, 'mouseout', (event) =>
        if @rowHeaderDragging
          if (not event.toElement?) || (event.toElement.parentElement.parentElement != @rowHeaderContainer)
            @rowHeaderContainer.className = "fattable-header-container fattable-row-header-container"
          @rowHeaderDragging = false

    if @totalWidth > @horizontalScrollbar.clientWidth
      @maxScrollHorizontal = @totalWidth - @horizontalScrollbar.clientWidth
    else
      @maxScrollHorizontal = 0

    if @totalHeight > @verticalScrollbar.clientHeight
      @maxScrollVertical = @totalHeight - @verticalScrollbar.clientHeight
    else
      @maxScrollVertical = 0

    supportedEvent = "DOMMouseScroll"
    if @bodyContainer.onwheel != undefined
      supportedEvent = "wheel"
    else if @bodyContainer.onmousewheel != undefined
      supportedEvent = "mousewheel"

    getDelta = (->
      switch supportedEvent
        when "wheel"
          (event) ->
            switch event.deltaMode
              when event.DOM_DELTA_LINE
                deltaX = -50*event.deltaX ? 0
                deltaY = -50*event.deltaY ? 0
              when event.DOM_DELTA_PIXEL
                deltaX = -1*event.deltaX ? 0
                deltaY = -1*event.deltaY ? 0
            [deltaX, deltaY]
        when "mousewheel"
          (event) ->
            deltaX = 0
            deltaY = 0
            deltaX = event.wheelDeltaX ? 0
            deltaY = event.wheelDeltaY ? event.wheelDelta
            [deltaX, deltaY]
        when "DOMMouseScroll"
          (event) ->
            deltaX = 0
            deltaY = 0
            if event.axis == event.HORIZONTAL_AXI then deltaX = -50.0*event.detail else deltaY = -50.0*event.detail
            [deltaX, deltaY]
    )()

    # mouse scroll events
    onMouseWheel = (event) =>
      [deltaX, deltaY] = getDelta event
      has_scrolled = @setScrollXY @scrollLeft - deltaX, @scrollTop - deltaY
      if has_scrolled
        event.preventDefault()

    onMouseWheelColumnHeader = (event) =>
      [deltaX, _] = getDelta event
      has_scrolled = @setScrollXY @scrollLeft - deltaX, @scrollTop
      if has_scrolled
        event.preventDefault()

    onMouseWheelRowHeader = (event) =>
      [_, deltaY] = getDelta event
      has_scrolled = @setScrollXY @scrollLeft, @scrollTop - deltaY
      if has_scrolled
        event.preventDefault()

    eventRegister.bind @bodyContainer, supportedEvent, onMouseWheel
    eventRegister.bind @columnHeaderContainer, supportedEvent, onMouseWheelColumnHeader
    eventRegister.bind @rowHeaderContainer, supportedEvent, onMouseWheelRowHeader

    @scroller = new Scroller(@setScrollXY.bind(@), {
      # some options...
      # see https://github.com/zynga/scroller
    })
    @scroller.setDimensions(@scrollWidth, @scrollHeight, @totalWidth, @totalHeight)

    # touch events
    onTouchStart = (event) =>
      @__isTouchDown = true
      @scroller.doTouchStart(getEventTouches(event), event.timeStamp)
      # event.preventDefault()

    onTouchMove = (event) =>
      @scroller.doTouchMove(getEventTouches(event), event.timeStamp, event.scale)
      @__isTouchDown = true

    onTouchEnd = (event) =>
      return if !@__isTouchDown
      @scroller.doTouchEnd(event.timeStamp)
      @__isTouchDown = false

    if `'ontouchstart' in window`
      eventRegister.bind @bodyContainer, "touchstart", onTouchStart
      eventRegister.bind @bodyContainer, "touchmove", onTouchMove
      eventRegister.bind @bodyContainer, "touchend", onTouchEnd
      eventRegister.bind @bodyContainer, "touchcancel", onTouchEnd
    else if window.navigator.pointerEnabled
      eventRegister.bind @bodyContainer, "pointerdown", onTouchStart
      eventRegister.bind @bodyContainer, "pointermove", onTouchMove
      eventRegister.bind @bodyContainer, "pointerup", onTouchEnd
      eventRegister.bind @bodyContainer, "pointercancel", onTouchEnd
    else if window.navigator.msPointerEnabled
      eventRegister.bind @bodyContainer, "MSPointerDown", onTouchStart
      eventRegister.bind @bodyContainer, "MSPointerMove", onTouchMove
      eventRegister.bind @bodyContainer, "MSPointerUp", onTouchEnd
      eventRegister.bind @bodyContainer, "MSPointerCancel", onTouchEnd

  # Gets called when the view has been scrolled to x,y coordinates.
  onScroll: (x,y) ->
    # This method is replaced by TableView class

  # returns true if we actually scrolled
  # false is returned if for instance we
  # reached the bottom of the scrolling area.
  setScrollXY: (x,y) ->
    has_scrolled = false
    if x?
      x = bound(x, 0, @maxScrollHorizontal)
      if @scrollLeft != x
        has_scrolled = true
        @scrollLeft = x
    else
      x = @scrollLeft
    if y?
      y = bound(y, 0, @maxScrollVertical)
      if @scrollTop != y
        has_scrolled = true
        @scrollTop = y
    else
      y = @scrollTop
    @horizontalScrollbar.scrollLeft = x
    @verticalScrollbar.scrollTop = y
    @onScroll x,y
    has_scrolled


class TableView
  constructor: (parameters) ->
    container = parameters.container

    if not container?
      throw "container not specified."
    if typeof container == "string"
      @container = document.querySelector container
    else if typeof container == "object"
      @container = container
    else
      throw "Container must be a string or a dom element."

    @_readRequiredParameter parameters, "painter", new Painter()
    @_readRequiredParameter parameters, "autoSetup", true
    @_readRequiredParameter parameters, "model"
    @_readRequiredParameter parameters, "nbRows"
    @_readRequiredParameter parameters, "rowHeight"
    @_readRequiredParameter parameters, "columnWidths"
    @_readRequiredParameter parameters, "nbColsOverdraw", 2
    @_readRequiredParameter parameters, "nbRowsOverdraw", 2
    @_readRequiredParameter parameters, "columnHeaderHeight"
    @_readRequiredParameter parameters, "rowHeaderWidth"
    @_readRequiredParameter parameters, "scrollBarVisible", true
    @_readRequiredParameter parameters, "horizontalScrollbar", @scrollBarVisible
    @_readRequiredParameter parameters, "verticalScrollbar", @scrollBarVisible
    @_readRequiredParameter parameters, "enableDragMove", true

    @nbCols = @columnWidths.length
    if (" "+@container.className+" ").search(/\sfattable\s/) == -1
      @container.className += " fattable"
    @totalHeight = @rowHeight * @nbRows
    @columnOffset = cumsum @columnWidths
    @totalWidth = @columnOffset[@columnOffset.length-1]
    @rows = {}
    @columns = {}
    @cells = {}
    @eventRegister = new EventRegister()
    @calculateContainerDimensions()

    @setup() if @autoSetup

  _readRequiredParameter: (parameters, k, default_value) ->
    if not parameters[k]?
      if default_value == undefined
        throw "Expected parameter <" + k + ">"
      else
        this[k] = default_value
    else
      this[k] = parameters[k]

  calculateContainerDimensions: ->
    @scrollWidth = @container.offsetWidth - @rowHeaderWidth
    @scrollHeight = @container.offsetHeight - @columnHeaderHeight
    @nbColsVisible = Math.min( smallest_diff_subsequence(@columnOffset, @scrollWidth) + @nbColsOverdraw, @columnWidths.length)
    @nbRowsVisible = Math.min( (@scrollHeight / @rowHeight | 0) + @nbRowsOverdraw, @nbRows)
    @horizontalScrollbar = false if @totalWidth <= @scrollWidth
    @verticalScrollbar = false if @totalHeight <= @scrollHeight

  _findLeftTopCornerAtXY: (x,y) ->
    # returns the square
    #   [ i_a -> i_b ]  x  [ j_a, j_b ]
    i = bound (y / @rowHeight | 0), 0, (@nbRows - @nbRowsVisible)
    j = bound binary_search(@columnOffset, x), 0, (@nbCols - @nbColsVisible)
    [i, j]

  cleanUp: ->
    # be nice rewind !
    @eventRegister.unbindAll()
    @scrollProxy?.onScroll = null
    @painter.cleanUp this
    @container.innerHTML = ""
    @bodyContainer = null
    @columnHeaderContainer = null
    @rowHeaderContainer = null

  setup: ->
    @cleanUp()
    @calculateContainerDimensions()

    # can be called when resizing the window
    @columns = {}
    @rows = {}
    @cells = {}

    @container.innerHTML = ""

    # column header container
    @columnHeaderContainer = document.createElement "div"
    @columnHeaderContainer.className += " fattable-header-container fattable-column-header-container"
    @columnHeaderContainer.style.width = @scrollWidth + "px"
    @columnHeaderContainer.style.height = @columnHeaderHeight + "px"
    @columnHeaderContainer.style.left = @rowHeaderWidth + "px"

    @columnHeaderViewport = document.createElement "div"
    @columnHeaderViewport.className = "fattable-viewport"
    @columnHeaderViewport.style.height = @columnHeaderHeight + "px"
    @columnHeaderContainer.appendChild @columnHeaderViewport

    # row header container
    @rowHeaderContainer = document.createElement "div"
    @rowHeaderContainer.className += " fattable-header-container fattable-row-header-container"
    @rowHeaderContainer.style.height = @scrollHeight + "px"
    @rowHeaderContainer.style.width = @rowHeaderWidth + "px"
    @rowHeaderContainer.style.top = @columnHeaderHeight + "px"

    @rowHeaderViewport = document.createElement "div"
    @rowHeaderViewport.className = "fattable-viewport"
    @rowHeaderContainer.appendChild @rowHeaderViewport

    # body container
    @bodyContainer = document.createElement "div"
    @bodyContainer.className = "fattable-body-container"
    @bodyContainer.style.width = @scrollWidth + "px"
    @bodyContainer.style.top = @columnHeaderHeight + "px"
    @bodyContainer.style.left = @rowHeaderWidth + "px"

    @bodyViewport = document.createElement "div"
    @bodyViewport.className = "fattable-viewport"
    @bodyViewport.style.height = @scrollHeight + "px"

    for j in [@nbColsVisible...@nbColsVisible*2] by 1
      el = document.createElement "div"
      el.style.height = @columnHeaderHeight + "px"
      el.pending = false
      @painter.setupColumnHeader el
      @columns[j] = el
      @columnHeaderViewport.appendChild el

    for i in [@nbRowsVisible...@nbRowsVisible*2] by 1
      el = document.createElement "div"
      el.style.width = @rowHeaderWidth + "px"
      el.pending = false
      @painter.setupRowHeader el
      @rows[i] = el
      @rowHeaderViewport.appendChild el

    for j in [@nbColsVisible ... @nbColsVisible*2] by 1
      for i in [@nbRowsVisible...@nbRowsVisible*2] by 1
        el = document.createElement "div"
        @painter.setupCell el
        el.pending = false
        el.style.height = @rowHeight + "px"
        @bodyViewport.appendChild el
        @cells[i + "," + j] = el

    @firstVisibleRow = @nbRowsVisible
    @firstVisibleColumn = @nbColsVisible
    @display 0,0
    @container.appendChild @bodyContainer
    @container.appendChild @columnHeaderContainer
    @container.appendChild @rowHeaderContainer
    @bodyContainer.appendChild @bodyViewport
    @refreshAllContent()

    @scrollProxy = new ScrollBarProxy @bodyContainer, @columnHeaderContainer, @rowHeaderContainer, @totalWidth, @totalHeight, @eventRegister, @horizontalScrollbar, @verticalScrollbar, @enableDragMove
    @scrollProxy.onScroll = (x,y) =>
      [i,j] = @_findLeftTopCornerAtXY x,y
      @display i,j
      for _, cell of @cells
        cell.style[prefixedTransformCssKey] = "translate(" + (cell.left - x) + "px," + (cell.top - y) + "px)"
      for _, col of @columns
        col.style[prefixedTransformCssKey] = "translate(" + (col.left - x) + "px, 0px)"
      for _, row of @rows
        row.style[prefixedTransformCssKey] = "translate(0px, " + (row.top - y) + "px)"
      clearTimeout @scrollEndTimer
      @scrollEndTimer = setTimeout @refreshAllContent.bind(this), 200
      @onScroll x,y

    @scrollProxy.onScroll(0, 0)

  resize: ->
    {scrollLeft, scrollTop} = @scrollProxy
    @setup()
    @scrollProxy.setScrollXY(scrollLeft, scrollTop)

  refreshAllContent: (evenNotPending=false) ->
    for j in [@firstVisibleColumn ... @firstVisibleColumn + @nbColsVisible] by 1
      columnHeader = @columns[j]
      do (columnHeader) =>
        if evenNotPending or columnHeader.pending
          @model.getColumnHeader j, (data) =>
            columnHeader.pending = false
            @painter.fillColumnHeader columnHeader, data

      for i in [@firstVisibleRow ... @firstVisibleRow + @nbRowsVisible] by 1
        k = i + "," + j
        cell = @cells[k]
        if evenNotPending or cell.pending
          do (cell) =>
            @model.getCell i,j,(data) =>
              cell.pending = false
              @painter.fillCell cell,data

    for i in [@firstVisibleRow ... @firstVisibleRow + @nbRowsVisible] by 1
      rowHeader = @rows[i]
      do (rowHeader) =>
        if evenNotPending or rowHeader.pending
          @model.getRowHeader i, (data) =>
            rowHeader.pending = false
            @painter.fillRowHeader rowHeader, data

  # Gets called when view has been scrolled to x,y .
  # You can replace this method, if you want.
  onScroll: (x,y) ->
    # console.debug "TableView.onScroll(#{x}, #{y})"

  goTo: (i,j) ->
    targetY = if i? then @rowHeight*i else undefined
    targetX = if j? then @columnOffset[j] else undefined
    @scrollProxy.setScrollXY targetX, targetY

  display: (i,j) ->
    @columnHeaderContainer.style.display = "none"
    @rowHeaderContainer.style.display = "none"
    @bodyContainer.style.display = "none"
    @moveX j
    @moveY i
    @columnHeaderContainer.style.display = ""
    @rowHeaderContainer.style.display = ""
    @bodyContainer.style.display = ""

  moveX: (j) ->
    last_i = @firstVisibleRow
    last_j = @firstVisibleColumn
    shift_j = j - last_j
    if shift_j == 0
      return
    dj = Math.min(Math.abs(shift_j), @nbColsVisible)

    for offset_j in [0 ... dj ] by 1
      if shift_j>0
        orig_j = @firstVisibleColumn + offset_j
        dest_j = j + offset_j + @nbColsVisible - dj
      else
        orig_j = @firstVisibleColumn + @nbColsVisible - dj + offset_j
        dest_j = j + offset_j
      col_x = @columnOffset[dest_j]
      col_width = @columnWidths[dest_j] + "px"

      # move the column header
      columnHeader = @columns[orig_j]
      delete @columns[orig_j]
      if @model.hasColumnHeader dest_j
        @model.getColumnHeader dest_j, (data) =>
          columnHeader.pending = false
          @painter.fillColumnHeader columnHeader, data
      else if not columnHeader.pending
        columnHeader.pending = true
        @painter.fillColumnHeaderPending columnHeader
      columnHeader.left = col_x
      columnHeader.style.width = col_width
      @columns[dest_j] = columnHeader

      # move the cells.
      for i in [ last_i...last_i + @nbRowsVisible] by 1
        k =  i  + "," + orig_j
        cell = @cells[k]
        delete @cells[k]
        @cells[ i + "," + dest_j] = cell
        cell.left = col_x
        cell.style.width = col_width
        do (cell) =>
          if @model.hasCell(i, dest_j)
            @model.getCell i, dest_j, (data) =>
              cell.pending = false
              @painter.fillCell cell, data
          else if not cell.pending
            cell.pending = true
            @painter.fillCellPending cell

    @firstVisibleColumn = j

  moveY: (i) ->
    last_i = @firstVisibleRow
    last_j = @firstVisibleColumn
    shift_i = i - last_i
    if shift_i == 0
      return
    di = Math.min(Math.abs(shift_i), @nbRowsVisible)

    for offset_i in [0 ... di ] by 1
      if shift_i>0
        orig_i = @firstVisibleRow + offset_i
        dest_i = i + offset_i + @nbRowsVisible - di
      else
        orig_i = @firstVisibleRow + @nbRowsVisible - di + offset_i
        dest_i = i + offset_i
      row_y = dest_i * @rowHeight

      # move the row header
      rowHeader = @rows[orig_i]
      delete @rows[orig_i]
      if @model.hasRowHeader dest_i
        @model.getRowHeader dest_i, (data) =>
          rowHeader.pending = false
          @painter.fillRowHeader rowHeader, data
      else if not rowHeader.pending
        rowHeader.pending = true
        @painter.fillRowHeaderPending rowHeader
      rowHeader.top = row_y
      @rows[dest_i] = rowHeader

      # move the cells.
      for j in [ last_j...last_j + @nbColsVisible] by 1
        k =  orig_i  + "," + j
        cell = @cells[k]
        delete @cells[k]
        @cells[ dest_i + "," + j] = cell
        cell.top = row_y
        do (cell) =>
          if @model.hasCell(dest_i, j)
            @model.getCell dest_i, j, (data) =>
              cell.pending = false
              @painter.fillCell cell, data
          else if not cell.pending
            cell.pending = true
            @painter.fillCellPending cell

    @firstVisibleRow = i

fattable = (params) ->
  new TableView params

ns =
  TableModel: TableModel
  TableView: TableView
  Painter: Painter
  PagedAsyncTableModel: PagedAsyncTableModel
  SyncTableModel: SyncTableModel

for k,v of ns
  fattable[k] = v

window.fattable = fattable
