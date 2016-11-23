## var_check {#sas_var_check}
* Check that a field/variable (defined as a string) actually exists in a given dataset. 

       %let ans=%var_check(dsn, var, lib=WORK);
* Trim a list of string elements to keep only those that actually define variables in a given dataset.

       %var_check(dsn, var, _varlst_=, lib=WORK);

### Arguments
* `dsn` : an input reference dataset;
* `var` : either a (list of) variable name(s), or the (list of) position(s) of variable(s) whose
	existence in input dataset `dsn` is tested; when `var` is passed as a list of integers, it is 
	only verified that these values are in the range `[1,#{variables in dsn}]` where `#{variables in dsn}`
	is the number of dimensions in `dsn`; the list of variables of corresponding variables is then
	returned through `_varlst_` (see below);
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `ans` : (_option_) the error code of the test, _i.e._:
		+ `0` when the variable `var` exists in the dataset,
		+ `1` (error: "var does not exist") otherwise;
	
	should not be used contemporaneously with the option `_varlst_` below; this is further unusable
	when `var` is passed as a list of integers;
* `_varlst_` : (_option_) name of the macro variable used to store the string elements from `var` 
	that do actually	define existing variables/fields in `dsn`; incompatible with returned result 
	`ans` above. 

### Examples
Let us consider the table `_dstest5`:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
then:

	%let var=a b y z c;
	%let list=;
	%let ans=%var_check(_dstest5, &var);

returns `ans=0 0 1 1 0`, the outputs of the existence test of string elements of `var` in 
`_dstest5`, while:

	%var_check(_dstest5, &var, _varlst_=list);

returns `list=a b c`, the only string elements of `var` which define variables in `_dstest5`. Finally,
it is possible to pass integer `var` to the macro so as to retrieve the names of the variables in
corresponding positions, _e.g._:

	%let var=3 1 4 2;
	%let list=;
	%var_check(_dstest35, &var, _varlst_=list);

returns `list=EQ_INC20 geo RB050a time`.

Run macro `%%_example_var_check` for more examples.

### Notes
1. As mentioned above, two types of outputs are possible: either the answer `ans` to the test when
a result shall be returned (and `_varlst_` is not passed), or an updated list of acceptable variables
(when `_varlst_` is passed). The former case is useful when testing a single variable existence in a 
dataset, the latter for triming a list of actual variables. Contemporaneous use is impossible.
2. In short, the macro performs either of the two following operations:
	+ the "intersection" between the list `var` with the list of variables in `dsn`, _i.e._ when 
	`_varlst_` is set:

        %let allvars=;
        %ds_contents(&dsn, _varlst_=allvars, lib=&lib);
        %let &_varlst_=%list_intersection(&var,  &allvars, casense=NO);
	+ the test of existence of the variables `var` otherwise, _i.e._ when a single variable `var` is 
	passed:

	    %let err=%sysfunc(varnum(%sysfunc(open(&lib..&dsn)),&var));
	    %if &err>0 %then 	%let ans=0;
	    %else 			 	%let ans=1;
3. The order of the variables in the output list `&_varlst_` /answer `ans` matches that in the input 
list `var`.
4. When none of the string elements in `var` matches a variable in `dsn`, an empty list `&_varlst_`/
answer `ans` is set. 

### References
1. SAS community: ["Tips: Check if a variable exists in a dataset"](http://www.sascommunity.org/wiki/Tips:Check_if_a_variable_exists_in_a_dataset).
2. Johnson, J. (2010): ["OBJECT EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%lib_check](@ref sas_lib_check), [%ds_contents](@ref sas_ds_contents), 
[%dir_check](@ref sas_dir_check), [%file_check](@ref sas_file_check),
[VARNUM](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000148439.htm).
