/** 
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
*/ /** \cond */

%macro ds_sample(/*input*/	idsn, 
				 /*output*/ odsn,	
				 /*option*/ sampsize=1, method=SRS, rep=1, seed=, strata=,
							var=, ilib=, olib=);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _v 
		_nobs;

 	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
 	%if %macro_isblank(olib) %then 	%let olib=&ilib;

	%if %error_handle(WarningOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists !, 
			verb=warn) %then
		%goto warning;
	%warning: /* nothing in fact: just proceed... */

	/* some basic checking */
 	%if not %macro_isblank(var) %then %do;
		%local _i SEP;
		%let SEP=%str( );
		%let _i=1;
		%do %while (%scan(&var, &_i, &SEP) ne %str());
			%let _v=%scan(&var, &_i, &SEP);
			%if %error_handle(ErrorInputParameter, 
					%var_check(&idsn, &_v, lib=&ilib) EQ 1, mac=&_mac,		
					txt=!!! Field %upcase(&var) not found in dataset %upcase(&idsn) !!!) %then
				%goto exit;
			%let _i=%eval(&_i+1);
		%end;
	%end;

	/* check that the request is...reasonable enough */
	%ds_count(&idsn, _nobs_=_nobs, lib=&ilib);

	%if %error_handle(ErrorInputParameter, 
			&sampsize > &_nobs, mac=&_mac,		
			txt=!!! Sample size (&sampsize) larger than number of observations (&_nobs) !!!) %then
		%goto exit;

	/* start the actual sampling */
	%if &_METHOD_ = urs %then %do ;
		%surveyselect(&idsn, &odsn, &method, &sampsize, &rep, seed=&seed, strata=&strata, ilib=&ilib, olib=&olib) ;
	%end ;
	%else %do ;
		PROC SURVEYSELECT DATA=&ilib..&idsn OUT=&olib..&odsn 
			METHOD = &method rep = &rep 
	  		SAMPSIZE = &sampsize
	  		%if not %macro_isblank(seed) %then %do;
			 	SEED = &seed /* used to reproduce exactly the same sampling process */
			%end;
			noprint;
			%if not %macro_isblank(var) %then %do;
	 			ID &var;
			%end;
			%if not %macro_isblank(strata) %then %do;
	 			STRATA &strata;
			%end;
		run;
	%end ;

	/* clean a bit the output */
/*	%ds_delete(&odsn, var=replicate, lib=&olib);*/ /* don't clean finally, as rep may be useful */
	/* in practice, does:
		data &odsn (drop=replicate);
			set &odsn;
		run;
	*/ 

	%exit:
%mend ds_sample;

%macro _example_ds_sample;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%_dstest31;
	%ds_print(_dstest31);

	%local tab_sample s_size v clist;
	%let tab_sample=_tab_example_ds_sample;
	%let s_size=2;

	%put;
	%put (i) Perform some request on a non existing variable DUMMY ...;
	%ds_sample(_dstest31, &tab_sample, sampsize=&s_size, var=dummy, method=SRS, rep=1);
	
	%put;
	%put (ii) Perform some dummy request with a too large sample size ...;
	%ds_sample(_dstest31, &tab_sample, sampsize=8, method=SRS, rep=1);

	%put;
	%put (iii) Perform some sampling of the dataset _dstest31 with size &s_size ...;
	%ds_sample(_dstest31, &tab_sample, sampsize=&s_size, method=SRS, rep=1);
	%ds_print(&tab_sample);
	%var_to_clist(&tab_sample, geo, _varclst_=clist, lib=WORK);
	%put the select sample is &clist;
	
	%let v=geo value;
	%put;
	%put (iv) Perform some sampling of the dataset selecting only the variables %upcase(&v) ...;
	%ds_sample(_dstest31, &tab_sample, sampsize=&s_size, var=&v, method=SRS, rep=1);
	%ds_print(&tab_sample);

	%put;
	%put (v) Same operation, changing the seed ...;
	%ds_sample(_dstest31, &tab_sample, seed=-1, sampsize=&s_size, var=&v, method=SRS, rep=1);
	%ds_print(&tab_sample);

	%put;
	%put (v) Now performing sampling on a table of 1,000 rows;
	%_dstest1000;
	%ds_sample(_dstest1000, &tab_sample, seed=-1, sampsize=&s_size, method=srs, rep=1);
	%ds_print(&tab_sample);

	%put;
	%put (v) And with a stratified sampling...;
	%_dstest1001;
	%ds_sample(_dstest1001, &tab_sample, seed=-1, sampsize=&s_size, method=srs, rep=1, strata=strata);
	%ds_print(&tab_sample);

	%put;

	/* clean */
	%work_clean(_dstest31);
	%work_clean(_dstest1000);
	%work_clean(_dstest1001);
%mend _example_ds_sample;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_sample;  
*/

/** \endcond */
