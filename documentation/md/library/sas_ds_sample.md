## ds_sample {#sas_ds_sample}
Perform the sampling of a given dataset following `PROC SURVEYSELECT` method. 

	%ds_sample(idsn, odsn, sampsize=1, method=SRS, rep=no, var=, seed=, strata= ,ilib=WORK, olib=WORK, debug=no);

### Arguments
* `idsn` : a dataset;
* `sampsize, method, rep, seed, strata` : (_option_) arguments of the `PROC SURVEYSELECT`; default:
	1, SRS (_i.e._ simple random sampling), 1 (no repetition), '' (not specified/used) and '' 
	respectively;
* `var` : (_option_) list of (unquoted and blank-separated) strings that store the name of 
	the variables/fields (which must exist in the dataset) to be returned in `odsn`;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` is used.

### Returns
`odsn` : name of the output table where the sampled data (of size `sampsize`, see above) will 
	be stored. 

### Example
Let us consider the table `_dstest31` as follows:
geo | value | unit
----|-------|-----
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

we then shall run the sampling of `geo` and `value` fields only:

	%ds_sample(_dstest31, dsn, sampsize=2, var=geo unit, method=SRS, rep=1);

which returns (`seed` not set) into the dataset `dsn` the following table:
geo | unit
----|-----
 BG | NAC
 FR | NAC

Run macro `%%_example_ds_sample` for more examples.

### Notes
1. In short, this macro runs, in case `strata` is not passed:

	PROC SURVEYSELECT DATA=&ilib..&dsn OUT=&olib..&odsn 
		METHOD = &method rep = &rep 
  		SAMPSIZE = &sampsize
  		SEED = &seed
 		ID &var;
	run;
or in case `strata` is specified:

	PROC SURVEYSELECT DATA=&ilib..&dsn OUT=&olib..&odsn 
		METHOD = &method rep = &rep 
  		SAMPSIZE = &sampsize
  		SEED = &seed
 		ID &var;
	STRATA &strata ;
	run;

with the parameters defined above. Check the 
[online documentation](https://support.sas.com/documentation/cdl/en/statugsurveyselect/61839/PDF/default/statugsurveyselect.pdf) 
of the `PROC SURVEYSELECT` procedure for more details.
2. No consideration on the `SIZE` (sampling unit size measure) statement is made, which implicitly means 
that you cannot perform unequal probability sampling with this macro. 
3. For SRS and URS methods (simple sampling with or without replacement), an alternative algorithm is
available so as to produce the same output whatever the machine used (see note 4 below). These algorithms 
have been implemented by P.BBES.Lamarche (<mailto:pierre.lamarche@ec.europa.eu>).
4. This macro runs on different machine, but with the same seed on the same dataset will produce the exact 
same samples. Please note however that the current version of SAS (9.2 TS Level 2M3) on Solaris machines does 
not ensure the same output as SAS installed on a Windows machine for the `PROC SURVEYSELECT`. Therefore 
alternative macros have been implemented for SRS and URS methods; the SYS method should also be implemented 
in a later version. 
 
### Reference
Fan, C.T., Muller, M.E., and Rezucha, I. (1962): ["Development of sampling plans by using eequential (item by item)
selection techniques and digital computers"](http://www.jstor.org/stable/2281647), JASAS, 57(298):387-402, DOI: 10.2307/2281647.

### See also
[%var_check](@ref sas_var_check), [%ds_count](@ref sas_ds_count), [%ds_delete](@ref sas_ds_delete),
[SURVEYSELECT](https://support.sas.com/documentation/cdl/en/statug/63033/HTML/default/viewer.htm#surveyselect_toc.htm).
