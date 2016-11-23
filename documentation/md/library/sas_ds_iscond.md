## ds_iscond {#sas_ds_iscond}
Check whether a given condition holds for part of or all the observations (rows) of a given dataset.

	%ds_iscond(dsn, cond, _ans_=, lib=WORK);

### Arguments
* `dsn` : a dataset, for which the condition has to be verified;
* `cond` : the expression of a condition on one or several variables of `dsn` written as a SAS
	base code; 
* `lib` : (_option_) the library in which the dataset `idsn` is stored.

### Returns
`_ans_` : name of the macro variable used to store the (quantitative) output of the test, _i.e._:
		+ 1 if the condition is verified for all observations in the input dataset,
		+ 0 if the condition is never verified,
		+ a value in [-1,0[ define as the opposite of the ratio of observations for which the 
		condition holds otherwise. 

### Examples
Let's perform some test on the values of test datatest #1000 (with 1000 observations sequentially
enumerated), _e.g._:
	
	%_dstest1000;
	%let ans=;
	%let cond=%quote(i le 0);
	%ds_iscond(_dstest1000, &cond, _ans_=ans);

returns `ans=0`, while:

	%let cond=%quote(i gt 0);
	%ds_iscond(_dstest1000, &cond, _ans_=ans);

returns `ans=1`, and:

	%let cond=%quote(i lt 400);
	%ds_iscond(_dstest1000, &cond, _ans_=ans);

returns `ans=-0.4`.

Run `%%_example_ds_iscond` for more examples.

### Notes
1. For very large tables, the accuracy of the test is relative to the precision of your machine. 
In practice, for tables with more than 1E9 observations but only one for which the condition `cond` 
holds, the ratio calculated may be equal to 1 (instead of a value<1). In that latter case, the macro
will return a negative value (`ans=-1`) to avoid confusion with the case (`ans=1`) where all the
condition actually holds for observations. (see `%%_example_ds_iscond`).
2. In practice, simply launching:

 	    %let ans=;
	    %ds_iscond(dsn, cond, _ans_=ans, lib=WORK);
provides with a result equivalent to running:
	
	 %ds_count(dsn, _nobs_=c0, lib=lib);
	 %ds_select(dsn, _tmp, where=cond, ilib=lib);
	 %ds_count(_tmp, _nobs_=c1, lib=lib);
and comparing the values of `c0` and `c1`:

	 %if &c1=&c0 %then 			%let ans=1;
	 %else %if &c1 < &c0 %then 	%let ans=%sysevalf(-&c1/&c0);
	 %else						%let ans=0;
This macro however does not generate any intermediary dataset.
3. Note in general the use of `%%quote` so as to express a condition. 

### Reference
Gupta, S. (2006): ["WHERE vs. IF statements: Knowing the difference in how and when to apply"](http://www2.sas.com/proceedings/sugi31/238-31.pdf).

### See also
[%ds_count](@ref sas_ds_count), [%ds_check](@ref sas_ds_check), [%ds_delete](@ref sas_ds_delete), [%ds_select](@ref sas_ds_select).
