## var_numcast {#sas_var_numcast}
Cast a given character variable into a numeric variable where numbers are attributed in sequence
depending on the frequency of the corresponding category in the character variable.

	%var_numcast(idsn, var, odsn=, suff=_new, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : input reference dataset, whose variable shall be cast;
* `var` : name of the character variable that should be cast, _i.e._ all categories
	in `var` will be converted into numbers;
* `suff` : (_option_) suffix to be added to the name of the cast variable; default: 
	`suff=_new`, _i.e._ the variable `a` in `idsn` will be renamed as `a_new`;
* `odsn` : (_option_) name of the output dataset; default: `odsn=idsn` so that the input
	dataset is in practice updated;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Returns
`odsn` : output dataset (stored in the `olib` library), containing the exact same data than `idsn`,
	plus an additional new variable (obtained as a concatenation of the original `var` name and 
	`suff`) where all the categories of the variable defined by `var` are cast into a numeric 
	variable.

### Examples
Let us consider test dataset #31 in WORKing directory:
geo | value | unit
:--:|------:|:---:
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

then the call to the macros:

	%_dstest31;
	%var_numcast(_dstest31, unit);
	
will return the updated dataset below:
geo | value | unit |unit_new
:--:|------:|:----:|-------:
 BE |  0    | EUR  |   1
 AT |  0.1  | EUR  |   1
 BG |  0.2  | NAC  |   2
 LU |  0.3  | EUR  |   1
 FR |  0.4  | NAC  |   2
 IT |  0.5  | EUR  |   1

Run macro `%%_example_var_numcast` for more examples.

### Note 
The values in the new variable are attributed in sequential order, from the most to the least frequent 
categories in `var`. 

### Reference
Wright, W.L. (2007): ["Creating a format from raw data or a SAS dataset"](http://www2.sas.com/proceedings/forum2007/068-2007.pdf).

### See also
[%var_info](@ref sas_var_info), [%var_rename](@ref sas_var_rename), [%digits](@ref sas_digits).
