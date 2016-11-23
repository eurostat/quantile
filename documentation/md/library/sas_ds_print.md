## ds_print {#sas_ds_print}
Simple print instruction for the (partial, total or "structural") display of a given dataset
using the `PROC PRINT` statement.

	%ds_print(dsn, lib=WORK, title=, head=, options=);

### Arguments
* `dsn` : a dataset reference;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `head` : (_option_) option set to the number of header observations (_i.e._, starting from 
	the first one) to display (useful for large datasets); default: `head` is not set and the 
	whole dataset is printed;
* `title` : (_option_) title of the printed table; default: `title=&dsn`, _i.e._ the name
	of the table is used;
* `options` : (_option_) list of options as normally accepted by `PROC PRINT`; use the `%quote` 
	macro to pass this parameter.
  
### Example
Print a test dataset in the `WORK` directory so that a blank line is inserted after every 2 
observations:

	%_dstest32;
	%ds_print(_dstest32, options=%quote(BLANKLINE=2));

Run macro `%%_example_ds_print` for more examples.

### Note
In the case the dataset exists but is empty (no observation), its structure will still be printed, 
i.e., the list of variables, their types and lengths will be displayed.
