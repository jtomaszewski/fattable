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

  hasHeader: (j) -> false

  getCell: (i,j, cb=(->)) ->
    cb "getCell not implemented"

  getHeader: (j,cb=(->)) ->
    cb "getHeader not implemented"


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

  getHeaderSync: (j) ->
    # Override me !
    "col " + j

  hasCell: (i,j) -> true

  hasHeader: (j) -> true

  getCell: (i,j, cb=(->)) ->
    cb @getCellSync i,j

  getHeader: (j,cb=(->)) ->
    cb @getHeaderSync j


# Extend this class if you have access
# to your data in a page fashion
# and you want to use a LRU cache
class PagedAsyncTableModel extends TableModel
  constructor: (cacheSize=100) ->
    @pageCache = new LRUCache cacheSize
    @headerPageCache = new LRUCache cacheSize
    @fetchCallbacks = {}
    @headerFetchCallbacks = {}

  # Should return a string identifying your page.
  cellPageName: (i,j) ->
    # Override me

  # Should return a string identifying the page of the column.
  headerPageName: (j) ->
    # Override me

  getHeader: (j) ->
    pageName = @headerPageName j
    if @headerPageCache.has pageName
      cb @headerPageCache.get(pageName)(j)
    else if @headerFetchCallbacks[pageName]?
      @headerFetchCallbacks[pageName].push [j, cb ]
    else
      @headerFetchCallbacks[pageName] = [ [j, cb ] ]
      @fetchHeaderPage pageName, (page) =>
        @headerPageCache.set pageName, page
        for [j,cb] in @headerFetchCallbacks[pageName]
          cb page(j)
        delete @headerFetchCallbacks[pageName]

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

  getHeader: (j,cb=(->)) ->
    cb("col " + j)


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
  setupHeader: (headerDiv) ->

  # Will be called whenever a cell is
  # put out of the DOM
  cleanUpCell: (cellDiv) ->

  # Will be called whenever a column is
  # put out of the DOM
  cleanUpHeader: (headerDiv) ->

  cleanUp: (table) ->
    for _,cell of table.cells
      @cleanUpCell cell
    for _,header of table.columns
      @cleanUpHeader header

  # Fills and style a column div.
  fillHeader: (headerDiv, data) ->
    headerDiv.textContent = data

  # Fills and style a cell div.
  fillCell: (cellDiv, data) ->
    cellDiv.textContent = data

  # Mark a column header as pending.
  # Its content is not in cache
  # and needs to be fetched
  fillHeaderPending: (headerDiv) ->
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
  constructor: (@bodyContainer, @headerContainer, @totalWidth, @totalHeight, eventRegister, @visible=true, @enableDragMove=true) ->
    @verticalScrollbar = document.createElement "div"
    @verticalScrollbar.className += " fattable-v-scrollbar"
    @horizontalScrollbar = document.createElement "div"
    @horizontalScrollbar.className += " fattable-h-scrollbar"

    if @visible
      @bodyContainer.appendChild @verticalScrollbar
      @bodyContainer.appendChild @horizontalScrollbar

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
      eventRegister.bind @headerContainer, 'mousedown', (event) =>
        if event.button == 1
          @headerDragging = true
          @headerContainer.className = "fattable-header-container fattable-moving"
          @dragging_dX = @scrollLeft + event.clientX
      eventRegister.bind @bodyContainer, 'mouseup', (event) =>
        if event.button == 1
          @headerDragging = false
          @headerContainer.className = "fattable-header-container"
          # cancel click events
          # if we were actually dragging with the middle button.
          event.stopPropagation()
          captureClick = (e) ->
            e.stopPropagation()
            @removeEventListener 'click', captureClick, true
          @bodyContainer.addEventListener 'click', captureClick, true
      eventRegister.bind @headerContainer, 'mousemove', (event) =>
        # Firefox pb see https://bugzilla.mozilla.org/show_bug.cgi?id=732621
        deferred = =>
          if @headerDragging
            newX = -event.clientX + @dragging_dX
            @setScrollXY newX
        window.setTimeout deferred, 0
      eventRegister.bind @headerContainer, 'mouseout', (event) =>
        if @headerDragging
          if (not event.toElement?) || (event.toElement.parentElement.parentElement != @headerContainer)
            @headerContainer.className = "fattable-header-container"
          @headerDragging = false

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
    onMouseWheelHeader = (event) =>
      [deltaX, _] = getDelta event
      has_scrolled = @setScrollXY @scrollLeft - deltaX, @scrollTop
      if has_scrolled
        event.preventDefault()
    eventRegister.bind @bodyContainer, supportedEvent, onMouseWheel
    eventRegister.bind @headerContainer, supportedEvent, onMouseWheelHeader

    @scroller = new Scroller(@setScrollXY.bind(@), {
      # some options...
      # see https://github.com/zynga/scroller
    })
    @scroller.setDimensions(@scrollWidth, @scrollHeight, @totalWidth, @totalHeight)

    # touch events
    onTouchStart = (event) =>
      @__isTouchDown = true
      @scroller.doTouchStart(getEventTouches(event), event.timeStamp)
      event.preventDefault()

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
    @_readRequiredParameter parameters, "headerHeight"
    @_readRequiredParameter parameters, "scrollBarVisible", true
    @_readRequiredParameter parameters, "enableDragMove", true
    @_readRequiredParameter parameters, "colsOverlimit", 2
    @_readRequiredParameter parameters, "rowsOverlimit", 2

    @nbCols = @columnWidths.length
    if (" "+@container.className+" ").search(/\sfattable\s/) == -1
      @container.className += " fattable"
    @totalHeight = @rowHeight * @nbRows
    @columnOffset = cumsum @columnWidths
    @totalWidth = @columnOffset[@columnOffset.length-1]
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
    @scrollWidth = @container.offsetWidth
    @scrollHeight = @container.offsetHeight - @headerHeight
    @nbColsVisible = Math.min( smallest_diff_subsequence(@columnOffset, @scrollWidth) + @colsOverlimit, @columnWidths.length)
    @nbRowsVisible = Math.min( (@scrollHeight / @rowHeight | 0) + @rowsOverlimit, @nbRows)

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
    @headerContainer = null

  setup: ->
    @cleanUp()
    @calculateContainerDimensions()

    # can be called when resizing the window
    @columns = {}
    @cells = {}

    @container.innerHTML = ""

    # header container
    @headerContainer = document.createElement "div"
    @headerContainer.className += " fattable-header-container";
    @headerContainer.style.height = @headerHeight + "px";

    @headerViewport = document.createElement "div"
    @headerViewport.className = "fattable-viewport"
    @headerViewport.style.width = @scrollWidth + "px"
    @headerViewport.style.height = @headerHeight + "px"
    @headerContainer.appendChild @headerViewport

    # body container
    @bodyContainer = document.createElement "div"
    @bodyContainer.className = "fattable-body-container";
    @bodyContainer.style.top = @headerHeight + "px";

    @bodyViewport = document.createElement "div"
    @bodyViewport.className = "fattable-viewport"
    @bodyViewport.style.width = @scrollWidth + "px"
    @bodyViewport.style.height = @scrollHeight + "px"

    for j in [@nbColsVisible ... @nbColsVisible*2] by 1
      for i in [@nbRowsVisible...@nbRowsVisible*2] by 1
        el = document.createElement "div"
        @painter.setupCell el
        el.pending = false
        el.style.height = @rowHeight + "px"
        @bodyViewport.appendChild el
        @cells[i + "," + j] = el

    for c in [@nbColsVisible...@nbColsVisible*2] by 1
      el = document.createElement "div"
      el.style.height = @headerHeight + "px"
      el.pending = false
      @painter.setupHeader el
      @columns[c] = el
      @headerViewport.appendChild el

    @firstVisibleRow = @nbRowsVisible
    @firstVisibleColumn = @nbColsVisible
    @display 0,0
    @container.appendChild @bodyContainer
    @container.appendChild @headerContainer
    @bodyContainer.appendChild @bodyViewport
    @refreshAllContent()

    @scrollProxy = new ScrollBarProxy @bodyContainer, @headerContainer, @totalWidth, @totalHeight, @eventRegister, @scrollBarVisible, @enableDragMove
    @scrollProxy.onScroll = (x,y) =>
      [i,j] = @_findLeftTopCornerAtXY x,y
      @display i,j
      for _, col of @columns
        col.style[prefixedTransformCssKey] = "translate(" + (col.left - x) + "px, 0px)"
      for _, cell of @cells
        cell.style[prefixedTransformCssKey] = "translate(" + (cell.left - x) + "px," + (cell.top - y) + "px)"
      clearTimeout @scrollEndTimer
      @scrollEndTimer = setTimeout @refreshAllContent.bind(this), 200
      @onScroll x,y

    @scrollProxy.onScroll(0, 0)

  refreshAllContent: (evenNotPending=false) ->
    for j in [@firstVisibleColumn ... @firstVisibleColumn + @nbColsVisible] by 1
      header = @columns[j]
      do (header) =>
        if evenNotPending or header.pending
          @model.getHeader j, (data) =>
            header.pending = false
            @painter.fillHeader header, data
      for i in [@firstVisibleRow ... @firstVisibleRow + @nbRowsVisible] by 1
        k = i + "," + j
        cell = @cells[k]
        if evenNotPending or cell.pending
          do (cell) =>
            @model.getCell i,j,(data) =>
              cell.pending = false
              @painter.fillCell cell,data

  # Gets called when view has been scrolled to x,y .
  # You can replace this method, if you want.
  onScroll: (x,y) ->
    # console.debug "TableView.onScroll(#{x}, #{y})"

  goTo: (i,j) ->
    targetY = if i? then @rowHeight*i else undefined
    targetX = if j? then @columnOffset[j] else undefined
    @scrollProxy.setScrollXY targetX, targetY

  display: (i,j) ->
    @headerContainer.style.display = "none"
    @bodyContainer.style.display = "none"
    @moveX j
    @moveY i
    @headerContainer.style.display = ""
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
      header = @columns[orig_j]
      delete @columns[orig_j]
      if @model.hasHeader dest_j
        @model.getHeader dest_j, (data) =>
          header.pending = false
          @painter.fillHeader header, data
      else if not header.pending
        header.pending = true
        @painter.fillHeaderPending header
      header.left = col_x
      header.style.width = col_width
      @columns[dest_j] = header

      # move the cells.
      for i in [ last_i...last_i + @nbRowsVisible] by 1
        k =  i  + "," + orig_j
        cell = @cells[k]
        delete @cells[k]
        @cells[ i + "," + dest_j] = cell
        cell.left = col_x
        # cell.style.left = col_x
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
    di = Math.min( Math.abs(shift_i), @nbRowsVisible)
    for offset_i in [0 ... di ] by 1
      if shift_i>0
        orig_i = last_i + offset_i
        dest_i = i + offset_i + @nbRowsVisible - di
      else
        orig_i = last_i + @nbRowsVisible - di + offset_i
        dest_i = i + offset_i
      row_y = dest_i * @rowHeight
      # move the cells.
      for j in [last_j...last_j+@nbColsVisible] by 1
        k =  orig_i  + "," + j
        cell = @cells[k]
        delete @cells[k]
        @cells[ dest_i + "," + j] = cell
        cell.top = row_y
        do (cell) =>
          if @model.hasCell dest_i, j
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
