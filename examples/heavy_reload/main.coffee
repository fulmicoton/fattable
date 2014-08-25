
# Only two columns...
# Stores records with a timestamp and a string
# mimicking a log.
#
# The last line appears on top.
# Everything is kept in memory.
#
class LogData extends fattable.SyncTableModel
    
    constructor: ->
        @lines = []

    getCellSync: (i, j, cb)->
        @lines[@nb_records - 1 - i][j]

    getHeaderSync: (j)->
        ["date", "log line"][j]

    hasCell: (i, j)->
        i<@lines.length and j<2

    appendLine: (record)->
        @nb_records = @lines.length + 1
        @lines.push record


painter = new fattable.Painter
log_data = new LogData()
line_id = 0

# Returns a function that is similar to f, but 
# reduce the number of calls to make sure that there is
# never 2 calls in less than delay (ms)
limiter = (f, delay)->
    done = false
    to_do = false
    execute = ->
        done = true
        f()
        window.setTimeout ellapsed, delay
    ellapsed = ->
        if to_do
            to_do = false
            execute()
        else
            done = false
    ->  
        if not done
            execute()
        else
            to_do = true

# This dummy appender will 
# append 500 lines chunks
# every 20ms
dummy_appender = (cb)->
    aux = ->
        for i in [0...500]
            log_data.appendLine [new Date(), "Line " + line_id]
            line_id += 1
        delay = 20
        cb()
        if line_id < 100000
            window.setTimeout aux, delay
    aux()


new_table = ->
    table = fattable
      "container": "#container"
      "model": log_data
      "nbRows": log_data.nb_records
      "rowHeight": 35
      "headerHeight": 35
      "painter": painter
      "columnWidths": [ 300, 500 ]
    table.setup()

$ ->
    # We debounce event to refresh the table at most every 100 ms.
    cb = limiter new_table, 100
    dummy_appender cb
    window.onresize = ->
        table.setup()


