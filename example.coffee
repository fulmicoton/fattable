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

CELL_PAGE_SIZE = 100
COL_PAGE_SIZE = 1000



makePage = (@pageName, @I, @J)->
    (i,j)->
        @pageName + ":" + (i - @I) + "," + (j - @J)
    

class AsyncTableData extends window.TableData

    constructor: ->
        @pageCache = new LRUCache()
        @fetchCallbacks = {}

    cellPageName: (i,j)->
        "cell" + ((i / CELL_PAGE_SIZE) | 0) + "," + ((j / CELL_PAGE_SIZE) | 0)

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
            @fetchCellPage pageName, (i / CELL_PAGE_SIZE | 0)*CELL_PAGE_SIZE, (j / CELL_PAGE_SIZE | 0 )*CELL_PAGE_SIZE

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
