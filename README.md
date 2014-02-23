# Fattable

## Demo

Checkout the [demo](http://fulmicoton.com/fattable/index2.html) here.

## What is it?

Fattable is a javascript Library to create table with infinite scroll, with infinite number of rows and number of columns.

Big table (more 10,000 cells) don't do well with DOM.
Your scroll will start getting choppy.

Also big tables can rapidly grow in sizes. It is not always possible to have clients download or even retain all of the table data. Fattable includes everything required to load your data asynchronously.

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
      "model": model,          // model describing your data (see below)
      "nbRows": 1000000,     // overall number of rows
      "rowHeight": 35,       // constant row height (px)
      "headerHeight": 100,   // height of the header (px)
      "columnWidths": [300, 300, 300, 300] // array of column width (px) 
    })  

## Painter

``painter`` is an object which role is to fill the content of your cells, and columnHeaders. It is expected to implement the following interface.
    
    var painter = {
        
        "setupHeader": function(headerDiv) {
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
        "fillHeader": function(headerDiv, data) {
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
        "fillHeaderPending": function(headerDiv) {
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

[Demo](http://fulmicoton.com/fattable/index2.html)

If your data is not too big, you probably can just fetch your data all at once, and then display the table.
For this simple use case, the best is probably to extend the ``SyncTableData``
object.

You just need to extend ``fattable.SyncTableModel`` and implement the following methods

  {
    "getCellSync": function(i,j) {
      return "cell " + i + "," + j;
    },
    "getHeaderSync": function(i,j) {
      return "col " + j;
    }
  }


### Asynchronous and paged async model

[Demo](http://fulmicoton.com/fattable/index.html)

You probably don't want your backend to receive one request per
cell displayed. A good solution to this problem is to partition your table into pages of cells. 

Queries are only sent when the user stops scrolling.

To use such a system, you just have to extend the ``PagedAsyncTableModel``class with the following methods. In addition, it include a simple LRU cache.

  {
    "cellPageName": function(i,j) {
        // returns a string which stands for the id of 
        // the page the cell (i,j) belongs to.
        var I = (i / 128) | 0;
        var J = (j / 29) | 0;
        return JSON.stringify([I,J]);
    },
    "fetchCellPage": function() {
        // Async method to return the page of 
        var coords = JSON.parse(pageName);
        var I = coords[0];
        var J = coords[1];
        getJSON("data/page-" + I + "-" + J + ".json", function(data) {
            cb(function(i,j) {
                return {
                    rowId: i,
                    content: data[i-I*128][j-J*29]
                };
            });
        });
    },
    "headerCellPage" : function(j) {
     // Same as for cellPageName but for cells.
    },
    "fetchHeaderPage" : function(j) {
      // Same as for fetchCellPage but for headers
    }
  }



### Custom async model

If you want to go custom, you can implement your own data model, it just has to implement the following methods :
  
  {
    hasCell: function(i,j) {
      // returns true if getting the data of the cell (i,j )
      // does not require an async call false if it does need it.
    },
    hasHeader: function(j) {
      // ... same thing for column header j
    },
    getCell: function(i,j, cb) {
        // fetch data associated to cell i,j 
        // and call the callback method cb with it
        // as argument
    },
    getHeader: function(j,cb {
        // ... same thing for column header j
    }
}


