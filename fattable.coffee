

sum = (arr)->
    s = 0
    for x in arr
        s += x
    s

cumsum = (arr)->
    cs = arr[...]
    cs[0] = 0.0
    s = 0.0
    for i in [0...arr.length - 1] by 1
        s += arr[i]
        cs[i+1] = s
    cs

class TableData
    # TODO make it asynchronous
    constructor: (@_nb_rows, @_nb_cols)->
    get: (i,j)->
        i + "," + j
    header: (i)->
        "col " + i
    nb_cols: ->
        @_nb_cols
    nb_rows: ->
        @_nb_rows

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


min_width_subarray = (cumsum, l)->
    s = Infinity
    for i in [0...cumsum.length - 1 - l]
        w = cumsum[i+l] - cumsum[i]
        if w < s
            s = w
    s

class TableView

    constructor: (container, @data, @layout)->
        if typeof container == "string"
            @container = document.querySelector container
        else
            @container = container
        @container.className += " fattable"
        @nb_cols = @data.nb_cols()
        @nb_rows = @data.nb_rows()
        @W = sum @layout.column_widths
        @row_height  = @layout.row_height
        @H = @layout.row_height * @nb_rows
        @col_offset = cumsum @layout.column_widths
        document.addEventListener "DOMContentLoaded", =>
            document.removeEventListener "DOMContentLoaded", arguments.callee
            @setup()
        window.addEventListener "resize", => @setup()


    compute_nb_columns: ->
        M = Math.min.apply null, @layout.column_widths
        for l in [M ... 1]
            w = min_width_subarray @col_offset, l
            if w < @w
                return l + 1

    visible: (x,y)->
        # returns the square
        #   [ i_a -> i_b ]  x  [ j_a, j_b ]
        j = binary_search @col_offset, x
        i = (y / @layout.row_height | 0)
        [i, j]

    setup: ->
        # can be called when resizing the window
        @columns = {}
        @cells = {}

        @container.innerHtml = ""
        @w = @container.offsetWidth
        @h = @container.offsetHeight - @layout.header_height

        @nb_cols_visible = @compute_nb_columns()
        @nb_rows_visible = (@h / @layout.row_height | 0) + 2

        # header container
        @headerContainer = document.createElement "div"
        @headerContainer.className += " fattable-header-container";
        @headerContainer.style.height = @layout.header_height + "px";
        
        @headerViewport = document.createElement "div"
        @headerViewport.className = "fattable-viewport"
        @headerViewport.style.width = @W + "px"
        @headerViewport.style.height = @layout.header_height + "px"
        @headerContainer.appendChild @headerViewport

        # body container 
        @bodyContainer = document.createElement "div"
        @bodyContainer.className = "fattable-body-container";
        @bodyContainer.style.top = @layout.header_height + "px";

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

        for j in [-@nb_cols_visible...0] by 1
            for i in [-@nb_rows_visible...0] by 1
                el = document.createElement "div"
                @viewport.appendChild el
                @cells[i + "," + j] = el

        for c in [-@nb_cols_visible...0] by 1
            el = document.createElement "div"
            @columns[c] = el
            @headerViewport.appendChild el

        @last_i = -@nb_rows_visible
        @last_j = -@nb_cols_visible
        @goTo 0,0
        @container.appendChild @bodyContainer
        @container.appendChild @headerContainer
        @bodyContainer.appendChild @viewport

        me = this
        @bodyContainer.onscroll = ->
            x = @scrollLeft
            y = @scrollTop
            [i,j] = me.visible x,y
            me.goTo i,j
            me.headerViewport.style.left = -x + "px"

    goTo: (i,j)->
        @headerContainer.style.display = "none"
        @bodyContainer.style.display = "none"
        @move_x j
        @move_y i
        @headerContainer.style.display = ""
        @bodyContainer.style.display = ""

    move_x: (j)->
        last_i = @last_i
        last_j = @last_j
        shift_j = j - last_j
        if shift_j == 0
            return
        dj = Math.min( Math.abs(shift_j), @nb_cols_visible)
        for offset_j in [0 ... dj ] by 1
            if shift_j>0
                orig_j = @last_j + offset_j
                dest_j = j + offset_j + @nb_cols_visible - dj
            else
                orig_j = @last_j + @nb_cols_visible - dj + offset_j
                dest_j = j + offset_j 
            col_x = @col_offset[dest_j] + "px"
            col_width = @layout.column_widths[dest_j] + "px"

            # move the column header
            columnHeader = @columns[orig_j]
            delete @columns[orig_j]
            columnHeader.textContent = @data.header dest_j
            columnHeader.style.left = col_x
            columnHeader.style.width = col_width
            @columns[dest_j] = columnHeader

            # move the cells.
            for i in [@last_i...@last_i+@nb_rows_visible]
                data = @data.get i, dest_j
                k =  i  + "," + orig_j
                cell = @cells[k]
                delete @cells[k]
                @cells[ i + "," + dest_j] = cell
                cell.style.left = col_x
                cell.style.width = col_width
                cell.textContent = data
        @last_j = j

    move_y: (i)->
        last_i = @last_i
        last_j = @last_j
        shift_i = i - last_i
        if shift_i == 0
            return
        di = Math.min( Math.abs(shift_i), @nb_rows_visible)
        for offset_i in [0 ... di ] by 1
            if shift_i>0
                orig_i = @last_i + offset_i
                dest_i = i + offset_i + @nb_rows_visible - di
            else
                orig_i = @last_i + @nb_rows_visible - di + offset_i
                dest_i = i + offset_i
            row_y = dest_i * @layout.row_height + "px"
            # move the cells.
            for j in [@last_j...@last_j+@nb_cols_visible]
                data = @data.get dest_i, j
                k =  orig_i  + "," + j
                cell = @cells[k]
                delete @cells[k]
                @cells[ dest_i + "," + j] = cell
                cell.style.top = row_y
                cell.textContent = data
        @last_i = i


window.TableData = TableData
window.TableView = TableView

