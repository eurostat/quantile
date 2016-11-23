/** 
## ds_count {#sas_ds_count}
Count the number of observations in a dataset, possibly missing or non missing for a given variable.

	%ds_count(dsn, _nobs_=, miss=, nonmiss=, lib=WORK);

### Arguments
* `dsn` : a dataset;
* `miss` : (_option_) the name of variable/field in the dataset for which only missing
	observations are considered; default: `miss` is not set;
* `nonmiss` : (_option_) the names of variable/field in the dataset for which only NON missing
	observations are considered; this is obviously compatible with the `miss` argument above
	only when the variables differ; default: `nonmiss` is not set;
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_nobs_` : name of the macro variable used to store the result number of observations; by default 
	(_i.e._, when neither miss nor nonmiss is set, the total number of observations is returned)

### Example
Let us consider the table `_dstest28`:
geo | value 
----|------:
 ' '|  1    
 AT |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  5 

then we can compute the TOTAL number of observations in `_dstest28`:

	%local nobs;
	%ds_count(_dstest28, _nobs_=nobs);

returns `nobs=6`, while:

	%ds_count(_dstest28, _nobs_=nobs, nonmiss=value);

returns the number of observations with NON MISSING `value`, _i.e._ `nobs=4`, and:

	%ds_count(_dstest28, _nobs_=nobs, miss=value, nonmiss=geo);

returns the number of observations with MISSING `value` and NON MISSING `geo` at the same time, 
_i.e._ `nobs=1`.

Run macro `%%_example_ds_count` for more examples.

### Reference
1. ["Counting the number of missing and non-missing values for each variable in a data set"](<http://support.sas.com/kb/44/124.html>).
2. Hamilton, J. (2001): ["How many observations are in my dataset?"](http://www2.sas.com/proceedings/sugi26/p095-26.pdf).

### See also
[%var_count](@ref sas_var_count), [%ds_check](@ref sas_ds_check), [%ds_isempty](@ref sas_ds_isempty), [%var_check](@ref sas_var_check).
*/ /** \cond */

%macro ds_count(dsn
				, _nobs_=
				, nonmiss=
				, miss=
				, lib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/* check that the output macro variable is set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_nobs_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _NOBS_ not set !!!) %then
		%goto exit;

    %if %macro_isblank(lib) %then %let lib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	%local _miss_isblank 
		_nonmiss_isblank
		_nobs_count;
	%let _nonmiss_isblank=%macro_isblank(nonmiss); /* 1 when nonmiss is not passed */
	%let _miss_isblank=%macro_isblank(miss); /* 1 when miss is not passed */

	/* perform some test on the arguments passed to the macro */
	%if &_nonmiss_isblank=0 and &_miss_isblank=0 %then %do;
		%if %error_handle(ErrorInputParameter,
			&nonmiss EQ &miss, mac=&_mac,
			txt=!!! Identical variable used for both MISS and NONMISS arguments !!!) %then
			%goto exit;
	%end;
	%else %if &_miss_isblank=0 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%var_check(&dsn, &miss, lib=&lib) EQ 1, mac=&_mac,		
				txt=!!! Variable %upcase(&miss) does not exist in dataset %upcase(&dsn) !!!) %then
			%goto exit;
	%end;
	%else %if &_nonmiss_isblank=0  %then %do;
		%if %error_handle(ErrorInputParameter, 
				%var_check(&dsn, &nonmiss, lib=&lib) EQ 1, mac=&_mac,		
				txt=!!! Variable %upcase(&nonmiss) does not exist in dataset %upcase(&dsn) !!!) %then
			%goto exit;
	%end;

	/* in case neither miss no nomiss is passed
	%local _dsid _nobs;
	%let _nobs=0;
	%let _dsid=%sysfunc(open(&lib..&dsn));
	%if &_dsid>0 %then %do;
		%let _nobs=%sysfunc(attrn(&_dsid,nlobs));
	    %let _dsid=%sysfunc(close(&_dsid));
	%end;
	*/

	/* run the "counting" procedure */
	PROC SQL noprint;
	   	SELECT COUNT(*) INTO:_nobs_count
	  	FROM &lib..&dsn
	   	%if &_nonmiss_isblank=0 or &_miss_isblank=0 %then %do;
			WHERE
		%end;
	   	%if &_nonmiss_isblank=0 %then %do;
 			 /*&nonmiss is not null*/ not(&nonmiss is missing)
		%end;
	   	%if &_nonmiss_isblank=0 and &_miss_isblank=0 %then %do;
			and
		%end;
		%if &_miss_isblank=0 %then %do;
 			&miss is missing
		%end;
		;
	quit;

	data _null_;
		call symput("&_nobs_",%sysevalf(&_nobs_count,integer));
	run;

	%exit:
%mend ds_count;

/* this is the same macro without any test on input parameters 
%macro _ds_count(dsn, _nobs_, nonmiss=, miss=, lib=);
	%local _nobs_count;
	%local _miss_isblank _nonmiss_isblank;

	%let _nonmiss_isblank=%macro_isblank(nonmiss); 
	%let _miss_isblank=%macro_isblank(miss); 

	PROC SQL noprint;
	   	SELECT count(*) INTO:_nobs_count
	  	FROM &lib..&dsn
	   	%if &_nonmiss_isblank=0 or &_miss_isblank=0 %then %do;
			WHERE
		%end;
	   	%if &_nonmiss_isblank=0 %then %do;
 			 not(&nonmiss is missing)
		%end;
	   	%if &_nonmiss_isblank=0 and &_miss_isblank=0 %then %do;
			and
		%end;
		%if &_miss_isblank=0 %then %do;
 			&miss is missing
		%end;
		;
	quit;

	data _null_;
		call symput("&_nobs_",%eval(&_nobs_count));
	run;
%mend _ds_count; */

%macro _example_ds_count;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local nobs;
	%_dstest28;
	%*ds_print(_dstest28);

	%put;
	%put (i) Count the total number of observations in _dstest28...;
	%ds_count(_dstest28, _nobs_=nobs);
	%if &nobs=6 %then 		%put OK: TEST PASSED - Count returns: 6 observations;
	%else 					%put ERROR: TEST FAILED - Count returns: wrong number of observations;

	%put;
	%put (ii) Count the observations with missing VALUE in _dstest28...;
	%ds_count(_dstest28, _nobs_=nobs, miss=value);
	%if &nobs=2 %then 		%put OK: TEST PASSED - Count returns: 2 obervations with missing VALUE;
	%else 					%put ERROR: TEST FAILED - Count returns: wrong number of observations with missing VALUE;

	%put;
	%put (iii) Count the observations with non missing VALUE and missing GEO in _dstest28...;
	%ds_count(_dstest28, _nobs_=nobs, nonmiss=value, miss=geo);
	%if &nobs=1 %then 		%put OK: TEST PASSED - Count returns: 1 obervation with non missing VALUE and missing GEO;
	%else 					%put ERROR: TEST FAILED - Count returns: wrong number of observations with non missing VALUE and missing GEO;

	%let nobs=; /*reset*/
	%put;
	%put (iv) Just fail ...;
	%ds_count(_dstest28, _nobs_=nobs, nonmiss=geo, miss=geo);
	%if &nobs= %then 		%put OK: TEST PASSED - Wrong parameterisation: fails;
	%else 					%put ERROR: TEST FAILED - Wrong parameterisation: passes;

	%put;

	/* clean your shit... */
	%work_clean(_dstest28);
%mend _example_ds_count;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_count; 
*/

/** \endcond */
