## _DSTEST25 {#sas_dstest25}
Test dataset #25.

### Contents
The following table is stored in `_dstest25`:
geo | value | time | unrel | unit 
----|-------|------|-------|------
 BE |   1   | 2014 |   1   |  EUR   
 BE |   2   | 2013 |   2   |  EUR
 BE |   3   | 2012 |   0   |  EUR
 AT |   1   | 2013 |   1   |  EUR
 AT |   2   | 2012 |   0   |  EUR
 AT |   3   | 2011 |   2   |  EUR
 AT |   4   | 2010 |   0   |  EUR
 BG |   1   | 2013 |   0   |  EUR
 BG |   2   | 2012 |   2   |  EUR
 LU |   1   | 2014 |   0   |  EUR
 LU |   2   | 2013 |   0   |  EUR
 LU |   3   | 2012 |   1   |  EUR
 FR |   1   | 2014 |   2   |  EUR
 FR |   2   | 2013 |   0   |  EUR
 FR |   3   | 2012 |   1   |  EUR
 IT |   1   | 2013 |   2   |  EUR
 IT |   2   | 2012 |   1   |  EUR

### Usage 

	%_dstest25(lib=, _ds_=, verb=no, force=no);

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest25`. 

### Example
To create dataset #25 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest25;
	%ds_print(_dstest25);

### See also
[%_dstestlib](@ref sas_dstestlib).
