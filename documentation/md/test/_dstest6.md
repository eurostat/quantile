## _DSTEST6 {#sas_dstest6}
Test dataset #6.

	%_dstest6;
	%_dstest6(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest6`:
 a | b | c | d | e | f | g | h |
---|---|---|---|---|---|---|--- 
 . | 1 | 2 | 3 | . | 5 | 6 | .

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest6` storing 
	the following table: 

### Example
To create dataset #6 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest6;
	%ds_print(_dstest6);

### See also
[%_dstestlib](@ref sas_dstestlib).
