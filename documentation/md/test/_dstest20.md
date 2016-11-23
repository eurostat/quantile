## _DSTEST20 {#sas_dstest20}
Test dataset #20.

	%_dstest20;
	%_dstest20(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest20`:
 breakdown | variable | start | end | fmt1_dummy | fmt2_dummy | fmt3_dummy | fmt4_dummy
-----------|----------|-------|-----|------------|------------|------------|------------
  label1   |   DUMMY  |   1   |  5	|      1	 |      0	  |      1	   |      0
  label2   |   DUMMY  |   1   |  3	|      1	 |      1	  |      0	   |      0  
  label2   |   DUMMY  |   5   |  5	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   8   |  10	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   12  |  12	|      1	 |      1 	  |      0	   |      0
  label3   |   DUMMY  |   1   |  10	|      0	 |      1 	  |      1	   |      0
  label3   |   DUMMY  |   20  |HIGH |      0	 |      1	  |      1	   |      0
  label4   |   DUMMY  |   10  |  20	|      0	 |      0	  |      0	   |      1
  label5   |   DUMMY  |   10  |  12	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   15  |  17	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   19  |  20	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   30  |HIGH	|      0	 |      1	  |      1	   |      0

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table).

### Example
To create dataset #20 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest20;
	%ds_print(_dstest20);

### See also
[%_dstestlib](@ref sas_dstestlib).
