/** 
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
*/ /** \cond */

%macro ds_isempty(dsn		/* Input reference dataset 											(REQ) */
				, var=		/* Name of the variable whose existence in input dataset is checked (REQ) */
				, _ans_=	/* Name of the macro variable storing the result of the test 		(REQ) */
				, lib=		/* Name of the input library 										(OPT) */
				, verb= 	/* Legacy parameter - Ignored 										(OBS) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_ans_) EQ 1, mac=&_mac,		
			txt=!!! Output macro variable _ANS_ not set !!!) %then
		%goto exit;

 	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/************************************************************************************/
	/**                                   actual opration                              **/
	/************************************************************************************/

	%local _dsn	/* temporary dataset */
		__ans	/* output result */
		_rc		/* file identifier */
		_dsid	/* dataset identifier */
		_nobs;	/* total number of observations */
	/* set default answer */
	%let __ans=1;

	%if /*%ds_check(&dsn, lib=&lib)*/not %sysfunc(exist(&lib..&dsn)) %then %do;
		%let ans=-1
		%goto quit;
	%end;


	/* retrieve the number of observations */
	%let _dsid = %sysfunc( open(&lib..&dsn) );
	%let _nobs = %sysfunc( attrn(&_dsid, nobs) );

	%if &_nobs=0 %then %do;
		%let __ans=1; 
		%goto quit;
	%end;

	%if &_nobs^=0 and %macro_isblank(var) %then %do;
		%let __ans=0;
		%goto quit;
	%end;
	%else %do;
		%if %error_handle(ErrorInputParameter, 
				%sysfunc(varnum(&_dsid, &var)) EQ 0, mac=&_mac,		
				txt=%quote(!!! Variable %upcase(&var) not found in dataset %upcase(&dsn) !!!)) %then %do;
			%let ans=-1;
			%goto quit;
		%end;
	%end;

	%let _dsn=TMP_%upcase(&sysmacroname);
	PROC SQL noprint;
		CREATE TABLE &_dsn AS 
		SELECT * FROM  &lib..&dsn 
		WHERE &var IS NOT MISSING;
	quit;

	PROC SQL noprint;
		SELECT DISTINCT count(&var) as N 
		INTO :_nobs 
		FROM &_dsn;
	quit;
 
	%work_clean(&_dsn); 

	%if &_nobs = 0 %then 
		/* no var field in dsn */
		%let __ans=1; 
	%else  
		/* var field exists in dsn */
		%let __ans=0; 

	%quit:
	/* return the answer */
	data _null_;
		call symput("&_ans_","&__ans");
	run;
	/* in all cases, free the dataset identifier */
	%let _rc = %sysfunc( close(&_dsid) ); 

	%exit:
%mend ds_isempty;


%macro _example_ds_isempty;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ans;

	%put;
	%put (i) Test the empty test dataset #0;                                           
	%_dstest0;
	%ds_isempty(_dstest0, _ans_=ans);
	%if &ans=1 %then 	%put OK: TEST PASSED - Empty dataset _dstest0 reported: errcode 1;
	%else 				%put ERROR: TEST FAILED - Empty dataset _dstest0 not reported: errcode &ans;

	%put;
	%put (ii) Test the non-empty test dataset #1 with missing observation A;                                           
	%_dstest1;
	%ds_isempty(_dstest1, var=a, _ans_=ans);
	%if &ans=1 %then 	%put OK: TEST PASSED - Empty A field reported in _dstest1: errcode 1;
	%else 				%put ERROR: TEST FAILED - Non-empty A field reported in _dstest1: errcode &ans;

	%put;
	%put (iii) Test the non-empty test dataset #2 and invoke the macro on field A;                                           
	%_dstest2;
	%ds_isempty(_dstest2, var=a, _ans_=ans);
	%if &ans=0 %then 	%put OK: TEST PASSED - Non-empty A field in _dstest2: errcode 0;
	%else 				%put ERROR: TEST FAILED - Non-empty A field in _dstest2: errcode &ans;

	%put;
	%put (iv) Test a dataset with no observations for field A;
	DATA _tmp; /* same structure as _dstest1 */
		SET _dstest2;
		STOP;
	run;
	%ds_isempty(_tmp, var=a, _ans_=ans);
	%if &ans=1 %then 	%put OK: TEST PASSED - Empty A field: errcode 1;
	%else 				%put ERROR: TEST FAILED - Empty A field: errcode &ans;

	%put;

	%work_clean(_dstest0,_dstest1,_dstest2,_tmp);
%mend _example_ds_isempty;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_isempty;  
*/

/** \endcond */
