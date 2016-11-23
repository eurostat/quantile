## _DSTEST36 {#sas_dstest36}
Test dataset #36.

	%_dstest36;
	%_dstest36(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest36`:
 geo | time | value
-----|------|------
EU27 | 2006 |  1
EU25 | 2004 |  2
EA13 | 2001 |  3
EU27 | 2007 |  4
EU15 | 2004 |  5
EA12 | 2007 |  6
EA12 | 2002 |  7
GR	 | 2005 |  8
EL	 | 2003 |  9
GR02 | 2003 |  10
EU15 | 2015 |  11
NMS12| 2015 |  12

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest36`.

### Example
To create dataset #36 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest36;
	%ds_print(_dstest36);

### See also
[%_dstestlib](@ref sas_dstestlib).
