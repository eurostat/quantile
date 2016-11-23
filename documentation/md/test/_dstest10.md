## _DSTEST10 {#sas_dstest10}
Test dataset #10.

	%_dstest10;
	%_dstest10(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest10`:
geo | EA18 | EA19 | EEA18| EEA28| EU27 | EU28 | EFTA
----|------|------|------|------|------|------|------
AT	| 1999 | 1999 | 1994 | 1994 | 1995 | 1995 | 1960
AT	| 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 1995
BE	| 1999 | 1999 | 1994 | 1994 | 1957 | 1957 |  .
BE	| 2500 | 2500 | 2500 | 2500 | 2500 | 2500 |  .
BG	|  .   |  .	  |  .   |  .   | 2007 | 2007 |  .
BG	|  .   |  .	  |  .   |  .   | 2500 | 2500 |  .
CH	|  .   |  .	  |  .   |  .   |  .   |  .   | 1960
CH	|  .   |  .	  |  .   |  .   |  .   |  .   | 2500
CY	| 2008 | 2008 |  .   | 2005 | 2004 | 2004 |  .
CY	| 2500 | 2500 |  .   | 2500 | 2500 | 2500 |  .
CZ	|  .   |  .   |  .   | 2005 | 2004 | 2004 |  .
CZ	|  .   |  .	  |  .   | 2500 | 2500 | 2500 |  .
DE	| 1999 | 1999 | 1994 | 1994 | 1957 | 1957 |  .
DE	| 2500 | 2500 | 2500 | 2500 | 2500 | 2500 |  .

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest10`.

### Example
To create dataset #10 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest10;
	%ds_print(_dstest10);

### See also
[%_dstestlib](@ref sas_dstestlib).
