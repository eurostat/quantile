## SAS {#sas_quantile_assign}
[//]: # (Divide a given sample, possibly weighted, into a certain number of slices of equal size, with units ranked according to a variable of interest.)

    %quantile_assign(idsn, var, weight, s, odsn =, name_s =, ilib = WORK, olib = WORK);

### Arguments
* `idsn`: the table which contains the variable of interest and possibly the weights
* `var`: the variable of interest (e.g. income or wealth). It has to be numeric;
* `s`: the number of slices;
* `weight`: (_option_) the variable containing the weights (e.g. in case of survey data). By default, weight is 1;
* `odsn` : (_option_) the name of the table that contains the output data. By default, this is the input table;
* `name_s`: (_option_) the name of the variable providing the slice number;
* `ilib`: (_option_) the library where the input table is stored. By default, the WORK library;
* `olib`: (_option_) the library where the output table has to be stored. By default, the WORK library.

### Returns
`odsn` : name of the final output dataset created, stored in the `olib` library. 

### Example
Given the dataset `_dstest1001`:
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
the following command:
	
	%quantile_assign(_dstest1001, i, 10, weight = strata, name_s = dec) ;
	
will reset the table in `_dstest1001` to:
i	|strata| w | i_s | dec
---:|-----:|--:|----:|----:
  1	|   1  | 1 |  1  |  1
  2	|   1  | 1 |  1  |  1
  3	|   1  | 1 |  1  |  1
  4	|   1  | 1 |  1  |  1
...	|  ... |...| ... | ...
100	|   1  | 1 |  1  |  1
101 |   2  | 1 |  2  |  1
102 |   2  | 1 |  2  |  1
...	|  ... |...| ... | ...
200	|   2  | 1 |  2  |  1
201 |   3  | 1 |  3  |  1
202 |   3  | 1 |  3  |  1
...	|  ... |...| ... | ...
900	|  9   | 1 |  9  |  9 
901	|  10  | 1 | 10  |  9
902	|  10  | 1 | 10  |  9
...	|  ... |...| ... | ...
999	|  10  | 1 | 10  | 10
1000|  10  | 1 | 10  | 10


Run macro `%%_example_quantile_assign` for examples.

### See also
[R version](@ref r_quantile_assign).
