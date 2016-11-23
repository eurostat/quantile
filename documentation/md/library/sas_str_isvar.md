## str_isvar {#sas_str_isvar}
Define if a (list of) string(s) actually define variables in a given dataset.

	%str_isvar(dsn, var, _ans_=, _var_=, lib=WORK, sep=%str( ));

### Arguments
* `dsn` : a reference dataset;
* `var` : list of string elements to be from the dataset when they exist;
* `lib` : (_option_) name of the input library; by default: `WORK` is used;
* `sep` : (_option_) character/string separator in input `var` list; default: `%%str( )`, _i.e._ 
	`sep` is blank.

### Returns
* `_ans_` : (_option_) name of the macro variable storing the list of same length as `var` where the
	i-th item provides the answer of the test above for the i-th item in `var`, _i.e._:
		+ `1` if it is the name of a variable in `var`,
		+ `0` if not;
	either this option or the next one (`_var_`) must be set so as to run the macro;
* `_var_` : (_option_) name of the macro variable storing the updated list from which all elements 
	that do not macth existing variables/fields in `dsn` have been removed. 

### Example
Let us consider the table `_dstest5`:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
then:

	%let var=a b y z c;
	%let ans=;
	%let list=;
	%str_isvar(_dstest5, &var, _ans_=ans, _var_=list);

returns `ans=1 1 0 0 1` and `list=a b c`, the only string elements of `var` which define variables 
in `_dstest5`.

Run macro `%%_example_str_isvar` for more examples.

### Note
1. In short, this macro "intersects" the list `var` with the list of variables in `dsn`, _i.e._ 
running:

    %let allvars=;
    %ds_contents(&dsn, _varlst_=allvars, lib=&lib);
    %let &_var_=%list_intersection(&var,  &allvars);
2. The order of the variables in the output list matches that in the input list `var`.
3. When none of the string elements in `var` matches a variable in `dsn`, an empty list is set. 

### See also
[%str_dsvar](@ref sas_str_dsvar), [%str_isds](@ref sas_str_isds), [%str_isgeo](@ref sas_str_isgeo), 
[%var_check](@ref sas_var_check), [%ds_contents](@ref sas_ds_contents), [%ds_check](@ref sas_ds_check).
