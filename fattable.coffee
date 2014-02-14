
cumsum = (arr)->
    cs = [ 0.0 ]
    s = 0.0
    for x in arr
        s += x
        cs.push s
    cs

isReady = false
isReadyCallbacks = []

document.addEventListener "DOMContentLoaded", =>
    document.removeEventListener "DOMContentLoaded", arguments.callee


bound = (x, m, M)->
    if (x < m) then m else if (x > M) then M else x

class Promise

    constructor: ->
        @callbacks = []
        @result = false
        @resolved = false

    then: (cb)->
        if @resolved
            cb @result
        else
            @callbacks.push cb

    resolve: (result)->
        @resolved = true
        @result = result
        for cb in @callbacks
            cb result

domReadyPromise = new Promise()

document.addEventListener "DOMContentLoaded", ->
    document.removeEventListener "DOMContentLoaded", arguments.callee
    domReadyPromise.resolve()

class TableData

    hasCell: (i,j)-> false

    hasColumn: (j)-> false

    getCell: (i,j, cb=(->))->
        deferred = ->
            cb(i + "," + j)
        setTimeout deferred, 100

    getHeader: (j,cb=(->))->
        cb("col " + j)

class SyncTableData extends TableData
    # Extends this class if you 
    # don't need to access your data in a asynchronous 
    # fashion (e.g. via ajax).
    # 
    # You only need to override
    # getHeaderSync and getCellSync
    
    getCellSync: (i,j)->
        # Override me !
        i + "," + j
    getHeaderSync: (j)->
        # Override me !
        "col " + j
    
    hasCell: (i,j)-> true

    hasColumn: (j)-> true

    getCell: (i,j, cb=(->))->
        cb ("cell" + i + "," + j)

    getHeader: (j,cb=(->))->
        cb ("col " + j)



class LRUCache

    constructor: (@size=100)->
        @data = {}
        @lru_keys = []

    has: (k)->
        # Returns true if the key k is 
        # already in the cache.
        @data.hasOwnProperty k

    get: (k)->
        # If key k is in the cache,
        # calls cb immediatly with  as arguments
        #    - v, the value associated to k
        #    - k, the key requested for.loca
        # if not, cb will be called
        # asynchronously.
        #if @data.hasOwnProperty(k)
        @data[k]
    
    set: (k,v)->
        idx = @lru_keys.indexOf k
        if idx >= 0
            @lru_keys.splice idx, 1
        @lru_keys.push k
        if @lru_keys.length >= @size
            removeKey = @lru_keys.shift()
            delete @data[removeKey]
        @data[k] = v



class PagedAsyncTableData extends TableData
    # Extend this class if you have access
    # to your data in a page fashion 
    # and you want to use a LRU cache
    constructor: (cacheSize=100)->
        @pageCache = new LRUCache cacheSize
        @fetchCallbacks = {}

    cellPageName: (i,j)->
        # Override me
        # Should return a string identifying your page.
        

    hasCell: (i,j)->
        pageName = @cellPageName i,j
        @pageCache.has pageName

    getCell: (i,j, cb=(->))->
        pageName = @cellPageName i,j
        if @pageCache.has pageName
            cb @pageCache.get(pageName)(i,j)
        else if @fetchCallbacks[pageName]?
            @fetchCallbacks[pageName].push [i, j, cb ]
        else
            @fetchCallbacks[pageName] = [ [i, j, cb ] ]
            @fetchCellPage pageName, (page)=>
                for [i,j,cb] in @fetchCallbacks[pageName]
                    cb page(i,j)
                delete @fetchCallbacks[pageName]
                @pageCache.set pageName, page

    fetchCellPage: (pageName, cb)->
        # override this
        # a page is a function that 
        # returns the cell value for any (i,j)
        [I,J] = JSON.parse pageName
        page = (i,j)->
            pageName + ":" + (i - I) + "," + (j - J)
        window.setTimeout (-> cb page), 500 

    hasColumn: (j)->
        true
    
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
            if not @dragging
                @scrollLeft = @horizontalScrollbar.scrollLeft
                @onScrollXY @scrollLeft,@scrollTop
        @verticalScrollbar.onscroll = =>
            if not @dragging
                @scrollTop = @verticalScrollbar.scrollTop
                @onScrollXY @scrollLeft,@scrollTop

        # setting up middle click drag
        @container.addEventListener 'mousedown', (evt)=>
            if evt.button == 1
                @dragging = true
                @container.className = "fattable-body-container fattable-moving"
                @dragging_dX = @scrollLeft + evt.clientX
                @dragging_dY = @scrollTop + evt.clientY
        @container.addEventListener 'mouseup', =>
            @dragging = false
            @container.className = "fattable-body-container"
        @container.addEventListener 'mousemove', (evt)=>
            if @dragging
                newX = -evt.clientX + @dragging_dX
                newY = -evt.clientY + @dragging_dY
                @setScrollXY newX, newY
        @container.addEventListener 'mouseout', (evt)=>
            if @dragging
                if (evt.toElement == null) || (evt.toElement.parentElement.parentElement != @container)
                    @container.className = "fattable-body-container"
                    @dragging = false
        if @W > @horizontalScrollbar.clientWidth
            @maxScrollHorizontal = @W - @horizontalScrollbar.clientWidth
        else
            @maxScrollHorizontal = 0

        if @H > @verticalScrollbar.clientHeight
            @maxScrollVertical = @H - @verticalScrollbar.clientHeight
        else
            @maxScrollVertical = 0
        
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
        x = bound(x, 0, @maxScrollHorizontal)
        y = bound(y, 0, @maxScrollVertical)
        @scrollLeft = x
        @scrollTop = y
        @horizontalScrollbar.scrollLeft = x
        @verticalScrollbar.scrollTop = y
        @onScrollXY x,y

class TableView

    readRequiredParameter: (parameters, k, default_value)->
        if not parameters[k]?
            if default_value == undefined
                throw "Expected parameter <" + k + ">"
            else
                this[k] = default_value
        else
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
            throw "Container must be a string or a dom element."

        @readRequiredParameter parameters, "painter", new CellPainter()
        @readRequiredParameter parameters, "data"
        @readRequiredParameter parameters, "nbRows"
        @readRequiredParameter parameters, "rowHeight"
        @readRequiredParameter parameters, "columnWidths"
        @readRequiredParameter parameters, "rowHeight"
        @readRequiredParameter parameters, "headerHeight"
        @nbCols = @columnWidths.length
        @container.className += " fattable"
        @H = @rowHeight * @nbRows
        @columnOffset = cumsum @columnWidths
        @W = @columnOffset[@columnOffset.length-1]
        domReadyPromise.then => @setup()
        window.addEventListener "resize", => @setup()

    visible: (x,y)->
        # returns the square
        #   [ i_a -> i_b ]  x  [ j_a, j_b ]
        i = bound (y / @rowHeight | 0), 0, (@nbRows - @nbRowsVisible)
        j = bound binary_search(@columnOffset, x), 0, (@nbCols - @nbColsVisible)
        [i, j]

    setup: ->
        # can be called when resizing the window
        @columns = {}
        @cells = {}

        @container.innerHTML = ""
        @w = @container.offsetWidth
        @h = @container.offsetHeight - @headerHeight
        @nbColsVisible = Math.min( smallest_diff_subsequence(@columnOffset, @w) + 2, @columnWidths.length)
        @nbRowsVisible = (@h / @rowHeight | 0) + 2

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
            @painter.setupColumnHeader el
            @columns[c] = el
            @headerViewport.appendChild el
        @firstVisibleRow = @nbRowsVisible
        @firstVisibleColumn = @nbColsVisible
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
        for j in [@firstVisibleColumn ... @firstVisibleColumn + @nbColsVisible] by 1
            columnHeader = @columns[j]
            do (columnHeader)=>
                if columnHeader.pending
                    @data.getHeader j, (data)=>
                        columnHeader.pending = false
                        @painter.fillColumnHeader columnHeader, data
            for i in [@firstVisibleRow ... @firstVisibleRow + @nbRowsVisible] by 1
                k = i+ ","+j
                cell = @cells[k]
                if cell.pending
                    do (cell)=>
                        @data.getCell i,j,(data)=>
                            cell.pending = false
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
        last_j = @firstVisibleColumn
        shift_j = j - last_j
        if shift_j == 0
            return
        dj = Math.min( Math.abs(shift_j), @nbColsVisible)

        for offset_j in [0 ... dj ] by 1
            if shift_j>0
                orig_j = @firstVisibleColumn + offset_j
                dest_j = j + offset_j + @nbColsVisible - dj
            else
                orig_j = @firstVisibleColumn + @nbColsVisible - dj + offset_j
                dest_j = j + offset_j 
            col_x = @columnOffset[dest_j] + "px"
            col_width = @columnWidths[dest_j] + "px"

            # move the column header
            columnHeader = @columns[orig_j]
            delete @columns[orig_j]
            if @data.hasColumn dest_j
                @data.getHeader dest_j, (data)=>
                    columnHeader.pending = false
                    @painter.fillColumnHeader columnHeader, data
            else if not columnHeader.pending
                columnHeader.pending = true
                @painter.fillColumnHeaderPending columnHeader
            columnHeader.style.left = col_x
            columnHeader.style.width = col_width
            @columns[dest_j] = columnHeader

            # move the cells.
            for i in [ last_i...last_i+@nbRowsVisible] by 1
                k =  i  + "," + orig_j
                cell = @cells[k]
                delete @cells[k]
                @cells[ i + "," + dest_j] = cell
                cell.style.left = col_x
                cell.style.width = col_width
                do (cell)=>
                    if @data.hasCell(i, dest_j)
                        @data.getCell i, dest_j, (data)=>
                            cell.pending = false
                            @painter.fillCell cell, data
                    else if not cell.pending
                        cell.pending = true
                        @painter.fillCellPending cell
        @firstVisibleColumn = j

    moveY: (i)->
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
            row_y = dest_i * @rowHeight + "px"
            # move the cells.
            for j in [last_j...last_j+@nbColsVisible] by 1
                k =  orig_i  + "," + j
                cell = @cells[k]
                delete @cells[k]
                @cells[ dest_i + "," + j] = cell
                cell.style.top = row_y
                do (cell)=>
                    if @data.hasCell dest_i, j
                        @data.getCell dest_i, j, (data)=>
                            cell.pending = false
                            @painter.fillCell cell, data
                    else if not cell.pending
                        cell.pending = true
                        @painter.fillCellPending cell
        @firstVisibleRow = i


fattable = (params)->
    new TableView params

ns =
    TableData: TableData
    TableView: TableView
    CellPainter: CellPainter
    PagedAsyncTableData: PagedAsyncTableData
    SyncTableData: SyncTableData
    bound: bound

for k,v of ns
    fattable[k] = v

window.fattable = fattable
