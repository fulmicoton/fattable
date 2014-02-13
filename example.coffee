CELL_PAGE_SIZE = 256 - 1
COL_PAGE_SIZE = 1024 - 1

makePage = (@pageName, @I, @J)->
    (i,j)->
        @pageName + ":" + (i - @I) + "," + (j - @J)

class AsyncTableData extends fattable.TableData

    constructor: ->
        @pageCache = new LRUCache()
        @fetchCallbacks = {}

    cellPageKey: (i,j)->
        [ i - (i & CELL_PAGE_SIZE), j - (j & CELL_PAGE_SIZE) ]

    hasCell: (i,j)->
        pageName = @cellPageKey(i,j).join(",")
        @pageCache.has pageName

    getCell: (i,j, cb=(->))->
        [I,J] =  @cellPageKey i,j
        pageName = [I,J].join ","
        if @pageCache.has pageName
            cb @pageCache.get(pageName)(i,j)
        else if @fetchCallbacks[pageName]?
            @fetchCallbacks[pageName].push [i, j, cb ]
        else
            @fetchCallbacks[pageName] = [ [i, j, cb ] ]
            @fetchCellPage pageName, I, J

    fetchCellPage: (pageName, I, J)->
        deferred = =>
            page = makePage pageName, I, J
            @pageCache.set pageName, page
            for [i,j,cb] in @fetchCallbacks[pageName]
                cb page(i,j)
            delete @fetchCallbacks[pageName]
        window.setTimeout deferred, 500

    hasColumn: (j)->
        true
    
    getHeader: (j,cb=(->))->
        cb("col " + j)

window.AsyncTableData = AsyncTableData
