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

CELL_PAGE_SIZE = 256 - 1
COL_PAGE_SIZE = 1024 - 1

makePage = (@pageName, @I, @J)->
    (i,j)->
        @pageName + ":" + (i - @I) + "," + (j - @J)
    

class AsyncTableData extends window.TableData

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
