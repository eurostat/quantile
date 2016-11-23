/** 
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
*/ /** \cond */

%macro ds_iscond(dsn		/* Input reference dataset 										(REQ) */
				, cond		/* Expression used as a test over all observations 				(REQ) */
				, _ans_=	/* Name of the macro variable storing the result of the test 	(REQ) */
				, lib=		/* Name of the input library 									(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_ans_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _ANS_ not set !!!) %then
		%goto exit;
	
	/* various default settings */
 	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/* further checkings */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) 
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(cond) EQ 1, mac=&_mac,		
				txt=!!! No condition has been defined !!!) %then
		%goto exit;

	%local nb_obs_0 /* number of observations in the dataset */
		nb_obs_1	/* number of observations in the dataset that verify the condition */
		_ans; 		/* output value of the test */

	/* count the number of observations in the input dataset */
	%ds_count(&dsn, _nobs_=nb_obs_0, lib=&lib);

	/* ibid, count with the desired condition */
	PROC SQL noprint;
		SELECT COUNT(*) INTO: nb_obs_1 
		FROM &lib..&dsn
		WHERE &cond;
	quit;

	%if %error_handle(ErrorInputDataset, 
			%macro_isblank(nb_obs_1) EQ 1, mac=&_mac,		
			txt=%quote(!!! SQL procedure fails - Condition %upcase(&cond) must be wrong: reformulate it !!!)) %then 
		%goto exit;

	/* Another approach consists in creating a temporary dataset:
		%local _tmp;
		%let _tmp=TMP%upcase(&_mac);
		%ds_select(&dsn, &_tmp, where=&cond, ilib=&lib);
		%ds_count(&_tmp, _nobs_=nb_obs_1, lib=&lib);
	* which essentially runs the following DATA step and PROC SQL procedures:
		DATA &_tmp;
			SET &lib..&dsn;
			WHERE &cond;
		run;
		PROC SQL;
			SELECT COUNT(*) INTO: nb_obs_1 
			FROM &_tmp;
		quit;
	* but also imply to clean your shit
		%work_clean(&_tmp);
	*/

	/* check that the condition is at least sometimes verified */
	%if &nb_obs_1 = 0 %then 				
		/* nothing satisfies the condition */
		%let _ans = 0;
	%else %if &nb_obs_1 = &nb_obs_0 %then  	
		/* everything satisfies the condition */
		%let _ans = 1 ;
	%else  									
		/* something satisfies the condition */
		%let _ans = %sysevalf(- &nb_obs_1 / &nb_obs_0);

	/*%let &_ans_=&_ans;*/
	data _null_;
		call symput("&_ans_",&_ans);
	run;

	%exit:
%mend ds_iscond;


%macro _example_ds_iscond;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local cond ans dsn;
	%let YOU_WANT_TO_WASTE_YOUR_TIME=no;
	%let TEST_CRASH_AS_YOU_LIKE=no;

	%_dstest1000;

	%if &TEST_CRASH_AS_YOU_LIKE=yes %then %do;
		%put; 
		%put (o) Test a dummy condition over a test dataset #1000;
		*options nosource nonotes errors=0;
		%ds_iscond(_dstest1000, DUMMY gt 0, _ans_=ans);
		*options source notes errors=9007199254740992;
		%if %macro_isblank(ans) %then 	%put OK: TEST PASSED - Wrong parameterisation: fails;
		%else 							%put ERROR: TEST FAILED - Wrong parameterisation: passes;
	%end;

	%put; 
	%put (i) Test a regular expression on a non-existing table;
	%ds_iscond(DUMMY, var>0, _ans_=ans);
	%if %macro_isblank(ans) %then 	%put OK: TEST PASSED - Wrong parameterisation: fails;
	%else 							%put ERROR: TEST FAILED - Wrong parameterisation: passes;

	%let cond=%quote(i ge 0);
	%put;
	%put (ii) Test the condition: &cond on test dataset #1000;
	%ds_iscond(_dstest1000, &cond, _ans_=ans);
	%if &ans=1 %then 			%put OK: TEST PASSED - Test returns 1 (true for all 1000 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;

	%let cond=%quote(i gt 600);
	%put;
	%put (ii) Ibid with the condition: &cond;
	%ds_iscond(_dstest1000, &cond, _ans_=ans);
	%let ans=%sysevalf(-&ans);
	%if &ans=0.4 %then 			%put OK: TEST PASSED - Test returns -0.4 (true for 400 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;

	%let cond=%quote(i gt 1000);
	%put;
	%put (iv) Ibid with the condition: &cond;
	%ds_iscond(_dstest1000, &cond, _ans_=ans);
	%if &ans=0 %then 			%put OK: TEST PASSED - Test returns 0 (false for all 1000 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;
	%put prout;
	
	%let cond=%quote(u ge 0);
	%let dsn=TMP%upcase(&sysmacroname);
	%put;
	%ranuni(&dsn, 100);
	%put (v) Test on a table with 100 observations generated using macro ranuni;
	%ds_iscond(&dsn, &cond ,_ans_ = ans) ;
	%if &ans=1 %then 			%put OK: TEST PASSED - Test returns 1 (true for all observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;
	
	%if &YOU_WANT_TO_WASTE_YOUR_TIME=yes %then %do;
		%local count res;
		%let cond=%quote(i gt 1);
		%let dsn=TMP%upcase(&sysmacroname);
		%put;
		%let count=100000000; /* 1E8 ... try 1E9: be ready to sleep */
		%let res=%sysevalf(-(&count-1)/&count);
		DATA &dsn;
			do i = 1 to &count;
			   	output;
			end;
		run;
		%put (vi) Test on a table with &count observations generated using macro ranuni;
		%ds_iscond(&dsn, &cond ,_ans_ = ans);
		%if &ans=&res %then 	%put OK: TEST PASSED - Test returns &res (true for almost all observations);
		%else 					%put ERROR: TEST FAILED - Test returns &ans;
	%end;

	%put;

	%work_clean(_dstest1000);
	%work_clean(&dsn);
%mend ;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_iscond; 
*/

/** \endcond */

