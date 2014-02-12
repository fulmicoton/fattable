
cumsum = (arr)->
    cs = arr[...]
    cs[0] = 0.0
    s = 0.0
    for i in [0...arr.length - 1] by 1
        s += arr[i]
        cs[i+1] = s
    cs

do_nothing = ->

class TableData

    hasCell: (i,j)->
        true

    hasColumn: (j)->
        true

    getCell: (i,j, cb=do_nothing)->
        #deferred = ->
        cb(i + "," + j)
        #setTimeout deferred, 100

    getHeader: (j,cb=do_nothing)->
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

    setupCell: (cell_div)->
        # Setup method are called at the creation
        # of the cells. That is during initialization
        # and for all window resize event.
        # 
        # Cells are recycled.

    setupColumnHeader: (col_div)->
        # Setup method are called at the creation
        # of the column header. That is during
        # initialization and for all window resize
        # event.
        #
        # Columns are recycled.

    fillColumnHeader: (col_div, data)->
        # Fills and style a column div.
        col_div.textContent = data

    fillCell: (cell_div, data)->
        # Fills and style a cell div.
        cell_div.textContent = data

    fillColumnHeaderPending: (cell_div)->
        # Mark a column header as pending.
        # Its content is not in cache
        # and needs to be fetched
        cell_div.textContent = "NA"

    fillCellPending: (cell_div)->
        # Mark a cell content as pending
        # Its content is not in cache and 
        # needs to be fetched
        cell_div.textContent = "NA"


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

class TableView

    readRequiredParameter: (parameters, k, type)->
        if not parameters[k]?
            throw "Expected parameter <"+k +">"
        this[k] = parameters[k]

    constructor: (parameters)->
        #
        # container, @painter, @data, @layout
        #
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

        # setting up middle click drag
        @bodyContainer.addEventListener 'mousedown', (evt)=>
            if evt.button == 1
                @moving = true
                @moving_dX = @bodyContainer.scrollLeft + evt.x
                @moving_dY = @bodyContainer.scrollTop + evt.y
        @bodyContainer.addEventListener 'mouseup', => @moving = false
        @bodyContainer.addEventListener 'mousemove', (evt)=>
            if @moving
                x = @bodyContainer.scrollLeft
                y = @bodyContainer.scrollTop
                @bodyContainer.scrollLeft = -evt.x + @moving_dX
                @bodyContainer.scrollTop = -evt.y + @moving_dY
        @bodyContainer.addEventListener 'mouseout', (evt)=>
            if (evt.toElement == null)
                @moving = false
        @viewport = document.createElement "div"
        @viewport.className = "fattable-viewport"
        @viewport.style.width = @W + "px"
        @viewport.style.height = @H + "px"

        for j in [-@nbColsVisible...0] by 1
            for i in [-@nb_rows_visible...0] by 1
                el = document.createElement "div"
                @painter.setupCell el
                @viewport.appendChild el
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
        @bodyContainer.appendChild @viewport
        @bodyContainer.onscroll = =>
            x = @bodyContainer.scrollLeft
            y = @bodyContainer.scrollTop
            [i,j] = @visible x,y
            @goTo i,j
            @headerViewport.style.left = -x + "px"
            clearTimeout @scrollEndTimer    
            @scrollEndTimer = setTimeout @on_scrollend.bind(this), 200
        @on_scrollend()

    on_scrollend: ->
        # for j in [@lastVisibleRow ... @lastVisibleRow + @nbColsVisible] by 1
        #     columnHeader = @columns[j]
        #     do (columnHeader)=>
        #         @data.getHeader j, (data)=>
        #             @painter.fillColumnHeader columnHeader, data
        #     for i in [@firstVisibleRow ... @firstVisibleRow + @nb_rows_visible] by 1
        #         k = i+ ","+j
        #         cell = @cells[k]
        #         do (cell)=>
        #             @data.getCell i,j,(data)=>
        #                 @painter.fillCell cell,data


    goTo: (i,j)->
        @headerContainer.style.display = "none"
        @bodyContainer.style.display = "none"
        @move_x j
        @move_y i
        @headerContainer.style.display = ""
        @bodyContainer.style.display = ""

    move_x: (j)->
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

    move_y: (i)->
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

    update_cell_contents: ->
        for j in [@lastVisibleRow ... @lastVisibleRow + @nbColsVisible] by 1
            for i in [@firstVisibleRow ... @firstVisibleRow + @nb_rows_visible] by 1
                k =  i  + "," + j
                cell = @cell[k]
                if cell.pending
                    @data.getCell i,j,(data)=>
                        @painter.fillCell cell,data
                        cell.pending = false

window.TableData = TableData
window.TableView = TableView
window.CellPainter = CellPainter

