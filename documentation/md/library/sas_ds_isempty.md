## ds_isempty {#sas_ds_isempty}
This macro check whether a dataset, or a variable in the dataset, is empty. 

	%ds_isempty(dsn, var=, _ans_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : (_option_) a string to be checked whether it exists as a non-empty variable/field in 
	`dsn`; default: `var` is empty, and the macro tests whether there are any observation in the
	dataset or not;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_ans_` : the name of the macro where the result of the test will be stored, _e.g._:
    	+ `-1` in the cases: *(i)*  the dataset does not exist, and *(ii)* `var` exists and is not 
			defined as a variable of the dataset
		+ `0` in the cases: *(i)* `var` is passed as empty and the dataset is not empty, and *(ii)* 
			`var` exists in the input dataset and contains non-missing observations,
		+ `1` otherwise, _i.e._ in the cases: *(i)* `var` is passed as empty and the dataset is empty, 
			and *(ii)* `var` exists in the input dataset but contains only missing observations.

### Examples
Let us consider the test on test dataset #2:
| a |
|---|
| 1 |

then the following test:

	%let ans=;
	%_dstest2;
	%ds_isempty(_dstest2, var=a, _ans_=ans);

returns `ans=0`, while:

	%_dstest1;
	%ds_isempty(_dstest1, var=a, _ans_=ans);

returns `ans=1` since the variable `a` is empty in that latter dataset #1. Even simpler example:

	%_dstest0;
	%ds_isempty(_dstest0, _ans_=ans);

will naturally report: `ans=1`.

Run macro `%%_example_ds_isempty` for more examples.

### Note
Whenever the variable `var` is passed but does not exist in the dataset (_e.g_ the test `%var_check(&dsn, &var, lib=&lib)`
returns 1), the macro returns `ans=-1`.

### Reference
Childress, S. and Welch, B. (2011): ["Three easy ways around nonexistent or empty datasets"](http://analytics.ncsu.edu/sesug/2011/CC19.Childress.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%ds_delete](@ref sas_ds_delete), [%var_check](@ref sas_var_check).
