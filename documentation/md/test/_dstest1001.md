## _DSTEST1001 {#sas_dstest1001}
Test dataset #1001.

	%_dstest1001;
	%_dstest1001(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest1001`:
i	|strata|
----|------|
1	|  1   |
2	|  1   |
3	|  1   |
4	|  1   |
...	| ...  |
100	|  1   |
101 |  2   |
102 |  2   |
...	| ...  |
200	|  2   |
201 |  3   |
202 |  3   |
...	| ...  |
900	|  9   |
901	|  10  |
902	|  10  |
...	| ...  |
999	|  10  |
1000|  10  |

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest1000`.

### Example
To create dataset #1001 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest1001;
	%ds_print(_dstest1001);

### See also
[%_dstestlib](@ref sas_dstestlib).
