# Fattable


## What is it?

Fattable is a javascript Library to create table with infinite scroll, with infinite number of rows and number of columns.

Big table (more 10,000 cells) don't do well with DOM.
Your scroll will start getting choppy.

This library is

 - **light** : no library needed, smaller than 10KB)
 - **fast** (only visible element are in DOM, the exact same DOM element are recycled over and over, )
 - **async friendly** : the API makes it simple to fetch your data aysnchronously.
 - **powerful and unbloated** : Design is up to you. Style the table via
 css and use your painter to hook up events, and render your content in your cell.

## Limitations

Cells must have a constant height, you need to give an array with your column widths. Also because it is light


## API

    var table = fattable({
      "painter": painter,    // your painter (see below)
      "data": data,          // your data layer (see below)
      "nbRows": 1000000,     // overall number of rows
      "rowHeight": 35,       // constant row height (px)
      "headerHeight": 100,   // height of the header (px)
      "columnWidths": [300, 300, 300, 300] // array of column width (px) 
    })  

## Painter

``painter`` is an object which role is to fill the content of your cells, and columnHeaders. It is expected to implement the following interface.
    
    var painter = {
        
        "setupColumnHeader": function(colHeaderDiv) {
            /* Setup method are called at the creation
               of the column header. That is during
               initialization and for all window resize
               event. Columns are recycled. */
        }
    ,
        "setupCell": function(cellDiv) {
            /* The cell painter tells how 
               to fill, and style cells.
               Do not set height or width.
               in either fill and setup methods. */
        }
    ,
        "fillColumnHeader": function(colHeaderDiv, data) {
            /* Fills and style a column div.
               Data is whatever the datalayer
               is returning. A String, or a more
               elaborate object. */
            colHeaderDiv.textContent = data;
        }
    ,
        "fillCell": function(cellDiv, data) {
            /* Fills and style a cell div.
               Data is whatever the datalayer
               is returning. A String, or a more
               elaborate object. */
            cellDiv.textContent = data;
        }
    ,
        "fillColumnHeaderPending": function(cellDiv) {
            /* Mark a column header as pending.
               When using an asynchronous.
               Its content is not in cache
               and needs to be fetched */
            cellDiv.textContent = "NA";
        }
    ,
        "fillCellPending": function(cellDiv) {
            /* Mark a cell content as pending
               Its content is not in cache and 
               needs to be fetched */
            cellDiv.textContent = "NA";
        }
    };
    

Actually this very simple implementation is the default.
And it is available as ``fattable.Painter``, so that you can just
override it.


## DataLayer

### Synchronous Data Layer

If your data is not too big, you probably can leave with fetching all your data all at once, and then display the table.
For this simple use case, the best is probably to extend the ``SyncTableData``
object.

You just need to 