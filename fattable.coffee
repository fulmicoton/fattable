

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

scroll_options =
    mouseWheel: true
    scrollbars: true 
    scrollX: true
    probeType: 3
    interactiveScrollbars: true
    deceleration: 0.01
    keyBindings:
        pageUp: 33
        pageDown: 34
        end: 35
        home: 36
        left: 37
        up: 38
        right: 39
        down: 40

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
    d = 99999
    res = undefined
    for x_ in vals
        d_ = distance x,x_
        if d_ < d
            d = d_
            res = x_
    res

class TableView

    constructor: (container, @data, @layout)->
        if typeof container == "string"
            @container = document.querySelector container
        else
            @container = container
        @container.class_name += " fattable"
        @nb_cols = @data.nb_cols()
        @nb_rows = @data.nb_rows()
        @W = sum @layout.column_widths
        @row_height  = @layout.row_height
        @H = @layout.row_height * @nb_rows
        @col_offset = cumsum @layout.column_widths
        @min_col = Math.min.apply null, @layout.column_widths
        onDomReady = =>
            document.removeEventListener "DOMContentLoaded", arguments.callee, false
            @setup()
        document.addEventListener "DOMContentLoaded", onDomReady, false
        window.addEventListener "resize", =>
            @setup()

    visible: (x,y)->
        # returns the square
        #   [ i_a -> i_b ]  x  [ j_a, j_b ]
        j = binary_search @col_offset, x
        i = (y / @layout.row_height | 0)
        [i, j]

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
        @nb_cols_visible = (@w / @min_col | 0) + 3
        @nb_rows_visible = (@h / @layout.row_height | 0) + 2

        # header container
        @headerContainer = document.createElement "div"
        @headerContainer.className += " fattable-header-container";
        @headerContainer.style.height = @layout.header_height + "px";
        @headerContainer.className = "header-container"
        
        @headerViewport = document.createElement "div"
        @headerViewport.className = " fattable-viewport"
        @headerViewport.style.width = @W + "px"
        @headerViewport.style.height = @layout.header_height + "px"
        @headerContainer.appendChild @headerViewport

        # body container 
        @bodyContainer = document.createElement "div"
        @bodyContainer.className = "fattable-body-container";
        @bodyContainer.style.top = @layout.header_height + "px";
        
        @viewport = document.createElement "div"
        @viewport.className = "fattable-viewport"
        @viewport.style.width = @W + "px"
        @viewport.style.height = @H + "px"

        for c in [0...@nb_cols_visible * @nb_rows_visible]
            @pool.push document.createElement "div"
        for c in [0...@nb_cols_visible]
            @headerPool.push document.createElement "div"
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
            me.repaint i,j
            me.headerContainer.style.display = ""
            me.bodyContainer.style.display = ""

    show_column_header: (j)->
        colEl = @headerPool.pop()
        data = @data.header j
        colEl.innerText = data
        colEl.style.left = @col_offset[j] + "px"
        colEl.style.top = "0"
        colEl.style.width = @layout.column_widths[j] - 1 + "px"
        colEl.style.height = @layout.header_height + "px"
        @headerViewport.appendChild colEl
        @columns[j] = colEl

    hide_column_header: (j)->
        columnHeader = @columns[j]
        @headerViewport.removeChild columnHeader
        @headerPool.push columnHeader
        delete @columns[j]

    show_cell: (i,j)->
        el = @pool.pop()
        data = @data.get i,j
        el.innerText = data
        el.style.left = @col_offset[j] + "px"
        el.style.top = @layout.row_height * i + "px"
        el.style.width = @layout.column_widths[j] - 1 + "px"
        el.style.height = @layout.row_height - 1 + "px"
        @viewport.appendChild el
        @cells[","+ (i + j * @nb_rows) ] = el

    show_patch: (i,j,w,h)->
        for row_id in [ i...i+h ] by 1
            for col_id in [ j ...j+w ] by 1
                @show_cell row_id, col_id

    hide_cell: (i,j)->
        k =  ","  + (i + j * @nb_rows)
        cell = @cells[k]
        @viewport.removeChild cell
        @pool.push cell
        delete cell[k]

    hide_patch: (i,j,w,h)->
        for row_id in [ i...i+h ] by 1
            for col_id in [ j ...j+w ] by 1
                @hide_cell row_id, col_id

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

