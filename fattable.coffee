
cumsum = (arr)->
    cs = arr[...]
    cs[0] = 0.0
    s = 0.0
    for i in [0...arr.length - 1] by 1
        s += arr[i]
        cs[i+1] = s
    cs

class TableData

    hasCell: (i,j)->
        false

    hasColumn: (j)->
        false

    getCell: (i,j, cb=(->))->
        deferred = ->
            cb(i + "," + j)
        setTimeout deferred, 100

    getHeader: (j,cb=(->))->
        cb("col " + j)

binary_search = (arr, x)->

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

distance = (a1, a2)->
    Math.abs(a2-a1)

closest = (x, vals...)->
    d = Infinity
    res = undefined
    for x_ in vals
        d_ = distance x,x_
        if d_ < d
            d = d_
            res = x_
    res

class LRUCache

    constructor: (fetcher, @size=100)->
        @data = {}
        @lru_keys = []

    has: (k)->
        # Returns true if the key k is 
        # already in the cache.
        @data.hasOwnProperty k

    get: (k, cb)->
        # If key k is in the cache,
        # calls cb immediatly with  as arguments
        #    - v, the value associated to k
        #    - k, the key requested for.loca
        # if not, cb will be called
        # asynchronously.
        if @data.hasOwnProperty(k)
            cb @data[k], k
        else
            fetcher k, (v)=>
                idx = @lru_keys.indexOf k
                if idx >= 0
                    @lru_keys.splice idx, 1
                @lru_keys.push k
                if @lru_keys.length >= @size
                    removeKey = @lru_keys.shift()
                    delete @data[removeKey]
                @data[k] = v
                cb v, k

class PageTableData

    constructor: ->


class CellPainter

    # The cell painter tells how 
    # to fill, and style cells.
    # Do not set height or width.
    # in either fill and setup methods.

    setupCell: (cellDiv)->
        # Setup method are called at the creation
        # of the cells. That is during initialization
        # and for all window resize event.
        # 
        # Cells are recycled.

    setupColumnHeader: (colHeaderDiv)->
        # Setup method are called at the creation
        # of the column header. That is during
        # initialization and for all window resize
        # event.
        #
        # Columns are recycled.

    fillColumnHeader: (colHeaderDiv, data)->
        # Fills and style a column div.
        colHeaderDiv.textContent = data

    fillCell: (cellDiv, data)->
        # Fills and style a cell div.
        cellDiv.textContent = data

    fillColumnHeaderPending: (cellDiv)->
        # Mark a column header as pending.
        # Its content is not in cache
        # and needs to be fetched
        cellDiv.textContent = "NA"

    fillCellPending: (cellDiv)->
        # Mark a cell content as pending
        # Its content is not in cache and 
        # needs to be fetched
        cellDiv.textContent = "NA"


smallest_diff_subsequence = (arr, w)->
    # Given an array of positive increasing integers arr
    # and an integer W, return the smallest integer l
    # such that arr_{x+l} - arr_{x} is always greater than w.
    # 
    # If no such l exists, just return arr.length
    l = 1
    start = 0
    while start + l < arr.length
        if arr[start+l] - arr[start] > w
            start += 1
        else
            l += 1
    return l




class ScrollBarProxy

    constructor: (@container, @W, @H)->
        @verticalScrollbar = document.createElement "div"
        @verticalScrollbar.className += " fattable-v-scrollbar"
        @horizontalScrollbar = document.createElement "div"
        @horizontalScrollbar.className += " fattable-h-scrollbar"
        @container.appendChild @verticalScrollbar
        @container.appendChild @horizontalScrollbar

        bigContentHorizontal = document.createElement "div"
        bigContentHorizontal.style.height = 1 + "px";
        bigContentHorizontal.style.width = @W + "px";
        bigContentVertical = document.createElement "div"
        bigContentVertical.style.width = 1 + "px";
        bigContentVertical.style.height = @H + "px";

        @horizontalScrollbar.appendChild bigContentHorizontal
        @verticalScrollbar.appendChild bigContentVertical

        @scrollLeft = 0
        @scrollTop  = 0
        @horizontalScrollbar.onscroll = =>
            @scrollLeft = @horizontalScrollbar.scrollLeft
            @onScrollXY @scrollLeft,@scrollTop
        @verticalScrollbar.onscroll = =>
            @scrollTop = @verticalScrollbar.scrollTop
            @onScrollXY @scrollLeft,@scrollTop

        # setting up middle click drag
        @container.addEventListener 'mousedown', (evt)=>
            if evt.button == 1
                @moving = true
                @moving_dX = @scrollLeft + evt.clientX
                @moving_dY = @scrollTop + evt.clientY
        @container.addEventListener 'mouseup', =>
            @moving = false
        @container.addEventListener 'mousemove', (evt)=>
            if @moving
                newX = -evt.clientX + @moving_dX
                newY = -evt.clientY + @moving_dY
                @setScrollXY newX, newY
        @container.addEventListener 'mouseout', (evt)=>
            if @moving
                if (evt.toElement == null) || (evt.toElement.parentElement.parentElement != @container)
                    @moving = false

        onMouseWheel = (evt)=>
            # TODO support other browsers
            if evt.type is "mousewheel"
                @setScrollXY @scrollLeft, @scrollTop - evt.wheelDelta

        if @container.addEventListener
            @container.addEventListener "mousewheel", onMouseWheel, false
            @container.addEventListener "DOMMouseScroll", onMouseWheel, false
        else @container.attachEvent "onmousewheel", onMouseWheel
    
    onScrollXY: (x,y)->

    setScrollXY: (x,y)->
        x = Math.max(x,0)
        x = Math.min(x,@W)
        y = Math.max(y,0)
        y = Math.min(y,@H)
        onScrollXY = @onScrollXY
        @onScrollXY = ->
        @scrollLeft = x
        @scrollTop = y
        @horizontalScrollbar.scrollLeft = x
        @verticalScrollbar.scrollTop = y
        @onScrollXY x,y
        @onScrollXY = onScrollXY


class TableView

    readRequiredParameter: (parameters, k, type)->
        if not parameters[k]?
            throw "Expected parameter <"+k +">"
        this[k] = parameters[k]

    constructor: (parameters)->
        container = parameters.container

        if not container?
            throw "container not specified."
        if typeof container == "string"
            @container = document.querySelector container
        else if typeof container == "object"
            @container = container
        else
            throw "container must be a string or a dom element."

        @readRequiredParameter parameters, "painter"
        @readRequiredParameter parameters, "data"
        @readRequiredParameter parameters, "nbRows"
        @readRequiredParameter parameters, "rowHeight"
        @readRequiredParameter parameters, "columnWidths"
        @readRequiredParameter parameters, "rowHeight"
        @readRequiredParameter parameters, "headerHeight"
        @nbCols = @columnWidths.length
              
        @container.className += " fattable"
        @H = @rowHeight * @nbRows
        @col_offset = cumsum @columnWidths
        @W = @col_offset[@col_offset.length-1]
        document.addEventListener "DOMContentLoaded", =>
            document.removeEventListener "DOMContentLoaded", arguments.callee
            @setup()
        window.addEventListener "resize", => @setup()

    visible: (x,y)->
        # returns the square
        #   [ i_a -> i_b ]  x  [ j_a, j_b ]
        j = binary_search @col_offset, x
        i = (y / @rowHeight | 0)
        [i, j]

    setup: ->
        # can be called when resizing the window
        @columns = {}
        @cells = {}

        @container.innerHtml = ""
        @w = @container.offsetWidth
        @h = @container.offsetHeight - @headerHeight
        @nbColsVisible = smallest_diff_subsequence(@col_offset, @w) + 2
        @nb_rows_visible = (@h / @rowHeight | 0) + 2

        # header container
        @headerContainer = document.createElement "div"
        @headerContainer.className += " fattable-header-container";
        @headerContainer.style.height = @headerHeight + "px";
        
        @headerViewport = document.createElement "div"
        @headerViewport.className = "fattable-viewport"
        @headerViewport.style.width = @W + "px"
        @headerViewport.style.height = @headerHeight + "px"
        @headerContainer.appendChild @headerViewport

        # body container 
        @bodyContainer = document.createElement "div"
        @bodyContainer.className = "fattable-body-container";
        @bodyContainer.style.top = @headerHeight + "px";

        @bodyViewport = document.createElement "div"
        @bodyViewport.className = "fattable-viewport"
        @bodyViewport.style.width = @W + "px"
        @bodyViewport.style.height = @H + "px"

        for j in [-@nbColsVisible...0] by 1
            for i in [-@nb_rows_visible...0] by 1
                el = document.createElement "div"
                @painter.setupCell el
                @bodyViewport.appendChild el
                @cells[i + "," + j] = el

        for c in [-@nbColsVisible...0] by 1
            el = document.createElement "div"
            @painter.setupColumnHeader el
            @columns[c] = el
            @headerViewport.appendChild el

        @firstVisibleRow = -@nb_rows_visible
        @lastVisibleRow = -@nbColsVisible
        @goTo 0,0
        @container.appendChild @bodyContainer
        @container.appendChild @headerContainer
        @bodyContainer.appendChild @bodyViewport
        @refreshAllContent()
        @scrollBarProxy = new ScrollBarProxy @bodyContainer, @W, @H
        @scrollBarProxy.onScrollXY = (x,y)=>
            [i,j] = @visible x,y
            @goTo i,j
            @headerViewport.style.left = -x + "px"
            @bodyViewport.style.left = -x + "px";
            @bodyViewport.style.top = -y + "px";
            clearTimeout @scrollEndTimer    
            @scrollEndTimer = setTimeout @refreshAllContent.bind(this), 200

    refreshAllContent: ->
        for j in [@lastVisibleRow ... @lastVisibleRow + @nbColsVisible] by 1
            columnHeader = @columns[j]
            do (columnHeader)=>
                @data.getHeader j, (data)=>
                    @painter.fillColumnHeader columnHeader, data
            for i in [@firstVisibleRow ... @firstVisibleRow + @nb_rows_visible] by 1
                k = i+ ","+j
                cell = @cells[k]
                do (cell)=>
                    @data.getCell i,j,(data)=>
                        @painter.fillCell cell,data

    goTo: (i,j)->
        @headerContainer.style.display = "none"
        @bodyContainer.style.display = "none"
        @moveX j
        @moveY i
        @headerContainer.style.display = ""
        @bodyContainer.style.display = ""

    moveX: (j)->
        last_i = @firstVisibleRow
        last_j = @lastVisibleRow
        shift_j = j - last_j
        if shift_j == 0
            return
        dj = Math.min( Math.abs(shift_j), @nbColsVisible)
        for offset_j in [0 ... dj ] by 1
            if shift_j>0
                orig_j = @lastVisibleRow + offset_j
                dest_j = j + offset_j + @nbColsVisible - dj
            else
                orig_j = @lastVisibleRow + @nbColsVisible - dj + offset_j
                dest_j = j + offset_j 
            col_x = @col_offset[dest_j] + "px"
            col_width = @columnWidths[dest_j] + "px"

            # move the column header
            columnHeader = @columns[orig_j]
            delete @columns[orig_j]
            if @data.hasColumn dest_j
                @data.getHeader dest_j, (data)=>
                    @painter.fillColumnHeader columnHeader, data
            else if not columnHeader.pending
                columnHeader.pending = false
                @painter.fillColumnHeaderPending columnHeader
            columnHeader.style.left = col_x
            columnHeader.style.width = col_width
            @columns[dest_j] = columnHeader

            # move the cells.
            for i in [ last_i...last_i+@nb_rows_visible]
                k =  i  + "," + orig_j
                cell = @cells[k]
                delete @cells[k]
                @cells[ i + "," + dest_j] = cell
                cell.style.left = col_x
                cell.style.width = col_width
                do (cell)=>
                    if @data.hasCell(i, dest_j)
                        @data.getCell i, dest_j, (data)=>
                            @painter.fillCell cell, data
                    else if not cell.pending
                        cell.pending = true
                        @painter.fillCellPending cell
        @lastVisibleRow = j

    moveY: (i)->
        last_i = @firstVisibleRow
        last_j = @lastVisibleRow
        shift_i = i - last_i
        if shift_i == 0
            return
        di = Math.min( Math.abs(shift_i), @nb_rows_visible)
        for offset_i in [0 ... di ] by 1
            if shift_i>0
                orig_i = last_i + offset_i
                dest_i = i + offset_i + @nb_rows_visible - di
            else
                orig_i = last_i + @nb_rows_visible - di + offset_i
                dest_i = i + offset_i
            row_y = dest_i * @rowHeight + "px"
            # move the cells.
            for j in [last_j...last_j+@nbColsVisible]
                k =  orig_i  + "," + j
                cell = @cells[k]
                delete @cells[k]
                @cells[ dest_i + "," + j] = cell
                cell.style.top = row_y
                @data.getCell dest_i, j, (data)=>
                    cell.pending = false
                    @painter.fillCell cell, data
                do (cell)=>
                    if @data.hasCell dest_i, j
                        @data.getCell dest_i, j, (data)=>
                            cell.pending = false
                            @painter.fillCell cell, data
                    else if not cell.pending
                        cell.pending = true
                        @painter.fillCellPending cell
        @firstVisibleRow = i

window.TableData = TableData
window.TableView = TableView
window.CellPainter = CellPainter
