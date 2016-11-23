## _DSTEST34 {#sas_dstest34}
Test dataset #34.

	%_dstest34;
	%_dstest34(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest34`:
geo | year | value
----|------|------
EU27|  2006|	1
EU25|  2004|	2
EA13|  2001|	3
EU27|  2007|	4
EU15|  2004|	5
EA12|  2007|	6
EA12|  2002|	7
EU15|  2015|	8
NMS12| 2015|	9

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest34`.

### Example
To create dataset #34 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest34;
	%ds_print(_dstest34);

### See also
[%_dstestlib](@ref sas_dstestlib).
