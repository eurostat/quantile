## ds_sort {#sas_ds_sort}
Sort the observations in a given dataset.

	%ds_sort(idsn, odsn=, asc=, desc=, dupout=, sortseq=, options=, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : a dataset reference;
* `odsn` : (_option_) name of the output dataset (in `WORK` library); when not set, the input
	dataset `idsn` is replaced with the newly sorted version; default: not set;
* `asc` : (_option_) list of variables to consider so as to sort `idsn` in ascending order; default:
	not set;
* `desc` : (_option_) list of variables to consider so as to sort `idsn` in ascending order; default:
	not set; note however that `asc` and `desc` cannot be both empty;
* `dupout` : (_option_) name of the `DUPOUT` file, _i.e._ all deleted observations, if any, will
	be put in this dataset (in `WORK` library); default: not used;
* `sortseq` : (_option_) option used by the `PROC SORT` procedure so as to change the sorting order
	of character variables; default: not used;
* `options` : (_option_) any additional options accepted by the `PROC SORT` procedure;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` is used.
  
### Returns
In either `odsn` or `idsn` (updated when the former is not passed), the original dataset sorted by
(ascending) `asc` variables and descending `desc` variables.

### Examples
Let us consider the test dataset #35:
geo | time | EQ_INC20 | RB050a
----|------|----------|-------
 BE | 2009 |    10    |   10 
 BE | 2010 |    50    |   10
 BE | 2011 |    60    |   10
 BE | 2012 |    20    |   20
 BE | 2013 |    10    |   20
 BE | 2014 |    30    |   20
 BE | 2015 |    40    |   20
 IT | 2009 |    10    |   10
 IT | 2010 |    50    |   10
 IT | 2011 |    50    |   10
 IT | 2012 |    30    |   20
 IT | 2013 |    30    |   20
 IT | 2014 |    20    |   20
 IT | 2015 |    50    |   20

and run the macro:
	
	%_dstest35;
	%ds_sort(_dstest35, asc=time, desc=eq_inc20 rb050a);

which updates _dstest35 with the following table:
geo | time | EQ_INC20 | RB050a
----|------|----------|-------
 BE	| 2009 | 	10	  |  10
 IT	| 2009 | 	10	  |  10
 BE	| 2010 | 	50	  |  10 
 IT	| 2010 | 	50	  |  10
 BE	| 2011 | 	60	  |  10
 IT	| 2011 | 	50	  |  10
 IT	| 2012 | 	30	  |  20
 BE	| 2012 | 	20	  |  20
 IT	| 2013 | 	30	  |  20
 BE	| 2013 | 	10	  |  20
 BE	| 2014 | 	30	  |  20
 IT	| 2014 | 	20	  |  20
 IT	| 2015 | 	50	  |  20
 BE	| 2015 | 	40	  |  20 

Run macro `%%_example_ds_sort` for more examples.

### Notes
1. In short, the macro runs the following `PROC SORT` procedure:

	   PROC SORT DATA=&ilib..&idsn 
		   OUT=&olib..&odsn
		   DUPOUT=&dupout
		   &options;
		   BY &asc DESCENDING &desc;
	   run;
2. In debug mode (_e.g._, `G_PING_DEBUG=1`), the macro is used to return a string:

		%let proc=%ds_sort( ... );

where `proc` is the procedure that launches the operation (see above), and while the actual operation 
is actually not ran. Further note that in the case the variable G_PING_DEBUG` is not defined in your 
environment, debug mode is ignored (_i.e._, by default the operation is ran).

### References
1. Bassett, B.K. (2006): ["The SORT procedure: Beyond the basics"](http://www2.sas.com/proceedings/sugi31/030-31.pdf).
2. Fickbohm, D. (2007): ["The SORT procedure: Beyond the basics"](http://www.lexjansen.com/wuss/2007/ApplicationsDevelopment/APP_Fickbaum_SortPrcedure.pdf).
3. Cherny, M. (2015): ["Getting the most out of PROC SORT: A review of its advanced options"](http://www.pharmasug.org/proceedings/2015/QT/PharmaSUG-2015-QT14.pdf).

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[SORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000057941.htm).
