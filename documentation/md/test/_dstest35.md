## _DSTEST35 {#sas_dstest35}
Test dataset #35.

	%_dstest35;
	%_dstest35(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest35`:
geo | time | EQ_INC20 | RB050a
----|------|----------|-------
 BE | 2009 |    10    |   10 
 BE | 2010 |    50    |   10
 BE | 2011 |    60    |   10
 BE | 2012 |    20    |   20
 BE | 2013 |    10    |   20
 BE | 2014 |    30    |   20
 BE | 2015 |    40    |   20
 IT | 2009 |    10    |   10
 IT | 2010 |    50    |   10
 IT | 2011 |    50    |   10
 IT | 2012 |    30    |   20
 IT | 2013 |    30    |   20
 IT | 2014 |    20    |   20
 IT | 2015 |    50    |   20

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest35`.

### Example
To create dataset #35 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest35;
	%ds_print(_dstest35);

### See also
[%_dstestlib](@ref sas_dstestlib).
