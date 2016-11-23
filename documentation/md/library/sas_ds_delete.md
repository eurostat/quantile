## ds_delete {#sas_ds_delete}
Conditionally delete observations and drop variable(s) from a given dataset.

	%ds_delete(dsn, var=, cond=, firstobs=0, obs=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : (_option_) List of variable(s) to delete (`drop`) from the dataset; if more variables
	are to be deleted, `var` should be defined as an unformatted list; default: not used;
* `cond` : (_option_) an expression that resolves to a boolean (0/1) so that all observations
	for which `cond` is true (1) will be deleted; default: `0`, _i.e._ no observations is deleted;
* `firstobs, obs` : (_option_) indexes of the first and the last observations to consider for the
	delete operation _resp._;  all obsevation whose index is `<firstobs` or `>obs` will be automatically
	deleted; see `DATA` step options; by default, options are not used;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Examples
Let us consider the following `_dstest31` table: 
geo | value | unit
----|------:|-----
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

we will delete all VALUEs and keep only observations for which UNIT is EUR: 

	%ds_delete(_dstest31, var=value, cond=%quote(unit="EUR"));

so that we have:
geo | unit
----|-----
 BG | NAC
 FR | NAC

Note that the command can be used to delete more than one variable at a time, _e.g._:

	%ds_delete(_dstest31, var=value unit, cond=%quote(unit="EUR"));

will return instead:
|geo | 
|----|
| BG |
| FR |

Run macro `%%_example_ds_delete` for more examples.

### Notes
1. In short, the macro sequentially runs two operations that summarizes to the following `DATA` step:

       DATA &lib..&dsn (DROP=&var);
		   SET &lib..&dsn(FIRSTOBS=&firstobs OBS=&obs);
   		   IF &cond THEN DELETE;
	   run;
2. It shall be noticed that in practice: first the options `firstobs` and `obs` are applied, then the 
condition `cond` is evaluated (though it occurs inside a unique `DATA` step), and then the variable `var` 
is dropped from the dataset. This matters in the cases where `cond` is an expression based on `var` values.

### Reference
1. ["Selecting and restricting observations"](http://www.albany.edu/~msz03/epi514/notes/fp051_065.pdf).
2. Gupta, S. (2006): ["WHERE vs. IF statements: Knowing the difference in how and when to apply"](http://www2.sas.com/proceedings/sugi31/238-31.pdf).

### See also
[%ds_check](@ref sas_ds_check), [%ds_isempty](@ref sas_ds_isempty), [%ds_iscond](@ref sas_ds_iscond), [%var_check](@ref sas_var_check),
[DELETE](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000247666.htm),
[DROP](http://support.sas.com/documentation/cdl/en/lestmtsref/63323/HTML/default/viewer.htm#n1capr0s7tilbvn1lypdshkgpaip.htm).
