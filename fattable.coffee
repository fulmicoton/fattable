

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
        #@min_col = @compute_min_columns()
        #console.log min_col
        onDomReady = =>
            document.removeEventListener "DOMContentLoaded", arguments.callee
            @setup()
        document.addEventListener "DOMContentLoaded", onDomReady
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

    on_mousedown: (evt)->
        if evt.button == 1
            @moving = true
            @moving_dX = @bodyContainer.scrollLeft + evt.x
            @moving_dY = @bodyContainer.scrollTop + evt.y
    on_mouseup: (evt)->
        @moving = false

    on_mousemove: (evt)->
        if @moving
            x = @bodyContainer.scrollLeft
            y = @bodyContainer.scrollTop
            @bodyContainer.scrollLeft = -evt.x + @moving_dX
            @bodyContainer.scrollTop = -evt.y + @moving_dY

    on_mouseout: (evt)->
        if evt.toElement == null
            @moving = false
    setup: ->
        # can be called when resizing the window
        @pool = []
        @headerPool = []
        @columns = {}
        @cells = {}

        @container.innerHtml = ""
        @w = @container.offsetWidth
        @h = @container.offsetHeight - @layout.header_height

        @last_i = 0
        @last_j = 0
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

        @bodyContainer.addEventListener 'mousedown', @on_mousedown.bind(this)
        @bodyContainer.addEventListener 'mouseup', @on_mouseup.bind(this)
        @bodyContainer.addEventListener 'mousemove', @on_mousemove.bind(this)
        @bodyContainer.addEventListener 'mouseout', @on_mouseout.bind(this)

        @viewport = document.createElement "div"
        @viewport.className = "fattable-viewport"
        @viewport.style.width = @W + "px"
        @viewport.style.height = @H + "px"


        for c in [0...@nb_cols_visible * @nb_rows_visible]
            el = document.createElement "div"
            @viewport.appendChild el
            @pool.push el
        for c in [0...@nb_cols_visible]
            el = document.createElement "div"
            @headerPool.push el
            @headerViewport.appendChild el

        for j in [0...@nb_cols_visible]
            @show_column_header j
            for i in [0...@nb_rows_visible]
                @show_cell i,j

        @cur_i = 0
        @cur_j = 0
        @container.appendChild @bodyContainer
        @container.appendChild @headerContainer
        @bodyContainer.appendChild @viewport

        me = this
        @bodyContainer.onscroll = ->
            x = @scrollLeft
            y = @scrollTop
            [i,j] = me.visible x,y
            me.headerContainer.style.display = "none"
            me.bodyContainer.style.display = "none"
            me.headerViewport.style.left = -x + "px";
            me.move_x j
            me.move_y i
            me.headerContainer.style.display = ""
            me.bodyContainer.style.display = ""

    show_column_header: (j)->
        colEl = @headerPool.pop()
        data = @data.header j
        colEl.textContent = data
        colEl.style.left = @col_offset[j] + "px"
        colEl.style.width = @layout.column_widths[j] + "px"
        @columns[j] = colEl

    hide_column_header: (j)->
        columnHeader = @columns[j]
        @headerPool.push columnHeader
        delete @columns[j]

    show_cell: (i,j)->
        el = @pool.pop()
        data = @data.get i,j
        el.textContent = data
        el.style.left = @col_offset[j] + "px"
        el.style.top = @layout.row_height * i + "px"
        el.style.width = @layout.column_widths[j] + "px"
        @cells[i  + "," + j] = el

    show_patch: (i,j,w,h)->
        for row_id in [ i...i+h ] by 1
            for col_id in [ j ...j+w ] by 1
                @show_cell row_id, col_id

    hide_cell: (i,j)->
        k =  i  + "," + j
        cell = @cells[k]
        @pool.push cell
        delete cell[k]

    hide_patch: (i,j,w,h)->
        for row_id in [ i...i+h ] by 1
            for col_id in [ j ...j+w ] by 1
                @hide_cell row_id, col_id

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

    repaint: (i,j)->
        last_i = @last_i
        last_j = @last_j
        if distance(i, last_i) >= @nb_rows_visible or distance(j, last_j) >= @nb_cols_visible
            @hide_patch last_i, last_j, @nb_cols_visible, @nb_rows_visible
            @show_patch i, j, @nb_cols_visible, @nb_rows_visible
            for cj in [ 0 ... @nb_cols_visible ] by 1
                @hide_column_header last_j + cj
                @show_column_header j + cj
        else
            if i > last_i
                nb_rows = i - last_i
                @hide_patch last_i, last_j, @nb_cols_visible, nb_rows
                @show_patch (last_i + @nb_rows_visible), j,  @nb_cols_visible, nb_rows
                mh = last_i + @nb_rows_visible - i
                mi = i
            else
                nb_rows = last_i-i
                @hide_patch (i + @nb_rows_visible), last_j, @nb_cols_visible, nb_rows
                @show_patch i, j, @nb_cols_visible, nb_rows
                mh = i + @nb_rows_visible - last_i
                mi = last_i
            if j > last_j
                @hide_patch mi, last_j, (j - last_j ), mh
                @show_patch mi, (last_j + @nb_cols_visible), (j - last_j), mh
                for cj in [ last_j ... j ] by 1
                    @hide_column_header cj
                    @show_column_header cj + @nb_cols_visible
            else
                @hide_patch mi, (j + @nb_cols_visible), (last_j - j), mh
                @show_patch mi, j, (last_j - j), mh
                for cj in [ j ... last_j ] by 1
                    @hide_column_header cj + @nb_cols_visible
                    @show_column_header cj
        @last_i = i
        @last_j = j


window.TableData = TableData
window.TableView = TableView

